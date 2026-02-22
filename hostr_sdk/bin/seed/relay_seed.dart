import 'dart:convert';
import 'dart:io';

import 'package:hostr_sdk/datasources/anvil/anvil.dart';
import 'package:hostr_sdk/datasources/lnbits/lnbits.dart';
import 'package:hostr_sdk/seed/pipeline/seed_pipeline.dart';
import 'package:hostr_sdk/seed/pipeline/seed_pipeline_config.dart';
import 'package:hostr_sdk/seed/pipeline/seed_pipeline_models.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/ndk.dart';
import 'package:path/path.dart' as p;

class RelaySeeder {
  /// Run the seed pipeline with the given [SeedPipelineConfig].
  Future<int> runPipeline({required SeedPipelineConfig config}) async {
    print('Seeding ${config.relayUrl} (pipeline)...');
    print(const JsonEncoder.withIndent('  ').convert(config.toJson()));
    final contractAddress = await _resolveDeployedMultiEscrowAddress();
    print('Using contract address: $contractAddress');

    if (config.fundProfiles) {
      await _fundMockProfilesFromPipeline(
        rpcUrl: config.rpcUrl,
        amountWei: config.fundAmountWei ?? BigInt.parse('10000000000000000000'),
        config: config,
        contractAddress: contractAddress,
      );
    }

    Ndk? ndk;
    try {
      final pipeline = SeedPipeline(
        config: config,
        contractAddress: contractAddress,
      );
      final data = await pipeline.run();
      print('Built ${data.allEvents.length} events.');
      print(
        'Summary: ${const JsonEncoder.withIndent("  ").convert(data.summary.toJson())}',
      );

      final events = data.allEvents;

      if (config.setupLnbits) {
        await _setupLnbitsForProfiles(events: events, pipelineConfig: config);
        print('LNbits setup completed for profiles with lud16 usernames.');
      }

      ndk = Ndk(
        NdkConfig(
          eventVerifier: Bip340EventVerifier(),
          cache: MemCacheManager(),
          bootstrapRelays: [config.relayUrl!],
        ),
      );
      print('Waiting for relay connectivity...');
      await ndk.relays.seedRelaysConnected.timeout(const Duration(seconds: 20));

      await _broadcastEventsInBatches(ndk: ndk, events: events);

      print('Seeded ${events.length} events.');
      _printPipelineUsersByRole(data);
      return events.length;
    } finally {
      if (ndk != null) {
        await ndk.destroy();
      }
    }
  }

  static const int _broadcastBatchSize = 100;
  static const int _broadcastMaxAttempts = 3;

  Future<void> _broadcastEventsInBatches({
    required Ndk ndk,
    required List<Nip01Event> events,
  }) async {
    for (var start = 0; start < events.length; start += _broadcastBatchSize) {
      final end = (start + _broadcastBatchSize) > events.length
          ? events.length
          : (start + _broadcastBatchSize);

      final futures = <Future<void>>[];
      for (var i = start; i < end; i++) {
        futures.add(_broadcastEventWithRetry(ndk: ndk, event: events[i], i: i));
      }

      await Future.wait(futures);
      print('Broadcasted $end/${events.length} events...');

      // Mild pacing between batches to avoid relay congestion.
      // await Future.delayed(const Duration(milliseconds: 40));
    }
  }

