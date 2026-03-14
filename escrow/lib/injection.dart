import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

final getIt = GetIt.instance;

String _readRequiredEnv(String key) {
  final value = Platform.environment[key]?.trim();
  if (value == null || value.isEmpty) {
    throw StateError('Missing required environment variable: $key');
  }
  return value;
}

Map<String, String> _parseOtlpHeaders(String? raw) {
  if (raw == null || raw.trim().isEmpty) return const {};

  final headers = <String, String>{};
  for (final part in raw.split(',')) {
    final entry = part.trim();
    if (entry.isEmpty) continue;

    final separator = entry.indexOf('=');
    if (separator <= 0) continue;

    final key = Uri.decodeQueryComponent(entry.substring(0, separator).trim());
    final value =
        Uri.decodeQueryComponent(entry.substring(separator + 1).trim());
    if (key.isEmpty || value.isEmpty) continue;

    headers[key] = value;
  }

  return headers;
}

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
        telemetry: Telemetry(
          serviceName: 'hostr-escrow',
          enableExport:
              (Platform.environment['OTEL_EXPORTER_OTLP_ENDPOINT'] ?? '')
                  .trim()
                  .isNotEmpty,
          otlpEndpoint: Platform.environment['OTEL_EXPORTER_OTLP_ENDPOINT'],
          otlpHeaders: _parseOtlpHeaders(
            Platform.environment['OTEL_EXPORTER_OTLP_HEADERS'],
          ),
        ),
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

  @override
  RifRelayConfig get rifRelay => _EscrowRifRelayConfig();

  @override
  RootstockSupportedContractsConfig get supportedContracts =>
      DefaultRootstockSupportedContractsConfig(
        multiEscrow: DefaultSupportedEscrowContractConfig(
          rifRelay: _EscrowRifRelayConfig(),
        ),
      );
}

class _EscrowBoltzConfig extends BoltzConfig {
  @override
  String get apiUrl => 'https://boltz.hostr.development/v2';
}

class _EscrowRifRelayConfig extends RifRelayConfig {
  @override
  String get callVerifier =>
      _readRequiredEnv('RIF_RELAY_RELAY_VERIFIER_ADDRESS');

  @override
  String get deployVerifier =>
      _readRequiredEnv('RIF_RELAY_DEPLOY_VERIFIER_ADDRESS');

  @override
  String get url => _readRequiredEnv('RIF_RELAY_URL');

  @override
  String get smartWalletFactoryAddress =>
      _readRequiredEnv('RIF_RELAY_SMARTWALLET_FACTORY_ADDRESS');
}
