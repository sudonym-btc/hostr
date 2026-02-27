import 'dart:io';

import 'package:hostr_sdk/datasources/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/injection.dart';
import 'package:hostr_sdk/seed/seed.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:logger/logger.dart';
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

  const IntegrationTestHarness({
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
    CustomLogger.configure(level: logLevel);

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
    await hostr.nwc.initiateAndAdd(pairingUrl);
  }

  Future<void> dispose({bool resetGetIt = true}) async {
    await hostr.dispose();
    if (resetGetIt) {
      await getIt.reset();
    }
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
