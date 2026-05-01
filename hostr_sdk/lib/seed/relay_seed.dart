import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:hostr_sdk/util/deterministic_key_derivation.dart';

import '../config/generated/test_env.g.dart' as env;
import '../datasources/lnbits/lnbits.dart';
import 'broadcast_isolate.dart';
import 'pipeline/seed_pipeline_config.dart';
import 'pipeline/seed_pipeline_models.dart';
import 'pipeline/seeder.dart';
import 'pipeline/sink/infrastructure_sink.dart';
import 'signet_bunker_client.dart';

class RelaySeeder {
  /// Run the seed pipeline with the given [SeedPipelineConfig].
  Future<SeedPipelineData> runPipeline({
    required SeedPipelineConfig config,
  }) async {
    print('Seeding ${config.relayUrl} (pipeline)...');
    print(const JsonEncoder.withIndent('  ').convert(config.toJson()));
    final contractAddress = env.evmConfig.chains.first.escrowContractAddress!;
    await _ensureContractIsDeployed(
      rpcUrl: config.rpcUrl,
      contractAddress: contractAddress,
    );
    print('Using contract address: $contractAddress');

    // ── Resolve real bytecode hash from deployed contract ────────────
    final resolvedBytecodeHash = await _resolveMultiEscrowBytecodeHash(
      rpcUrl: config.rpcUrl,
      contractAddress: contractAddress,
    );
    print('Resolved MultiEscrow bytecode hash: $resolvedBytecodeHash');

    // Overlay the resolved hash onto the config so every downstream
    // consumer (escrow services, escrow methods) uses the real value.
    final resolvedConfig = config.copyWith(
      multiEscrowBytecodeHash: resolvedBytecodeHash,
    );

    BroadcastIsolate? broadcaster;
    InfrastructureSink? sink;
    try {
      final sw = Stopwatch()..start();

      // ── Spawn broadcast isolate ──────────────────────────────────────
      // NDK runs in a dedicated isolate with its own event loop so that
      // heavy EVM / anvil work on the main isolate cannot starve the
      // WebSocket and cause spurious 4 s timeouts.
      broadcaster = await BroadcastIsolate.spawn(
        relayUrl: resolvedConfig.relayUrl!,
        maxConcurrent: _maxConcurrentBroadcasts,
        maxAttempts: _broadcastMaxAttempts,
      );
      print('Broadcast isolate ready. [${sw.elapsedMilliseconds} ms]');

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

      // ── Create Seeder + InfrastructureSink ────────────────────────────
      final lnbitsConfig = resolvedConfig.setupLnbits
          ? LnbitsSetupConfig.fromEnvironment(
              lnbitsBaseUrl: resolvedConfig.lnbitsBaseUrl,
              lnbitsAdminEmail: resolvedConfig.lnbitsAdminEmail,
              lnbitsAdminPassword: resolvedConfig.lnbitsAdminPassword,
              lnbitsExtensionName: resolvedConfig.lnbitsExtensionName,
              lnbitsNostrPrivateKey: resolvedConfig.lnbitsNostrPrivateKey,
            )
          : null;

      sink = InfrastructureSink(
        rpcUrl: resolvedConfig.rpcUrl,
        contractAddress: contractAddress,
        chainId: env.evmConfig.chains.first.chainId,
        tradeSponsorPrivateKey: resolvedConfig.tradeSponsorPrivateKey,
        broadcaster: broadcaster,
        lnbitsConfig: lnbitsConfig,
      );

      final seeder = Seeder(
        config: resolvedConfig,
        contractAddress: contractAddress,
      );

      // ── Run pipeline ─────────────────────────────────────────────────
      // Enable auto-mining so each tx is mined immediately.  Without
      // this, Anvil may be in interval-mining mode (from a prior run's
      // finally block), causing delayed receipts, mempool pile-ups, and
      // TradeIdAlreadyExists reverts from orphaned txs of crashed runs.
      await sink.enableAutomine();
      final data = await seeder.seed(sink);

      // All events have been queued — tell the isolate to finish up.
      final finished = await broadcaster.finish();
      broadcaster = null; // already cleaned up
      broadcastCount = finished.successCount;
      failCount = finished.failureCount;

      print(
        'Broadcast complete: $broadcastCount succeeded, $failCount failed. '
        '[pipeline+broadcast ${sw.elapsedMilliseconds} ms]',
      );
      if (failCount > 0) {
        throw StateError('Relay seed broadcast failed for $failCount event(s)');
      }

      // ── Summary ──────────────────────────────────────────────────────
      print(
        'Summary: ${const JsonEncoder.withIndent("  ").convert(data.summary.toJson())}',
      );
      await _printPipelineUsersByRole(data);

      print('Seeded $broadcastCount events.');
      await _insertUsersIntoSignetBunker(config: resolvedConfig, data: data);

      return data;
    } finally {
      // Restore interval mining so the node doesn't burn CPU spinning
      // on empty blocks while idle.
      try {
        await sink?.disableAutomine();
      } catch (_) {
        // Best-effort — node may already be unreachable.
      }
      sink?.close();
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

  Future<void> _insertUsersIntoSignetBunker({
    required SeedPipelineConfig config,
    required SeedPipelineData data,
  }) async {
    final rawUrl = config.signetBunkerUrl?.trim();
    if (rawUrl == null || rawUrl.isEmpty) return;

    final baseUri = Uri.tryParse(rawUrl);
    if (baseUri == null || !baseUri.hasScheme || baseUri.host.isEmpty) {
      throw StateError('Invalid signetBunkerUrl: $rawUrl');
    }

    print('Inserting seeded nsecs into Signet bunker: $baseUri');
    final client = SignetBunkerClient(baseUri: baseUri);
    try {
      await client.deleteKeysWithPrefix(_signetKeyPrefix(config));
      final imported = <Map<String, dynamic>>[];
      for (final user in data.users) {
        final nsec = user.keyPair.privateKeyBech32;
        if (nsec == null || nsec.isEmpty) continue;

        final keyName = _signetKeyName(config: config, user: user);
        final key = await client.importNsec(
          keyName: keyName,
          nsec: nsec,
          replaceExisting: false,
        );
        imported.add({
          'keyName': key.keyName,
          'role': user.isHost ? 'host' : 'guest',
          'npub': user.keyPair.publicKeyBech32,
          'bunkerUri': key.bunkerUri,
        });
      }

      print('Inserted ${imported.length} seeded nsecs into Signet bunker.');
      if (imported.isNotEmpty) {
        print(const JsonEncoder.withIndent('  ').convert(imported));
      }
    } finally {
      await client.close();
    }
  }

  String _signetKeyName({
    required SeedPipelineConfig config,
    required SeedUser user,
  }) {
    final role = user.isHost ? 'host' : 'guest';
    return '${_signetKeyPrefix(config)}$role-${user.index}';
  }

  String _signetKeyPrefix(SeedPipelineConfig config) =>
      'hostr-seed-${config.seed}-';

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

  /// Derive the SHA-256 hash of the deployed MultiEscrow runtime bytecode
  /// by fetching the on-chain code and hashing it.
  Future<String> _resolveMultiEscrowBytecodeHash({
    required String rpcUrl,
    required String contractAddress,
  }) async {
    final hexCode = await _ethGetCode(rpcUrl: rpcUrl, address: contractAddress);
    // Convert the 0x-prefixed hex string to bytes for hashing.
    final bytesString = hexCode.startsWith('0x')
        ? hexCode.substring(2)
        : hexCode;
    final bytes = <int>[];
    for (var i = 0; i < bytesString.length; i += 2) {
      bytes.add(int.parse(bytesString.substring(i, i + 2), radix: 16));
    }
    return sha256.convert(bytes).toString();
  }

  Future<void> _printPipelineUsersByRole(SeedPipelineData data) async {
    final users = data.users;
    final userByPubkey = {for (final u in users) u.keyPair.publicKey: u};

    Future<Map<String, dynamic>> userSummary(SeedUser user) async {
      final privateKey = user.keyPair.privateKey;
      final evmAddress = user.hasEvm && privateKey != null
          ? (await deriveEvmKey(privateKey)).address.eip55With0x
          : null;

      return {
        'nsec': user.keyPair.privateKeyBech32,
        'npub': user.keyPair.publicKeyBech32,
        'hasEvm': user.hasEvm,
        'evmAddress': evmAddress,
        'reservations': {'escrow': <String>[], 'zap': <String>[]},
      };
    }

    final guestEntries = await Future.wait(
      users
          .where((u) => !u.isHost)
          .where((u) => u.keyPair.privateKey != null)
          .map(
            (u) async => MapEntry(u.keyPair.privateKey!, await userSummary(u)),
          ),
    );
    final hostEntries = await Future.wait(
      users
          .where((u) => u.isHost)
          .where((u) => u.keyPair.privateKey != null)
          .map(
            (u) async => MapEntry(u.keyPair.privateKey!, await userSummary(u)),
          ),
    );

    final grouped = {
      'guest': {for (final entry in guestEntries) entry.key: entry.value},
      'host': {for (final entry in hostEntries) entry.key: entry.value},
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
