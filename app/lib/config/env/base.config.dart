import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

abstract class Config {
  List<String> get relays => [];
  String get hostrBlossom;
  String get hostrRelay;
  RootstockConfig get rootstock;
  String get googleMapsApiKey => 'AIzaSyBjcePUwkKwD-iMmHpjXVDV0MaiYH1dnGo';
  int get defaultZap => 1000;
  int get defaultBudgetMonthly => 1 * pow(10, 6).toInt();

  HostrConfig get hostrConfig => HostrConfig(
    bootstrapRelays: [...relays, hostrRelay],
    bootstrapBlossom: [hostrBlossom],
    rootstockConfig: rootstock,
    storage: SecureKeyValueStorage(),
    logs: CustomLogger(),
  );
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
