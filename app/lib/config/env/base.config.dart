import 'dart:math';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hostr/data/sources/calendar/eventide_calendar_port.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:sqlite3/common.dart';

abstract class Config {
  List<String> get relays => [];
  String get hostrBlossom;
  String get hostrRelay;
  EvmConfig get evmConfig;
  List<String> get bootstrapEscrowPubkeys => [];
  bool get useSecureKeyValueStorage => true;
  String get googleMapsApiKey;
  String get tipsAddress => 'tips@lnbits.hostr.development';
  int get defaultZap => 1000;
  int get defaultBudgetMonthly => 1 * pow(10, 6).toInt();

  Telemetry? buildTelemetry() => null;

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

/// Reads ERC-4337 AA config from compile-time env vars.
AAConfig envBackedAAConfig() => AAConfig(
  bundlerUrl: requiredBuildConfig(
    'AA_BUNDLER_URL',
    const String.fromEnvironment('AA_BUNDLER_URL'),
  ),
  entryPointAddress: requiredBuildConfig(
    'AA_ENTRY_POINT_ADDRESS',
    const String.fromEnvironment('AA_ENTRY_POINT_ADDRESS'),
  ),
  accountFactoryAddress: requiredBuildConfig(
    'AA_ACCOUNT_FACTORY_ADDRESS',
    const String.fromEnvironment('AA_ACCOUNT_FACTORY_ADDRESS'),
  ),
  paymasterAddress: requiredBuildConfig(
    'AA_PAYMASTER_ADDRESS',
    const String.fromEnvironment('AA_PAYMASTER_ADDRESS'),
  ),
);

/// Reads token contract addresses from compile-time env vars.
///
/// Used by local/test environments where mock tokens are deployed dynamically.
/// Production/staging environments hardcode the real Arbitrum addresses instead.
Map<String, TokenConfig> envBackedTokens() {
  final tbtcAddr = const String.fromEnvironment('ARBITRUM_TBTC_ADDRESS');
  final tbtcDec = const String.fromEnvironment('ARBITRUM_TBTC_DECIMALS');
  final usdtAddr = const String.fromEnvironment('ARBITRUM_USDT_ADDRESS');
  final usdtDec = const String.fromEnvironment('ARBITRUM_USDT_DECIMALS');

  return {
    if (tbtcAddr.isNotEmpty)
      'tBTC': TokenConfig(
        address: tbtcAddr,
        decimals: int.tryParse(tbtcDec) ?? 18,
      ),
    if (usdtAddr.isNotEmpty)
      'USDT': TokenConfig(
        address: usdtAddr,
        decimals: int.tryParse(usdtDec) ?? 6,
      ),
  };
}

/// Well-known ERC-20 tokens on Arbitrum One (mainnet).
const arbitrumMainnetTokens = {
  'USDT': TokenConfig(
    address: '0xFd086bC7CD5C481DCC9C85ebE478A1C0b69FCbb9',
    decimals: 6,
  ),
  'tBTC': TokenConfig(
    address: '0x6c84a8f1c29108F47a79964b5Fe888D4f4D0cD8D',
    decimals: 18,
  ),
};

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
