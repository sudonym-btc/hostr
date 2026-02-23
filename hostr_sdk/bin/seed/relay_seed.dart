import 'dart:convert';
import 'dart:io';

import 'package:hostr_sdk/datasources/anvil/anvil.dart';
import 'package:hostr_sdk/seed/pipeline/seed_pipeline.dart';
import 'package:hostr_sdk/seed/pipeline/seed_pipeline_config.dart';
import 'package:hostr_sdk/seed/pipeline/seed_pipeline_models.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:path/path.dart' as p;
import 'package:rxdart/rxdart.dart';

class RelaySeeder {
  /// Run the seed pipeline with the given [SeedPipelineConfig].
  Future<int> runPipeline({required SeedPipelineConfig config}) async {
    print('Seeding ${config.relayUrl} (pipeline)...');
    print(const JsonEncoder.withIndent('  ').convert(config.toJson()));
    final contractAddress = await _resolveDeployedMultiEscrowAddress();
    print('Using contract address: $contractAddress');

    // Enable automine so seed transactions confirm instantly.
    final anvilClient = AnvilClient(rpcUri: Uri.parse(config.rpcUrl));
    try {
      final automineOk = await anvilClient.setAutomine(true);
      if (automineOk) {
        print('Enabled automine for seeding.');
      }
    } catch (e) {
      print('Could not enable automine (non-fatal): $e');
    }

    Ndk? ndk;
    try {
      final sw = Stopwatch()..start();

      // ── Verify relay is accepting WSS connections before anything else ──
      // NDK has a tight 4 s connect timeout which loses the race when the
      // event loop is saturated by hundreds of parallel EVM transactions.
      // A direct dart:io WebSocket.connect (which respects HttpOverrides)
      // gives us a clean, isolated check with a generous timeout.
      await _ensureRelayReachable(config.relayUrl!);

      // ── Relay: create NDK and connect (relay is already proven up) ───
      ndk = Ndk(
        NdkConfig(
          eventVerifier: Bip340EventVerifier(),
          cache: MemCacheManager(),
          bootstrapRelays: [config.relayUrl!],
        ),
      );
      sw.reset();
      print('Waiting for relay connectivity...');
      await ndk.relays.seedRelaysConnected.timeout(const Duration(seconds: 20));
      print('Relay connected. [relay ${sw.elapsedMilliseconds} ms]');

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

      // ── Broadcast: consume events with rxdart operators ──────────────
      sw.reset();
      int broadcastCount = 0;

      await streams.events.bufferCount(_broadcastBatchSize).asyncMap((
        batch,
      ) async {
        final futures = <Future<void>>[];
        for (var i = 0; i < batch.length; i++) {
          futures.add(
            _broadcastEventWithRetry(
              ndk: ndk!,
              event: batch[i],
              i: broadcastCount + i,
              relayUrl: config.relayUrl!,
            ),
          );
        }
        await Future.wait(futures);
        broadcastCount += batch.length;
        final typeCounts = <String, int>{};
        for (final event in batch) {
          final name = event.runtimeType.toString();
          typeCounts[name] = (typeCounts[name] ?? 0) + 1;
        }
        final typeStr = typeCounts.entries
            .map((e) => '${e.value}× ${e.key}')
            .join(', ');
        print(
          'Broadcasted ${batch.length} events '
          '($typeStr) [$broadcastCount total]',
        );

        // Mild pacing between batches to avoid relay congestion.
        await Future.delayed(const Duration(milliseconds: 50));
      }).drain<void>();

      print(
        'Built $broadcastCount events. '
        '[pipeline+broadcast ${sw.elapsedMilliseconds} ms]',
      );

      // ── Summary ──────────────────────────────────────────────────────
      final data = await streams.done.first;
      print(
        'Summary: ${const JsonEncoder.withIndent("  ").convert(data.summary.toJson())}',
      );
      _printPipelineUsersByRole(data);

      print('Seeded $broadcastCount events.');

      // Switch to interval mining for realistic local development.
      try {
        await anvilClient.setAutomine(false);
        final intervalOk = await anvilClient.setIntervalMining(30);
        if (intervalOk) {
          print('Switched to 30 s interval mining.');
        }
      } catch (e) {
        print('Could not set interval mining (non-fatal): $e');
      }

      return broadcastCount;
    } finally {
      anvilClient.close();
      if (ndk != null) {
        await ndk.destroy();
      }
    }
  }

  static const int _broadcastBatchSize = 50;
  static const int _broadcastMaxAttempts = 6;

