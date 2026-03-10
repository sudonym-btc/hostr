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

  HostrConfig buildHostrConfig({
    CustomLogger? logger,
    CommonDatabase? operationsDb,
    ShowNotification? showNotification,
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
