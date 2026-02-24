import 'dart:convert';
import 'dart:io';

import 'package:hostr_sdk/datasources/anvil/anvil.dart';
import 'package:hostr_sdk/seed/pipeline/seed_pipeline.dart';
import 'package:hostr_sdk/seed/pipeline/seed_pipeline_config.dart';
import 'package:hostr_sdk/seed/pipeline/seed_pipeline_models.dart';
import 'package:models/main.dart';
import 'package:path/path.dart' as p;

import 'broadcast_isolate.dart';

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
