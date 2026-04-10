@Tags(['unit'])
library;

import 'package:hostr_sdk/datasources/app_database.dart';
import 'package:hostr_sdk/mocks/usecase_mocks.mocks.dart';
import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/user_config/hostr_user_config.dart';
import 'package:hostr_sdk/usecase/user_config/user_config_store.dart';
import 'package:hostr_sdk/util/custom_logger.dart';
import 'package:mockito/mockito.dart';
import 'package:models/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart' as native_sqlite3;
import 'package:test/test.dart';

void main() {
  group('HostrUserConfig', () {
    group('defaults', () {
      test('has sensible default values', () {
        const config = HostrUserConfig();
        expect(config.mode, AppMode.guest);
        expect(config.autoWithdrawEnabled, isTrue);
      });

      test('convenience getters work', () {
        const config = HostrUserConfig();
        expect(config.isGuest, isTrue);
        expect(config.isHost, isFalse);
      });
    });

    group('copyWith', () {
      test('changes only specified fields', () {
        const original = HostrUserConfig();
        final updated = original.copyWith(mode: AppMode.host);

        expect(updated.mode, AppMode.host);
        expect(updated.isHost, isTrue);
        // Everything else stays the same
        expect(updated.autoWithdrawEnabled, original.autoWithdrawEnabled);
      });

      test('can update multiple fields at once', () {
        const original = HostrUserConfig();
        final updated = original.copyWith(
          mode: AppMode.host,
          autoWithdrawEnabled: false,
        );

        expect(updated.mode, AppMode.host);
        expect(updated.autoWithdrawEnabled, isFalse);
      });
    });

    group('serialisation', () {
      test('toJson / fromJson roundtrip preserves all fields', () {
        const config = HostrUserConfig(
          mode: AppMode.host,
          autoWithdrawEnabled: false,
        );

        final json = config.toJson();
        final restored = HostrUserConfig.fromJson(json);

        expect(restored, equals(config));
        expect(restored.mode, AppMode.host);
        expect(restored.autoWithdrawEnabled, isFalse);
      });

      test('fromJson uses defaults for missing fields', () {
        final config = HostrUserConfig.fromJson({});
        expect(config.mode, AppMode.guest);
        expect(config.autoWithdrawEnabled, isTrue);
      });

      test('fromJson handles mode string correctly', () {
        final host = HostrUserConfig.fromJson({'mode': 'host'});
        expect(host.mode, AppMode.host);

        final guest = HostrUserConfig.fromJson({'mode': 'guest'});
        expect(guest.mode, AppMode.guest);

        final unknown = HostrUserConfig.fromJson({'mode': 'something_else'});
        expect(unknown.mode, AppMode.guest);
      });

      test('toJson serialises mode as string', () {
        const config = HostrUserConfig(mode: AppMode.host);
        expect(config.toJson()['mode'], 'host');
      });
    });

    group('AppMode', () {
      test('fromString parses known values', () {
        expect(AppMode.fromString('host'), AppMode.host);
        expect(AppMode.fromString('guest'), AppMode.guest);
      });

      test('fromString defaults to guest for unknown/null', () {
        expect(AppMode.fromString(null), AppMode.guest);
        expect(AppMode.fromString('unknown'), AppMode.guest);
        expect(AppMode.fromString(''), AppMode.guest);
      });
    });

    group('equatable', () {
      test('equal configs are equal', () {
        const a = HostrUserConfig(mode: AppMode.host);
        const b = HostrUserConfig(mode: AppMode.host);
        expect(a, equals(b));
      });

      test('different configs are not equal', () {
        const a = HostrUserConfig(mode: AppMode.host);
        const b = HostrUserConfig(mode: AppMode.guest);
        expect(a, isNot(equals(b)));
      });
    });
  });

  group('UserConfigStore', () {
    late CommonDatabase db;
    late Auth auth;
    late KeyPair? activeKeyPair;
    late UserConfigStore store;

    final userA = Bip340.fromPrivateKey('1' * 64);
    final userB = Bip340.fromPrivateKey('2' * 64);

    setUp(() {
      db = AppDatabase(native_sqlite3.sqlite3.openInMemory()).db;
      activeKeyPair = userA;
      final mockAuth = MockAuth();
      when(mockAuth.activeKeyPair).thenAnswer((_) => activeKeyPair);
      auth = mockAuth;
      store = UserConfigStore(db, CustomLogger(), auth);
    });

    tearDown(() {
      store.dispose();
    });

    group('initialize', () {
      test('loads defaults when storage is empty', () async {
        await store.initialize();
        final config = await store.state;
        expect(config, equals(HostrUserConfig.defaults));
      });

      test('loads config from storage', () async {
        db.execute('INSERT INTO config (pubkey, key, value) VALUES (?, ?, ?)', [
          userA.publicKey,
          'mode',
          'host',
        ]);

        await store.initialize();
        final config = await store.state;
        expect(config.mode, AppMode.host);
      });

      test('is idempotent — second call does not reload', () async {
        await store.initialize();
        await store.update(const HostrUserConfig(mode: AppMode.host));

        // Write something different directly to the DB.
        db.execute(
          'INSERT OR REPLACE INTO config (pubkey, key, value) VALUES (?, ?, ?)',
          [userA.publicKey, 'mode', 'guest'],
        );

        // Second initialize should be a no-op
        await store.initialize();
        final config = await store.state;
        expect(config.mode, AppMode.host);
      });

      test('handles corrupt storage gracefully', () async {
        db.execute('INSERT INTO config (pubkey, key, value) VALUES (?, ?, ?)', [
          userA.publicKey,
          'auto_withdraw_enabled',
          'not-a-bool',
        ]);
        await store.initialize();
        final config = await store.state;
        expect(config.mode, AppMode.guest);
        expect(config.autoWithdrawEnabled, isTrue);
      });
    });

    group('update', () {
      test('persists config and flushes to storage', () async {
        const updated = HostrUserConfig(
          mode: AppMode.host,
          autoWithdrawEnabled: false,
        );
        await store.update(updated);

        final config = await store.state;
        expect(config.mode, AppMode.host);
        expect(config.autoWithdrawEnabled, isFalse);

        // Verify it's in underlying storage
        final rows = db.select(
          'SELECT key, value FROM config WHERE pubkey = ? ORDER BY key',
          [userA.publicKey],
        );
        expect(rows, hasLength(2));
        final decoded = {
          for (final row in rows) row['key'] as String: row['value'] as String,
        };
        expect(decoded['mode'], 'host');
        expect(decoded['auto_withdraw_enabled'], 'false');
      });
    });

    group('stream', () {
      test('emits defaults initially and updates on change', () async {
        final emissions = <HostrUserConfig>[];
        final sub = store.stream.listen(emissions.add);

        // Let the initial seeded value propagate
        await Future<void>.delayed(Duration.zero);

        await store.update(const HostrUserConfig(mode: AppMode.host));

        await Future<void>.delayed(Duration.zero);

        await sub.cancel();

        expect(emissions.length, greaterThanOrEqualTo(2));
        expect(emissions.first.mode, AppMode.guest); // default
        expect(emissions.last.mode, AppMode.host);
      });
    });

    group('reset', () {
      test('resets to defaults and clears storage', () async {
        await store.update(
          const HostrUserConfig(mode: AppMode.host, autoWithdrawEnabled: false),
        );

        await store.reset();

        final config = await store.state;
        expect(config, equals(HostrUserConfig.defaults));
        expect(config.mode, AppMode.guest);
        expect(config.autoWithdrawEnabled, isTrue);
      });
    });

    group('persistence roundtrip', () {
      test('config survives store recreation', () async {
        await store.update(
          const HostrUserConfig(mode: AppMode.host, autoWithdrawEnabled: false),
        );

        // Create a new store pointing at the same storage
        final store2 = UserConfigStore(db, CustomLogger(), auth);
        await store2.initialize();

        final config = await store2.state;
        expect(config.mode, AppMode.host);
        expect(config.autoWithdrawEnabled, isFalse);

        store2.dispose();
      });

      test(
        'keeps config isolated per pubkey and survives auth changes',
        () async {
          await store.update(const HostrUserConfig(mode: AppMode.host));

          activeKeyPair = userB;
          await store.initialize();
          final userBConfig = await store.state;
          expect(userBConfig, equals(HostrUserConfig.defaults));

          await store.update(
            const HostrUserConfig(
              mode: AppMode.guest,
              autoWithdrawEnabled: false,
            ),
          );

          final rawA = db.select(
            'SELECT value FROM config WHERE pubkey = ? AND key = ?',
            [userA.publicKey, 'mode'],
          );
          final rawB = db.select(
            'SELECT value FROM config WHERE pubkey = ? AND key = ?',
            [userB.publicKey, 'mode'],
          );
          expect(rawA, isNotNull);
          expect(rawB, isNotNull);

          activeKeyPair = userA;
          await store.initialize();
          final userAConfig = await store.state;
          expect(userAConfig.mode, AppMode.host);
        },
      );
    });
  });
}
