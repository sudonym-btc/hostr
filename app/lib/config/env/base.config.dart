import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

abstract class Config {
  List<String> get relays => [];
  String get hostrBlossom;
  String get hostrRelay;
  RootstockConfig get rootstock;
  bool get useSecureKeyValueStorage => true;
  String get googleMapsApiKey => 'AIzaSyBjcePUwkKwD-iMmHpjXVDV0MaiYH1dnGo';
  int get defaultZap => 1000;
  int get defaultBudgetMonthly => 1 * pow(10, 6).toInt();

  HostrConfig get hostrConfig => HostrConfig(
    bootstrapRelays: [...relays, hostrRelay],
    bootstrapBlossom: [hostrBlossom],
    rootstockConfig: rootstock,
    storage: useSecureKeyValueStorage
        ? SecureKeyValueStorage()
        : InMemoryKeyValueStorage(),
    logs: CustomLogger(),
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
