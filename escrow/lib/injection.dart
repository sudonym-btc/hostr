import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

final getIt = GetIt.instance;

Future<void> setupInjection({
  required String relayUrl,
  required String rpcUrl,
  required String blossomUrl,
  String environment = 'dev',
}) async {
  await _ensureHydratedStorage();

  if (getIt.isRegistered<Hostr>()) {
    await getIt.unregister<Hostr>(
        disposingFunction: (hostr) => hostr.dispose());
  }

  getIt.registerSingleton<Hostr>(
    Hostr(
      environment: environment,
      config: HostrConfig(
        logs: CustomLogger(),
        bootstrapRelays: [relayUrl],
        bootstrapBlossom: [blossomUrl],
        hostrRelay: relayUrl,
        rootstockConfig: _EscrowRootstockConfig(rpcUrl: rpcUrl),
      ),
    ),
  );
}

Future<void> _ensureHydratedStorage() async {
  final storageDir = Directory('${Directory.systemTemp.path}/hostr_escrow');
  if (!storageDir.existsSync()) {
    storageDir.createSync(recursive: true);
  }

  HydratedBloc.storage = await HydratedStorage.build(
    storageDirectory: HydratedStorageDirectory(storageDir.path),
  );
}

class _EscrowRootstockConfig extends RootstockConfig {
  final String _rpcUrl;

  _EscrowRootstockConfig({required String rpcUrl}) : _rpcUrl = rpcUrl;

  @override
  int get chainId => 33;

  @override
  String get rpcUrl => _rpcUrl;

  @override
  BoltzConfig get boltz => _EscrowBoltzConfig();
}

class _EscrowBoltzConfig extends BoltzConfig {
  @override
  String get apiUrl => 'http://localhost:9001/v2';

  @override
  String get rifRelayCallVerifier =>
      '0x5FC8d32690cc91D4c39d9d3abcBD16989F875707';

  @override
  String get rifRelayDeployVerifier =>
      '0xDc64a140Aa3E981100a9becA4E685f962f0cF6C9';

  @override
  String get rifRelayUrl => 'http://localhost:8090';

  @override
  String get rifSmartWalletFactoryAddress =>
      '0x9A9f2CCfdE556A7E9Ff0848998Aa4a0CFD8863AE';
}
