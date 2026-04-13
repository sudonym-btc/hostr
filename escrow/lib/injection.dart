import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';

import 'env_config.dart';

final getIt = GetIt.instance;

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
  String environment = 'dev',
  CustomLogger? logger,
}) async {
  await _ensureHydratedStorage();

  final env = EnvConfig.forEnvironment(environment);

  if (getIt.isRegistered<Hostr>()) {
    await getIt.unregister<Hostr>(
        disposingFunction: (hostr) => hostr.dispose());
  }

  getIt.registerSingleton<Hostr>(
    Hostr(
      environment: environment,
      config: HostrConfig(
        logs: logger ?? CustomLogger(),
        bootstrapRelays: [env.relayUrl],
        bootstrapBlossom: [env.blossomUrl],
        hostrRelay: env.relayUrl,
        evmConfig: env.evmConfig,
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
