import 'dart:convert';
import 'dart:io';

import 'package:hostr_sdk/util/deterministic_key_derivation.dart';

import '../util/contract_address.dart';
import 'broadcast_isolate.dart';
import 'pipeline/seed_pipeline.dart';
import 'pipeline/seed_pipeline_config.dart';
import 'pipeline/seed_pipeline_models.dart';

class RelaySeeder {
  /// Run the seed pipeline with the given [SeedPipelineConfig].
  Future<SeedPipelineData> runPipeline({
    required SeedPipelineConfig config,
  }) async {
    print('Seeding ${config.relayUrl} (pipeline)...');
    print(const JsonEncoder.withIndent('  ').convert(config.toJson()));
    final contractAddress = resolveContractAddress();
    await _ensureContractIsDeployed(
      rpcUrl: config.rpcUrl,
      contractAddress: contractAddress,
    );
    print('Using contract address: $contractAddress');

    BroadcastIsolate? broadcaster;
    try {
      final sw = Stopwatch()..start();

      // ── Spawn broadcast isolate ──────────────────────────────────────
      // NDK runs in a dedicated isolate with its own event loop so that
      // heavy EVM / anvil work on the main isolate cannot starve the
      // WebSocket and cause spurious 4 s timeouts.
      broadcaster = await BroadcastIsolate.spawn(
        relayUrl: config.relayUrl!,
        maxConcurrent: _maxConcurrentBroadcasts,
        maxAttempts: _broadcastMaxAttempts,
      );
      print('Broadcast isolate ready. [${sw.elapsedMilliseconds} ms]');

      final pipeline = SeedPipeline(
        config: config,
        contractAddress: contractAddress,
      );

      // Returns immediately — pipeline runs in a microtask.
      // All subjects are ReplaySubjects, so nothing is lost before we
      // subscribe.
      final streams = pipeline.run();

      // ── Side-effect listeners (log-only) ─────────────────────────────
      streams.userFunded.listen((r) {
        print('[funded] ${r.address} — ${r.amountWei} wei');
      });

      streams.chainTx.listen((r) {
        print('[chain] ${r.action} tx=${r.txHash}');
      });

      streams.nip05Created.listen((r) {
        print('[nip05] ${r.username}@${r.domain}');
      });

      // ── Track broadcast results on main isolate ──────────────────────
      sw.reset();
      int broadcastCount = 0;
      int failCount = 0;

      broadcaster.results.listen((result) {
        if (result is BroadcastSuccess) {
          broadcastCount++;
          if (broadcastCount % 50 == 0) {
            print(
              'Broadcasted $broadcastCount events '
              '[${sw.elapsedMilliseconds} ms]',
            );
          }
        } else if (result is BroadcastFailure) {
          failCount++;
          print('[broadcast-fail] ${result.message}');
        }
      });

      // ── Feed events to the broadcast isolate as they arrive ──────────
      int nextIndex = 0;
      await for (final event in streams.events) {
        broadcaster.submit(nextIndex++, event);
      }

      // All events have been queued — tell the isolate to finish up.
      final finished = await broadcaster.finish();
      broadcaster = null; // already cleaned up
      broadcastCount = finished.successCount;
      failCount = finished.failureCount;

      print(
        'Broadcast complete: $broadcastCount succeeded, $failCount failed. '
        '[pipeline+broadcast ${sw.elapsedMilliseconds} ms]',
      );

      // ── Summary ──────────────────────────────────────────────────────
      final data = await streams.done.first;
      print(
        'Summary: ${const JsonEncoder.withIndent("  ").convert(data.summary.toJson())}',
      );
      _printPipelineUsersByRole(data);

      print('Seeded $broadcastCount events.');

      return streams.done.first;
    } finally {
      if (broadcaster != null) {
        try {
          await broadcaster.finish();
        } catch (_) {
          // Best-effort cleanup.
        }
      }
    }
  }

  static const int _maxConcurrentBroadcasts = 5;
  static const int _broadcastMaxAttempts = 6;

