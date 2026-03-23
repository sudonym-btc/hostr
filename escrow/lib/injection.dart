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

/// Reads token contract addresses from runtime environment variables.
Map<String, TokenConfig> _envTokens() {
  final tbtcAddr = Platform.environment['ARBITRUM_TBTC_ADDRESS']?.trim();
  final tbtcDec = Platform.environment['ARBITRUM_TBTC_DECIMALS']?.trim();
  final usdtAddr = Platform.environment['ARBITRUM_USDT_ADDRESS']?.trim();
  final usdtDec = Platform.environment['ARBITRUM_USDT_DECIMALS']?.trim();

  return {
    if (tbtcAddr != null && tbtcAddr.isNotEmpty)
      'tBTC': TokenConfig(
        address: tbtcAddr,
        decimals: int.tryParse(tbtcDec ?? '') ?? 18,
      ),
    if (usdtAddr != null && usdtAddr.isNotEmpty)
      'USDT': TokenConfig(
        address: usdtAddr,
        decimals: int.tryParse(usdtDec ?? '') ?? 6,
      ),
  };
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
        evmConfig: EvmConfig(
          boltz: BoltzConfig(apiUrl: 'https://boltz.hostr.development/v2'),
          chains: [
            EvmChainConfig(
              id: 'arbitrum-regtest',
              chainId: 412346,
              rpcUrl: rpcUrl,
              accountAbstraction: AAConfig(
                bundlerUrl: Platform.environment['AA_BUNDLER_URL']?.trim() ??
                    'http://bundler:3000/rpc',
                entryPointAddress: _readRequiredEnv('AA_ENTRY_POINT_ADDRESS'),
                accountFactoryAddress:
                    _readRequiredEnv('AA_ACCOUNT_FACTORY_ADDRESS'),
                paymasterAddress: _readRequiredEnv('AA_PAYMASTER_ADDRESS'),
              ),
              tokens: _envTokens(),
            ),
          ],
        ),
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
