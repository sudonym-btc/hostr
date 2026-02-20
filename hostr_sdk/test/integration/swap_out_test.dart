import 'dart:io';

import 'package:hostr_sdk/datasources/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/injection.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:logger/logger.dart';
import 'package:models/stubs/main.dart';
import 'package:test/test.dart';

void main() {
  late Hostr hostr;
  late AnvilClient anvil;
  late AlbyHubClient albyHub;

  setUpAll(() async {
    CustomLogger.configure(level: Level.debug);

    final storageDir = Directory(
      '${Directory.systemTemp.path}/hostr_swap_out_it',
    );
    if (storageDir.existsSync()) {
      storageDir.deleteSync(recursive: true);
    }
    storageDir.createSync(recursive: true);

    HydratedBloc.storage = await HydratedStorage.build(
      storageDirectory: HydratedStorageDirectory(storageDir.path),
    );

    hostr = Hostr(
      environment: Env.dev,
      config: HostrConfig(
        logs: CustomLogger(),
        bootstrapRelays: ['ws://relay.hostr.development'],
        bootstrapBlossom: ['http://blossom.hostr.development'],
        rootstockConfig: _DevelopmentRootstockConfig(),
      ),
    );
    anvil = AnvilClient(rpcUri: Uri.parse('http://localhost:8545'));
    albyHub = AlbyHubClient(
      baseUri: Uri.parse('https://alby1.hostr.development'),
      unlockPassword: Platform.environment['ALBYHUB_PASSWORD'] ?? 'Testing123!',
    );
  });

  tearDownAll(() {
    CustomLogger.configure(level: Level.trace);
  });

  tearDown(() async {
    await hostr.dispose();
    await getIt.reset();
  });

  test(
    'swap out emits expected state flow when NWC is connected',
    () async {
      try {
        await hostr.auth.signin(MockKeys.guest.privateKey!);

        final pairingUrl = await albyHub.getConnectionForUser(
          MockKeys.guest,
          appName: 'swap-out-it-${DateTime.now().millisecondsSinceEpoch}',
        );
        await hostr.nwc.initiateAndAdd(pairingUrl!);

        await anvil.setBalance(
          address: hostr.auth.getActiveEvmKey().address.eip55With0x,
          amountWei: BitcoinAmount.fromInt(BitcoinUnit.sat, 100000).getInWei,
        );

        final evm = getIt<Evm>();
        final swapOut = evm.rootstock.swapOutAll();

        final emittedStates = <SwapOutState>[swapOut.state];
        final sub = swapOut.stream.listen(emittedStates.add);

        await swapOut.execute();
        await sub.cancel();

        expect(emittedStates.first, isA<SwapOutInitialised>());
        expect(
          emittedStates.any((state) => state is SwapOutAwaitingOnChain),
          isTrue,
        );
        expect(emittedStates.any((state) => state is SwapOutFunded), isTrue);
        expect(emittedStates.last, isA<SwapOutCompleted>());
      } finally {
        albyHub.close();
      }
    },
    timeout: const Timeout(Duration(seconds: 25)),
  );

  test(
    'swap out fails with expected state flow when NWC is not connected',
    () async {
      hostr = Hostr(
        environment: Env.dev,
        config: HostrConfig(
          logs: CustomLogger(),
          bootstrapRelays: ['ws://relay.hostr.development'],
          bootstrapBlossom: ['http://blossom.hostr.development'],
          rootstockConfig: _DevelopmentRootstockConfig(),
        ),
      );
      if (!getIt.isRegistered<Hostr>()) {
        getIt.registerSingleton<Hostr>(hostr);
      }

      hostr.start();
      await hostr.auth.signin(MockKeys.guest.privateKey!);

      await anvil.setBalance(
        address: hostr.auth.getActiveEvmKey().address.eip55With0x,
        amountWei: BitcoinAmount.fromInt(BitcoinUnit.sat, 100000).getInWei,
      );

      final evm = getIt<Evm>();
      final swapOut = evm.rootstock.swapOutAll();

      final emittedStates = <SwapOutState>[swapOut.state];
      final sub = swapOut.stream.listen(emittedStates.add);

      Object? thrown;
      try {
        await swapOut.execute();
      } catch (e) {
        thrown = e;
      } finally {
        await sub.cancel();
      }

      expect(thrown, isNotNull);
      expect(thrown.toString(), contains('No active NWC connection'));

      expect(emittedStates.first, isA<SwapOutInitialised>());
      expect(emittedStates.last, isA<SwapOutFailed>());
      expect(
        emittedStates.any((state) => state is SwapOutAwaitingOnChain),
        isFalse,
      );
    },
    timeout: const Timeout(Duration(seconds: 15)),
  );
}

class _DevelopmentRootstockConfig extends RootstockConfig {
  @override
  int get chainId => 33;

  @override
  String get rpcUrl => 'http://localhost:8545';

  @override
  BoltzConfig get boltz => _DevelopmentBoltzConfig();
}

class _DevelopmentBoltzConfig extends BoltzConfig {
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