  Future<void> _ensureContractIsDeployed({
    required String rpcUrl,
    required String contractAddress,
  }) async {
    final code = await _ethGetCode(rpcUrl: rpcUrl, address: contractAddress);
    final normalized = code.trim().toLowerCase();
    final isEmptyCode = RegExp(r'^0x0*$').hasMatch(normalized);

    if (isEmptyCode) {
      throw StateError(
        'Escrow contract not deployed at $contractAddress on $rpcUrl. '
        'Deployment file exists, but address has no contract code. '
        'Deploy contracts first (or refresh deployment artifacts) before seeding.',
      );
    }
  }

  Future<String> _ethGetCode({
    required String rpcUrl,
    required String address,
  }) async {
    final httpClient = HttpClient();
    try {
      final uri = Uri.parse(rpcUrl);
      final request = await httpClient.postUrl(uri);
      request.headers.contentType = ContentType.json;
      request.write(
        jsonEncode({
          'jsonrpc': '2.0',
          'id': 1,
          'method': 'eth_getCode',
          'params': [address, 'latest'],
        }),
      );

      final response = await request.close();
      final body = await utf8.decodeStream(response);
      if (response.statusCode < 200 || response.statusCode >= 300) {
        throw StateError(
          'RPC eth_getCode failed with HTTP ${response.statusCode}: $body',
        );
      }

      final decoded = jsonDecode(body);
      if (decoded is! Map) {
        throw StateError('Invalid eth_getCode response: $body');
      }

      final map = Map<String, dynamic>.from(decoded);
      final error = map['error'];
      if (error != null) {
        throw StateError('RPC eth_getCode error: $error');
      }

      final result = map['result'];
      if (result is! String) {
        throw StateError('Invalid eth_getCode result: $result');
      }

      return result;
    } finally {
      httpClient.close(force: true);
    }
  }

  void _printPipelineUsersByRole(SeedPipelineData data) {
    final users = data.users;
    final userByPubkey = {for (final u in users) u.keyPair.publicKey: u};

    Map<String, dynamic> userSummary(SeedUser user) {
      final privateKey = user.keyPair.privateKey;
      final evmAddress = user.hasEvm && privateKey != null
          ? deriveEvmKey(privateKey).address.eip55With0x
          : null;

      return {
        'nsec': user.keyPair.privateKeyBech32,
        'npub': user.keyPair.publicKeyBech32,
        'hasEvm': user.hasEvm,
        'evmAddress': evmAddress,
        'reservations': {'escrow': <String>[], 'zap': <String>[]},
      };
    }

    final grouped = {
      'guest': {
        for (final u in users.where((u) => !u.isHost))
          if (u.keyPair.privateKey != null)
            u.keyPair.privateKey!: userSummary(u),
      },
      'host': {
        for (final u in users.where((u) => u.isHost))
          if (u.keyPair.privateKey != null)
            u.keyPair.privateKey!: userSummary(u),
      },
    };

    for (final reservation in data.reservations) {
      final tradeId = reservation.getDtag() ?? reservation.id;
      final proof = reservation.proof;
      if (proof == null) continue;

      final usesEscrow = proof.escrowProof != null;
      final usesZap = proof.zapProof != null;
      final guest = userByPubkey[reservation.pubKey];
      final host = userByPubkey[proof.listing.pubKey];

      void addToRole(SeedUser? user, String role) {
        if (user == null || user.keyPair.privateKey == null) return;
        final roleMap = grouped[role] as Map<String, dynamic>;
        final info = roleMap[user.keyPair.privateKey!] as Map<String, dynamic>?;
        if (info == null) return;
        final reservations = info['reservations'] as Map<String, dynamic>;
        if (usesEscrow) {
          (reservations['escrow'] as List<String>).add(tradeId);
        }
        if (usesZap) {
          (reservations['zap'] as List<String>).add(tradeId);
        }
      }

      addToRole(guest, 'guest');
      addToRole(host, 'host');
    }

    for (final role in ['guest', 'host']) {
      final roleMap = grouped[role] as Map<String, dynamic>;
      for (final info in roleMap.values) {
        final reservations =
            (info as Map<String, dynamic>)['reservations']
                as Map<String, dynamic>;
        reservations['escrow'] =
            (reservations['escrow'] as List<String>).toSet().toList()..sort();
        reservations['zap'] =
            (reservations['zap'] as List<String>).toSet().toList()..sort();
      }
    }

    print(
      'Seed users private keys by role with EVM + reservation proof usage:',
    );
    print(const JsonEncoder.withIndent('  ').convert(grouped));
  }
}