  /// Verify the relay is accepting WSS connections before creating NDK.
  ///
  /// Uses a direct [WebSocket.connect] (which honours [HttpOverrides] for
  /// self-signed certs) with a generous per-attempt timeout. This avoids
  /// the race condition where NDK's tight 4 s bootstrap timeout loses to
  /// hundreds of parallel EVM transactions saturating the event loop.
  Future<void> _ensureRelayReachable(
    String relayUrl, {
    Duration timeout = const Duration(seconds: 60),
  }) async {
    print('Verifying relay reachable at $relayUrl ...');
    final sw = Stopwatch()..start();
    while (sw.elapsed < timeout) {
      try {
        final ws = await WebSocket.connect(
          relayUrl,
        ).timeout(const Duration(seconds: 10));
        await ws.close();
        print('Relay verified reachable. [${sw.elapsedMilliseconds} ms]');
        return;
      } catch (e) {
        print(
          'Relay not reachable yet ($e), retrying in 2 s... '
          '(${sw.elapsed.inSeconds}s elapsed)',
        );
        await Future.delayed(const Duration(seconds: 2));
      }
    }
    throw Exception(
      'Relay $relayUrl not reachable after ${timeout.inSeconds}s',
    );
  }

  Future<void> _broadcastEventWithRetry({
    required Ndk ndk,
    required Nip01Event event,
    required int i,
    required String relayUrl,
  }) async {
    String? lastMsg;

    for (var attempt = 1; attempt <= _broadcastMaxAttempts; attempt++) {
      try {
        final broadcastResult = await ndk.broadcast
            .broadcast(nostrEvent: event, specificRelays: [relayUrl])
            .broadcastDoneFuture;

        if (broadcastResult.isEmpty) {
          // Relay may have dropped the socket; wait for reconnection and retry.
          await ndk.relays.seedRelaysConnected.timeout(
            const Duration(seconds: 15),
            onTimeout: () async {},
          );
          await Future.delayed(Duration(milliseconds: 300 * attempt));
          continue;
        }

        final successful = broadcastResult.any((r) => r.broadcastSuccessful);
        if (successful) {
          return;
        }

        lastMsg = broadcastResult.isNotEmpty ? broadcastResult.first.msg : null;
      } catch (e) {
        lastMsg = e.toString();
        // Socket/connection error — wait for relay to reconnect.
        await ndk.relays.seedRelaysConnected.timeout(
          const Duration(seconds: 15),
          onTimeout: () async {},
        );
      }

      // Backoff for congested relay / transient websocket failures.
      await Future.delayed(Duration(milliseconds: 300 * attempt));
    }

    throw Exception(
      'Failed to broadcast event index=$i '
      '(kind=${event.kind}, ${event.runtimeType}): '
      '${lastMsg ?? 'no response from relay'}',
    );
  }

  Future<String> _resolveDeployedMultiEscrowAddress() async {
    final deploymentFiles = _candidateDeploymentFiles();

    final addressRegex = RegExp(r'^0x[a-fA-F0-9]{40}$');

    for (final file in deploymentFiles) {
      if (!await file.exists()) {
        continue;
      }

      final raw = await file.readAsString();
      final decoded = jsonDecode(raw);
      if (decoded is! Map) {
        continue;
      }

      final map = Map<String, dynamic>.from(decoded);

      for (final entry in map.entries) {
        final value = entry.value;
        if (value is! String) {
          continue;
        }

        if (!addressRegex.hasMatch(value)) {
          continue;
        }

        if (entry.key.toLowerCase().contains('multiescrow')) {
          return value;
        }
      }

      for (final value in map.values) {
        if (value is String && addressRegex.hasMatch(value)) {
          return value;
        }
      }
    }

    throw Exception(
      'No deployed multi-escrow contract address found in candidate files: ${deploymentFiles.map((f) => f.path).join(', ')}',
    );
  }

  List<File> _candidateDeploymentFiles() {
    final files = <File>[];
    final seen = <String>{};

    void add(String path) {
      final normalized = p.normalize(path);
      if (seen.add(normalized)) {
        files.add(File(normalized));
      }
    }

    // Most common when running from hostr_sdk directory.
    add(
      p.join(
        Directory.current.path,
        '..',
        'escrow',
        'contracts',
        'ignition',
        'deployments',
        'chain-33',
        'deployed_addresses.json',
      ),
    );

    // If running from repo root.
    add(
      p.join(
        Directory.current.path,
        'escrow',
        'contracts',
        'ignition',
        'deployments',
        'chain-33',
        'deployed_addresses.json',
      ),
    );

    // Relative to executing script location.
    final scriptPath = Platform.script.toFilePath();
    final scriptDir = p.dirname(scriptPath);
    final sdkRoot = p.normalize(p.join(scriptDir, '..'));
    add(
      p.join(
        sdkRoot,
        '..',
        'escrow',
        'contracts',
        'ignition',
        'deployments',
        'chain-33',
        'deployed_addresses.json',
      ),
    );

    return files;
  }

  void _printPipelineUsersByRole(SeedPipelineData data) {
    final users = data.users;
    final userByPubkey = {for (final u in users) u.keyPair.publicKey: u};

    Map<String, dynamic> userSummary(SeedUser user) {
      final privateKey = user.keyPair.privateKey;
      final evmAddress = user.hasEvm && privateKey != null
          ? getEvmCredentials(privateKey).address.eip55With0x
          : null;

      return {
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
      final commitmentHash = reservation.parsedTags.commitmentHash;
      final proof = reservation.parsedContent.proof;
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
          (reservations['escrow'] as List<String>).add(commitmentHash);
        }
        if (usesZap) {
          (reservations['zap'] as List<String>).add(commitmentHash);
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
