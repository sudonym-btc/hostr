import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hostr/data/sources/calendar/eventide_calendar_port.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

abstract class Config {
  List<String> get relays => [];
  String get hostrBlossom;
  String get hostrRelay;
  EvmConfig get evmConfig;
  List<String> get bootstrapEscrowPubkeys => [];
  bool get useSecureKeyValueStorage => true;
  String get googleMapsApiKey;
  String get googleMapsWebMapId => '';
  String get googleMapsAndroidMapId => '';
  String get googleMapsIosMapId => '';
  String get tipsAddress => 'tips@lnbits.hostr.development';
  String get hostrSocialNpub => '';
  String get hostrTwitterHandle => 'hostr_network';
  int get defaultZap => 1000;
  int get defaultBudgetMonthly => 1 * pow(10, 6).toInt();

  String googleMapsMapIdForPlatform({
    required bool isWeb,
    required TargetPlatform platform,
  }) {
    if (isWeb) return googleMapsWebMapId;
    return switch (platform) {
      TargetPlatform.android => googleMapsAndroidMapId,
      TargetPlatform.iOS => googleMapsIosMapId,
      _ => '',
    };
  }

  Telemetry? buildTelemetry() => null;

  HostrConfig buildHostrConfig({
    CustomLogger? logger,
    AppDatabase? appDatabase,
    ShowNotification? showNotification,
  }) {
    final log = logger ?? CustomLogger();

    return HostrConfig(
      appDatabase: appDatabase,
      bootstrapRelays: [
        hostrRelay,
        ...relays,
      ].where((r) => r.isNotEmpty).toList(),
      bootstrapBlossom: [hostrBlossom].where((b) => b.isNotEmpty).toList(),
      bootstrapEscrowPubkeys: bootstrapEscrowPubkeys,
      hostrRelay: hostrRelay,
      evmConfig: evmConfig,
      storage: useSecureKeyValueStorage
          ? SecureKeyValueStorage()
          : InMemoryKeyValueStorage(),
      logs: log,
      telemetry: buildTelemetry(),
      calendarPort: EventideCalendarPort(logger: log),
      showNotification: showNotification,
    );
  }
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
