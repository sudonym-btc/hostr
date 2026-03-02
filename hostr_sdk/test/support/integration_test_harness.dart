import 'dart:io';

import 'package:hostr_sdk/datasources/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/injection.dart';
import 'package:hostr_sdk/seed/seed.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:logger/logger.dart';
import 'package:models/nostr_kinds.dart';
import 'package:ndk/ndk.dart' hide ConsoleOutput;
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

/// Shared integration-test bootstrap for Hostr SDK tests.
///
/// Provides a single place for:
/// - hydrated storage setup
/// - Hostr config defaults
/// - Anvil client setup
/// - AlbyHub client setup
/// - optional NWC pairing helper
/// - seed-backed fixture generator
class IntegrationTestHarness {
  final Hostr hostr;
  final AnvilClient anvil;
  final AlbyHubClient albyHub;
  final TestSeedHelper seeds;
  final Directory hydratedDir;

  /// Pubkeys of NWC app connections created during this harness lifetime.
  /// Used by [dispose] to tear them down and free relay subscription slots.
  final List<String> _createdAppPubkeys = [];

  IntegrationTestHarness({
    required this.hostr,
    required this.anvil,
    required this.albyHub,
    required this.seeds,
    required this.hydratedDir,
  });

  static const bootstrapRelays = ['wss://relay.hostr.development'];
  static const bootstrapBlossom = ['https://blossom.hostr.development'];
  static const hostrRelay = 'wss://relay.hostr.development';
  static const anvilRpc = 'http://localhost:8545';
  static const albyHubUrl = 'https://alby1.hostr.development';

  static Future<IntegrationTestHarness> create({
    required String name,
    String environment = Env.dev,
    int seed = 42,
    Level logLevel = Level.warning,
    bool cleanHydratedStorage = true,
  }) async {
    CustomLogger.configure(output: ConsoleOutput(), level: logLevel);

    final storageDir = Directory('${Directory.systemTemp.path}/$name');
    if (cleanHydratedStorage && storageDir.existsSync()) {
      storageDir.deleteSync(recursive: true);
    }
    if (!storageDir.existsSync()) {
      storageDir.createSync(recursive: true);
    }

    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: HydratedStorageDirectory(storageDir.path),
    );

    final hostr = Hostr(
      environment: environment,
      config: HostrConfig(
        logs: CustomLogger(),
        bootstrapRelays: bootstrapRelays,
        bootstrapBlossom: bootstrapBlossom,
        hostrRelay: hostrRelay,
        rootstockConfig: _DevelopmentRootstockConfig(),
      ),
    );

    final anvil = AnvilClient(rpcUri: Uri.parse(anvilRpc));
    final albyHub = AlbyHubClient(
      baseUri: Uri.parse(albyHubUrl),
      unlockPassword: Platform.environment['ALBYHUB_PASSWORD'] ?? 'Testing123!',
    );

    return IntegrationTestHarness(
      hostr: hostr,
      anvil: anvil,
      albyHub: albyHub,
      hydratedDir: storageDir,
      seeds: TestSeedHelper(seed: seed),
    );
  }

  Future<void> signInAndConnectNwc({
    required KeyPair user,
    required String appNamePrefix,
  }) async {
    await hostr.auth.signin(user.privateKey!);
    final pairingUrl = await albyHub.getConnectionForUser(
      user,
      appName: '$appNamePrefix-${DateTime.now().millisecondsSinceEpoch}',
    );
    if (pairingUrl == null) {
      throw StateError(
        'Failed to obtain NWC pairing URL for ${user.publicKey}',
      );
    }

    // Wait for AlbyHub to publish the kind 13194 info event for this app's
    // wallet pubkey to the relay. Without this, NDK's connect() may query
    // before the event has propagated → empty permissions → "method not in
    // permissions" errors.
    final parsedUri = Uri.parse(pairingUrl);
    final walletPubkey = parsedUri.host;

    // The `secret` query param is the app's private key. Derive its public
    // key — that's the appPubkey AlbyHub indexes connections by.
    final appSecret = parsedUri.queryParameters['secret'];
    if (appSecret != null) {
      _createdAppPubkeys.add(Bip340.getPublicKey(appSecret));
    }
    await hostr.requests
        .subscribe(
          filter: Filter(kinds: [kNostrKindNWCInfo], authors: [walletPubkey]),
          name: 'nwc-info-wait',
        )
        .stream
        .take(1)
        .toList();

    await hostr.nwc.initiateAndAdd(pairingUrl);
  }

  Future<void> dispose({bool resetGetIt = true}) async {
    await hostr.dispose();
    if (resetGetIt) {
      await getIt.reset();
    }

    print('IntegrationTestHarness disposed');
    print(_createdAppPubkeys);
    // Tear down NWC app connections on AlbyHub to free relay subscription
    // slots. Errors are swallowed so a single failure doesn't block the rest.
    for (final pubkey in _createdAppPubkeys) {
      try {
        await albyHub.destroyConnection(pubkey);
      } catch (e) {
        // best-effort cleanup
        CustomLogger().e(
          'Failed to destroy AlbyHub connection for $pubkey',
          error: e,
        );
      }
    }
    _createdAppPubkeys.clear();
    albyHub.close();
    seeds.dispose();
  }

  static void resetLogLevel() {
    CustomLogger.configure(level: Level.trace);
  }
}

class _DevelopmentRootstockConfig extends RootstockConfig {
  _DevelopmentRootstockConfig();

  @override
  int get chainId => 33;

  @override
  String get rpcUrl => IntegrationTestHarness.anvilRpc;

  @override
  BoltzConfig get boltz => _DevelopmentBoltzConfig();
}

class _DevelopmentBoltzConfig extends BoltzConfig {
  _DevelopmentBoltzConfig();

  @override
  String get apiUrl => 'http://localhost:9001/v2';

  @override
  String get rifRelayUrl => 'http://localhost:8090';

  @override
  String get rifRelayCallVerifier =>
      '0x5FC8d32690cc91D4c39d9d3abcBD16989F875707';

  @override
  String get rifRelayDeployVerifier =>
      '0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9';

  @override
  String get rifSmartWalletFactoryAddress =>
      '0x9A9f2CCfdE556A7E9Ff0848998Aa4a0CFD8863AE';
}