  Future<void> _broadcastEventWithRetry({
    required Ndk ndk,
    required Nip01Event event,
    required int i,
  }) async {
    String? lastMsg;

    for (var attempt = 1; attempt <= _broadcastMaxAttempts; attempt++) {
      final broadcastResult = await ndk.broadcast
          .broadcast(nostrEvent: event)
          .broadcastDoneFuture;

      if (broadcastResult.isEmpty) {
        // Relay may have dropped the socket; wait for reconnection and retry.
        await ndk.relays.seedRelaysConnected.timeout(
          const Duration(seconds: 10),
          onTimeout: () async {},
        );
        await Future.delayed(Duration(milliseconds: 120 * attempt));
        continue;
      }

      final successful = broadcastResult.any((r) => r.broadcastSuccessful);
      if (successful) {
        return;
      }

      lastMsg = broadcastResult.isNotEmpty ? broadcastResult.first.msg : null;

      // Backoff for congested relay / transient websocket failures.
      await Future.delayed(Duration(milliseconds: 120 * attempt));
    }

    throw Exception(
      'Failed to broadcast event index=$i: ${lastMsg ?? ''}, ${event.toString()}',
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

  Future<void> _setupLnbitsForProfiles({
    required List<Nip01Event> events,
    required SeedPipelineConfig pipelineConfig,
  }) async {
    final usernamesByDomain = <String, Set<String>>{};
    final nip05ByDomain = <String, Map<String, String>>{};

    for (final profile in events.whereType<ProfileMetadata>()) {
      final lud16 = profile.metadata.lud16;
      if (lud16 != null) {
        final split = lud16.split('@');
        if (split.length == 2 && split[0].isNotEmpty && split[1].isNotEmpty) {
          usernamesByDomain
              .putIfAbsent(split[1].toLowerCase(), () => <String>{})
              .add(split[0]);
        }
      }

      final nip05 = profile.metadata.nip05;
      if (nip05 != null) {
        final split = nip05.split('@');
        if (split.length == 2 && split[0].isNotEmpty && split[1].isNotEmpty) {
          final domain = split[1].toLowerCase();
          // Only set up NIP-05 entries on LNbits-served domains.
          if (domain.startsWith('lnbits')) {
            nip05ByDomain.putIfAbsent(
              domain,
              () => <String, String>{},
            )[split[0]] = profile.pubKey;
          }
        }
      }
    }

    if (usernamesByDomain.isEmpty && nip05ByDomain.isEmpty) {
      print(
        'No profile lud16 usernames or nip05 entries found. '
        'Skipping LNbits setup.',
      );
      return;
    }

    final config = LnbitsSetupConfig.fromEnvironment(
      lnbits1BaseUrl: pipelineConfig.lnbits1BaseUrl,
      lnbits2BaseUrl: pipelineConfig.lnbits2BaseUrl,
      lnbitsAdminEmail: pipelineConfig.lnbitsAdminEmail,
      lnbitsAdminPassword: pipelineConfig.lnbitsAdminPassword,
      lnbitsExtensionName: pipelineConfig.lnbitsExtensionName,
      lnbitsNostrPrivateKey: pipelineConfig.lnbitsNostrPrivateKey,
    );

    final datasource = LnbitsDatasource();

    if (usernamesByDomain.isNotEmpty) {
      await datasource.setupUsernamesByDomain(
        usernamesByDomain: usernamesByDomain,
        config: config,
      );
    }

    if (nip05ByDomain.isNotEmpty) {
      final totalEntries = nip05ByDomain.values.fold<int>(
        0,
        (sum, m) => sum + m.length,
      );
      print(
        '[lnbits][nip05] Setting up $totalEntries NIP-05 entries across '
        '${nip05ByDomain.length} domain(s): ${nip05ByDomain.keys.join(', ')}',
      );
      for (final entry in nip05ByDomain.entries) {
        print(
          '[lnbits][nip05]   ${entry.key}: '
          '${entry.value.keys.join(', ')}',
        );
      }

      final domainIds = await datasource.setupNip05ByDomain(
        nip05ByDomain: nip05ByDomain,
        config: config,
      );

      print(
        '[lnbits][nip05] Finished NIP-05 setup. '
        'Created/verified ${domainIds.length} domain(s): $domainIds',
      );

      // Write nginx vhost location configs so that
      // /.well-known/nostr.json is proxied to the nostrnip5 API.
      _writeNip05NginxConfigs(domainIds);
    } else {
      print(
        '[lnbits][nip05] No NIP-05 entries to set up (no lnbits* domains found).',
      );
    }
  }

  void _writeNip05NginxConfigs(Map<String, String> domainIds) {
    // Resolve the project root (hostr_sdk is at <root>/hostr_sdk).
    final sdkDir = Platform.script.resolve('../../..').toFilePath();
    final projectRoot = Directory(sdkDir).parent.path;
    final vhostDir = Directory('$projectRoot/docker/vhost.d');
    if (!vhostDir.existsSync()) {
      vhostDir.createSync(recursive: true);
    }

    for (final entry in domainIds.entries) {
      final domain = entry.key;
      final domainId = entry.value;
      final file = File('${vhostDir.path}/${domain}_location');
      file.writeAsStringSync(
        '# Auto-generated by seed pipeline — proxies NIP-05 to nostrnip5\n'
        'location /.well-known/nostr.json {\n'
        '    proxy_pass http://127.0.0.1:5000'
        '/nostrnip5/api/v1/domain/$domainId/nostr.json;\n'
        '    proxy_set_header Host \$host;\n'
        '    proxy_set_header X-Real-IP \$remote_addr;\n'
        '}\n',
      );
      print('Wrote nginx vhost config: ${file.path}');
    }
  }

  // ── Pipeline-aware helpers ────────────────────────────────────────────────

  Future<void> _fundMockProfilesFromPipeline({
    required String rpcUrl,
    required BigInt amountWei,
    required SeedPipelineConfig config,
    required String contractAddress,
  }) async {
    final privateKeys = <String>{
      if (MockKeys.hoster.privateKey != null) MockKeys.hoster.privateKey!,
      if (MockKeys.guest.privateKey != null) MockKeys.guest.privateKey!,
      if (MockKeys.escrow.privateKey != null) MockKeys.escrow.privateKey!,
      ...mockKeys.map((k) => k.privateKey).whereType<String>(),
    };

    // Derive pipeline users to get their private keys for funding.
    final pipeline = SeedPipeline(
      config: config,
      contractAddress: contractAddress,
    );
    final users = pipeline.buildUsers();
    privateKeys.addAll(
      users.map((u) => u.keyPair.privateKey).whereType<String>(),
    );
    pipeline.dispose();

    final addresses = privateKeys
        .map((pk) => getEvmCredentials(pk).address.eip55With0x)
        .toSet()
        .toList(growable: false);

    print('Funding ${addresses.length} mock EVM addresses via $rpcUrl...');

    final anvilClient = AnvilClient(rpcUri: Uri.parse(rpcUrl));
    try {
      for (final address in addresses) {
        final funded = await anvilClient.setBalance(
          address: address,
          amountWei: amountWei,
        );
        if (!funded) {
          throw Exception(
            'Could not fund $address on $rpcUrl. Neither anvil_setBalance nor hardhat_setBalance is supported.',
          );
        }
      }
    } finally {
      anvilClient.close();
    }
    print(
      'Funded ${addresses.length} mock addresses with $amountWei wei each.',
    );
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
