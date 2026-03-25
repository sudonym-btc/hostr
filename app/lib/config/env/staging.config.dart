import 'package:hostr/injection.dart';
import 'package:hostr_sdk/config/generated/staging_env.g.dart' as env;
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:injectable/injectable.dart';

import 'base.config.dart';

@Injectable(as: Config, env: [Env.staging])
class StagingConfig extends Config {
  @override
  List<String> get bootstrapEscrowPubkeys => env.bootstrapEscrowPubkeys;

  @override
  Telemetry buildTelemetry() => Telemetry(
    serviceName: env.telemetryServiceName,
    enableExport: env.telemetryEnabled,
    otlpEndpoint: env.telemetryEndpoint.isNotEmpty
        ? env.telemetryEndpoint
        : null,
  );

  @override
  List<String> relays = env.bootstrapRelays;
  @override
  String get hostrBlossom => env.blossomUrl;
  @override
  String get hostrRelay => env.relayUrl;
  @override
  EvmConfig evmConfig = env.evmConfig;
  @override
  String get tipsAddress => env.tipsAddress;
  @override
  String get googleMapsApiKey => env.googleMapsApiKey;
}
