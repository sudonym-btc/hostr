import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:meta/meta.dart' show visibleForTesting;
import 'package:models/stubs/main.dart' show MockKeys;
import 'package:ndk/shared/nips/nip01/key_pair.dart';

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

  static const int _maxConcurrentBroadcasts = 50;
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

    final signetTargets = selectSignetBunkerSeedKeyTargets(data.users);

    print(
      'Inserting first host/guest/escrow seeded nsecs into Signet bunker: '
      '$baseUri',
    );
    final client = SignetBunkerClient(baseUri: baseUri);
    try {
      await client.deleteKeysWithPrefix(_signetGeneratedKeyPrefix);
      final imported = <Map<String, dynamic>>[];
      for (final target in signetTargets) {
        final nsec = target.keyPair.privateKeyBech32;
        if (nsec == null || nsec.isEmpty) continue;

        final keyName = _signetKeyName(config: config, target: target);
        final key = await client.importNsec(
          keyName: keyName,
          nsec: nsec,
          replaceExisting: false,
        );
        imported.add({
          'keyName': key.keyName,
          'role': target.role,
          'npub': target.keyPair.publicKeyBech32,
          'bunkerUri': key.bunkerUri,
        });
      }

      final selectedUserCount = signetTargets
          .where((target) => target.userIndex != null)
          .length;
      final skippedCount = data.users.length - selectedUserCount;
      print(
        'Inserted ${imported.length} seeded nsecs into Signet bunker '
        '(${skippedCount < 0 ? 0 : skippedCount} users skipped).',
      );
      if (imported.isNotEmpty) {
        print(const JsonEncoder.withIndent('  ').convert(imported));
      }
    } finally {
      await client.close();
    }
  }

  String _signetKeyName({
    required SeedPipelineConfig config,
    required SignetBunkerSeedKeyTarget target,
  }) {
    final index = target.userIndex;
    final suffix = index == null ? '' : '-$index';
    return '${_signetKeyPrefix(config)}${target.role}$suffix';
  }

  static const String _signetGeneratedKeyPrefix = 'hostr-seed-';

  String _signetKeyPrefix(SeedPipelineConfig config) =>
      '$_signetGeneratedKeyPrefix${config.seed}-';

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
    final usage = {
      'guest': {'escrow': <String>{}, 'zap': <String>{}},
      'host': {'escrow': <String>{}, 'zap': <String>{}},
    };

    for (final order in data.orders) {
      final tradeId = order.getDtag() ?? order.id;
      final proof = order.proof;
      if (proof == null) continue;

      final usesEscrow = proof.hasEscrowPaymentProof;
      final usesZap = proof.zapParams != null;
      final guest = userByPubkey[order.pubKey];
      final host = userByPubkey[proof.listing.pubKey];

      void addToRole(SeedUser? user, String role) {
        if (user == null) return;
        final orders = usage[role]!;
        if (usesEscrow) {
          orders['escrow']!.add(tradeId);
        }
        if (usesZap) {
          orders['zap']!.add(tradeId);
        }
      }

      addToRole(guest, 'guest');
      addToRole(host, 'host');
    }

    final hosts = users.where((u) => u.isHost).toList();
    final guests = users.where((u) => !u.isHost).toList();

    print('Seed users by role with order proof usage:');
    print(
      const JsonEncoder.withIndent('  ').convert({
        'guest': {
          'users': guests.length,
          'with_private_key': guests
              .where((u) => u.keyPair.privateKey != null)
              .length,
          'with_evm': guests.where((u) => u.hasEvm).length,
          'escrow_orders': usage['guest']!['escrow']!.length,
          'zap_orders': usage['guest']!['zap']!.length,
        },
        'host': {
          'users': hosts.length,
          'with_private_key': hosts
              .where((u) => u.keyPair.privateKey != null)
              .length,
          'with_evm': hosts.where((u) => u.hasEvm).length,
          'escrow_orders': usage['host']!['escrow']!.length,
          'zap_orders': usage['host']!['zap']!.length,
        },
      }),
    );
  }
}

@visibleForTesting
class SignetBunkerSeedKeyTarget {
  final String role;
  final int? userIndex;
  final KeyPair keyPair;

  const SignetBunkerSeedKeyTarget({
    required this.role,
    required this.keyPair,
    this.userIndex,
  });
}

@visibleForTesting
List<SignetBunkerSeedKeyTarget> selectSignetBunkerSeedKeyTargets(
  List<SeedUser> users,
) {
  final selectedUsers = selectSignetBunkerSeedUsers(users);
  return [
    for (final user in selectedUsers)
      SignetBunkerSeedKeyTarget(
        role: user.isHost ? 'host' : 'guest',
        userIndex: user.index,
        keyPair: user.keyPair,
      ),
    SignetBunkerSeedKeyTarget(role: 'escrow', keyPair: MockKeys.escrow),
  ];
}

@visibleForTesting
List<SeedUser> selectSignetBunkerSeedUsers(List<SeedUser> users) {
  SeedUser? firstHost;
  SeedUser? firstGuest;

  for (final user in users) {
    if (user.isHost && firstHost == null) {
      firstHost = user;
    } else if (!user.isHost && firstGuest == null) {
      firstGuest = user;
    }

    if (firstHost != null && firstGuest != null) break;
  }

  return [?firstHost, ?firstGuest];
}
