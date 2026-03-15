import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hostr/data/sources/calendar/eventide_calendar_port.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:sqlite3/common.dart';

abstract class Config {
  List<String> get relays => [];
  String get hostrBlossom;
  String get hostrRelay;
  RootstockConfig get rootstock;
  List<String> get bootstrapEscrowPubkeys => [];
  bool get useSecureKeyValueStorage => true;
  String get googleMapsApiKey;
  int get defaultZap => 1000;
  int get defaultBudgetMonthly => 1 * pow(10, 6).toInt();

  Telemetry? buildTelemetry() => null;

  HostrConfig buildHostrConfig({
    CustomLogger? logger,
    CommonDatabase? operationsDb,
    ShowNotification? showNotification,
    ConfigureCryptography? configureCryptography,
  }) {
    final log = logger ?? CustomLogger();

    return HostrConfig(
      operationsDb: operationsDb,
      bootstrapRelays: [
        ...relays,
        hostrRelay,
      ].where((r) => r.isNotEmpty).toList(),
      bootstrapBlossom: [hostrBlossom].where((b) => b.isNotEmpty).toList(),
      bootstrapEscrowPubkeys: bootstrapEscrowPubkeys,
      hostrRelay: hostrRelay,
      rootstockConfig: rootstock,
      storage: useSecureKeyValueStorage
          ? SecureKeyValueStorage()
          : InMemoryKeyValueStorage(),
      logs: log,
      telemetry: buildTelemetry(),
      calendarPort: EventideCalendarPort(logger: log),
      showNotification: showNotification,
      configureCryptography: configureCryptography,
    );
  }
}

String requiredBuildConfig(String key, String value) {
  if (value.trim().isEmpty) {
    throw StateError('Missing required build config: $key');
  }
  return value;
}

List<String> buildConfigList(String key, String value) {
  return value
      .split(',')
      .map((entry) => entry.trim())
      .where((entry) => entry.isNotEmpty)
      .toList(growable: false);
}

class EnvBackedRifRelayConfig extends RifRelayConfig {
  @override
  String get url => requiredBuildConfig(
    'RIF_RELAY_URL',
    const String.fromEnvironment('RIF_RELAY_URL'),
  );

  @override
  String get callVerifier => requiredBuildConfig(
    'RIF_RELAY_RELAY_VERIFIER_ADDRESS',
    const String.fromEnvironment('RIF_RELAY_RELAY_VERIFIER_ADDRESS'),
  );

  @override
  String get deployVerifier => requiredBuildConfig(
    'RIF_RELAY_DEPLOY_VERIFIER_ADDRESS',
    const String.fromEnvironment('RIF_RELAY_DEPLOY_VERIFIER_ADDRESS'),
  );

  @override
  String get smartWalletFactoryAddress => requiredBuildConfig(
    'RIF_RELAY_SMARTWALLET_FACTORY_ADDRESS',
    const String.fromEnvironment('RIF_RELAY_SMARTWALLET_FACTORY_ADDRESS'),
  );
}

class InMemoryKeyValueStorage implements KeyValueStorage {
  final Map<String, dynamic> _state = {};

  @override
  Future<void> write(String key, dynamic value) async {
    _state[key] = value;
  }

  @override
  Future<dynamic> read(String key) async {
    return _state[key];
  }

  @override
  Future<void> delete(String key) async {
    _state.remove(key);
  }
}

class SecureKeyValueStorage implements KeyValueStorage {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  @override
  Future<void> write(String key, dynamic value) async {
    // Delete first to avoid Keychain errSecDuplicateItem (-25299)
    // when concurrent isolates write the same key simultaneously.
    await _storage.delete(key: key);
    await _storage.write(key: key, value: value);
  }

  @override
  Future<dynamic> read(String key) async {
    return await _storage.read(key: key);
  }

  @override
  Future<void> delete(String key) async {
    await _storage.delete(key: key);
  }
}
