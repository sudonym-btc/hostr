import 'package:hostr_sdk/config.dart';
import 'package:hostr_sdk/config/generated/test_env.g.dart' as env;
import 'package:hostr_sdk/datasources/app_database.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:test/test.dart';

void main() {
  HostrConfig buildConfig({
    required String hostrRelay,
    required List<String> bootstrapRelays,
  }) {
    final appDatabase = AppDatabase(sqlite3.sqlite3.openInMemory());
    addTearDown(appDatabase.db.close);

    return HostrConfig(
      appDatabase: appDatabase,
      bootstrapRelays: bootstrapRelays,
      bootstrapBlossom: const [],
      hostrRelay: hostrRelay,
      evmConfig: env.evmConfig,
    );
  }

  test('default NDK config eagerly bootstraps only the Hostr relay', () {
    final config = buildConfig(
      hostrRelay: 'wss://relay.hostr.network',
      bootstrapRelays: const [
        'wss://relay.hostr.network',
        'wss://relay.damus.io',
        'wss://relay.nostr.band',
      ],
    );

    expect(config.bootstrapRelays, hasLength(3));
    expect(config.ndkConfig.bootstrapRelays, ['wss://relay.hostr.network']);
    expect(config.ndkConfig.ignoreRelays, ['wss://relay.hostr.development']);
  });

  test('default NDK config falls back when no Hostr relay is configured', () {
    final config = buildConfig(
      hostrRelay: '',
      bootstrapRelays: const [
        'wss://relay.damus.io',
        'wss://relay.damus.io',
        'wss://relay.nostr.band',
      ],
    );

    expect(config.ndkConfig.bootstrapRelays, [
      'wss://relay.damus.io',
      'wss://relay.nostr.band',
    ]);
    expect(config.ndkConfig.ignoreRelays, ['wss://relay.hostr.development']);
  });

  test('default NDK config allows the development relay in development', () {
    final config = buildConfig(
      hostrRelay: 'wss://relay.hostr.development',
      bootstrapRelays: const ['wss://relay.hostr.development'],
    );

    expect(config.ndkConfig.bootstrapRelays, ['wss://relay.hostr.development']);
    expect(config.ndkConfig.ignoreRelays, isEmpty);
  });
}
