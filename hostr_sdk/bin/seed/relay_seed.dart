import 'dart:convert';
import 'dart:io';

import 'package:hostr_sdk/datasources/lnbits/lnbits.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/ndk.dart';
import 'package:path/path.dart' as p;

import 'deterministic_seed_builder.dart';
import 'seed_models.dart';

class RelaySeeder {
  Future<int> run({required DeterministicSeedConfig config}) async {
    print('Seeding ${config.relayUrl}...');
    final contractAddress = await _resolveDeployedMultiEscrowAddress();
    print('Using contract address: $contractAddress');

    if (config.fundProfiles) {
      await _fundMockProfiles(
        rpcUrl: config.rpcUrl,
        amountWei: config.fundAmountWei ?? BigInt.parse('10000000000000000000'),
        deterministicConfig: config,
      );
    }

    final ndk = Ndk(
      NdkConfig(
        eventVerifier: Bip340EventVerifier(),
        cache: MemCacheManager(),
        bootstrapRelays: [config.relayUrl!],
      ),
    );
    final mocked = await MOCK_EVENTS(contractAddress: contractAddress);
    final events = config == null
        ? mocked
        : [
            ...(await DeterministicSeedBuilder(
              config: config.validated(),
              contractAddress: contractAddress,
              rpcUrl: config.rpcUrl,
            ).build()).allEvents,
            ...mocked,
          ];

    if (config.setupLnbits) {
      await _setupLnbitsForProfiles(
        events: events,
        deterministicConfig: config,
      );
    }

    for (var i = 0; i < events.length; i++) {
      final event = events[i];
      var success = false;
      String? lastMsg;

      for (var attempt = 1; attempt <= 3; attempt++) {
        final broadcastResult = await ndk.broadcast
            .broadcast(nostrEvent: event)
            .broadcastDoneFuture;

        if (broadcastResult.first.broadcastSuccessful) {
          success = true;
          break;
        }

        lastMsg = broadcastResult.first.msg;

        // Backoff for congested relay / transient websocket failures.
        await Future.delayed(Duration(milliseconds: 120 * attempt));
      }

      if (!success) {
        throw Exception(
          'Failed to broadcast event index=$i/${events.length - 1}: ${lastMsg ?? ''}, ${event.toString()}',
        );
      }

      // Lightweight pacing so large seed sets don't overwhelm relay IO.
      if (i % 10 == 0) {
        await Future.delayed(const Duration(milliseconds: 25));
      }
    }

    print('Seeded ${events.length} events.');
    return events.length;
  }

  Future<DeterministicSeedData> buildDeterministicEvents({
    required DeterministicSeedConfig config,
    String rpcUrl = 'http://localhost:8545',
  }) async {
    final contractAddress = await _resolveDeployedMultiEscrowAddress();
    return DeterministicSeedBuilder(
      config: config.validated(),
      contractAddress: contractAddress,
      rpcUrl: rpcUrl,
    ).build();
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

  Future<void> _fundMockProfiles({
    required String rpcUrl,
    required BigInt amountWei,
    DeterministicSeedConfig? deterministicConfig,
  }) async {
    final privateKeys = <String>{
      if (MockKeys.hoster.privateKey != null) MockKeys.hoster.privateKey!,
      if (MockKeys.guest.privateKey != null) MockKeys.guest.privateKey!,
      if (MockKeys.escrow.privateKey != null) MockKeys.escrow.privateKey!,
      ...mockKeys.map((k) => k.privateKey).whereType<String>(),
    };

    if (deterministicConfig != null) {
      final deterministicUsers = DeterministicSeedBuilder(
        config: deterministicConfig.validated(),
        contractAddress: await _resolveDeployedMultiEscrowAddress(),
      ).deriveUsers();

      privateKeys.addAll(
        deterministicUsers.map((u) => u.keyPair.privateKey).whereType<String>(),
      );
    }

    final addresses = privateKeys
        .map((pk) => getEvmCredentials(pk).address.eip55With0x)
        .toSet()
        .toList(growable: false);

    print('Funding ${addresses.length} mock EVM addresses via $rpcUrl...');

    for (final address in addresses) {
      final funded =
          await _setBalance(rpcUrl, 'anvil_setBalance', address, amountWei) ||
          await _setBalance(rpcUrl, 'hardhat_setBalance', address, amountWei);

      if (!funded) {
        throw Exception(
          'Could not fund $address on $rpcUrl. Neither anvil_setBalance nor hardhat_setBalance is supported.',
        );
      }
    }

    print(
      'Funded ${addresses.length} mock addresses with $amountWei wei each.',
    );
  }

  Future<bool> _setBalance(
    String rpcUrl,
    String method,
    String address,
    BigInt amountWei,
  ) async {
    final uri = Uri.parse(rpcUrl);
    final request = await HttpClient().postUrl(uri);
    request.headers.contentType = ContentType.json;
    request.write(
      jsonEncode({
        'jsonrpc': '2.0',
        'id': 1,
        'method': method,
        'params': [address, '0x${amountWei.toRadixString(16)}'],
      }),
    );

    final response = await request.close();
    final body = await utf8.decodeStream(response);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      return false;
    }

    final decoded = jsonDecode(body) as Map<String, dynamic>;
    return decoded['error'] == null;
  }

  Future<void> _setupLnbitsForProfiles({
    required List<Nip01Event> events,
    DeterministicSeedConfig? deterministicConfig,
  }) async {
    final usernamesByDomain = <String, Set<String>>{};

    for (final profile in events.whereType<ProfileMetadata>()) {
      final lud16 = profile.metadata.lud16;
      if (lud16 == null) {
        continue;
      }

      final split = lud16.split('@');
      if (split.length != 2 || split[0].isEmpty || split[1].isEmpty) {
        continue;
      }

      usernamesByDomain
          .putIfAbsent(split[1].toLowerCase(), () => <String>{})
          .add(split[0]);
    }

    if (usernamesByDomain.isEmpty) {
      print('No profile lud16 usernames found. Skipping LNbits setup.');
      return;
    }

    final config = LnbitsSetupConfig.fromEnvironment(
      lnbits1BaseUrl: deterministicConfig?.lnbits1BaseUrl,
      lnbits2BaseUrl: deterministicConfig?.lnbits2BaseUrl,
      lnbitsAdminEmail: deterministicConfig?.lnbitsAdminEmail,
      lnbitsAdminPassword: deterministicConfig?.lnbitsAdminPassword,
      lnbitsExtensionName: deterministicConfig?.lnbitsExtensionName,
      lnbitsNostrPrivateKey: deterministicConfig?.lnbitsNostrPrivateKey,
    );

    await LnbitsDatasource().setupUsernamesByDomain(
      usernamesByDomain: usernamesByDomain,
      config: config,
    );
  }
}
