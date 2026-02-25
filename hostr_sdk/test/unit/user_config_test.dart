import 'dart:convert';

import 'package:hostr_sdk/datasources/storage.dart';
import 'package:hostr_sdk/usecase/user_config/hostr_user_config.dart';
import 'package:hostr_sdk/usecase/user_config/user_config_store.dart';
import 'package:hostr_sdk/util/custom_logger.dart';
import 'package:test/test.dart';

void main() {
  group('HostrUserConfig', () {
    group('defaults', () {
      test('has sensible default values', () {
        const config = HostrUserConfig();
        expect(config.mode, AppMode.guest);
        expect(config.autoWithdrawEnabled, isTrue);
        expect(config.autoWithdrawMinimumSats, 10000);
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
        expect(
          updated.autoWithdrawMinimumSats,
          original.autoWithdrawMinimumSats,
        );
      });

      test('can update multiple fields at once', () {
        const original = HostrUserConfig();
        final updated = original.copyWith(
          mode: AppMode.host,
          autoWithdrawEnabled: false,
          autoWithdrawMinimumSats: 50000,
        );

        expect(updated.mode, AppMode.host);
        expect(updated.autoWithdrawEnabled, isFalse);
        expect(updated.autoWithdrawMinimumSats, 50000);
      });
    });

    group('serialisation', () {
      test('toJson / fromJson roundtrip preserves all fields', () {
        const config = HostrUserConfig(
          mode: AppMode.host,
          autoWithdrawEnabled: false,
          autoWithdrawMinimumSats: 25000,
        );

        final json = config.toJson();
        final restored = HostrUserConfig.fromJson(json);

        expect(restored, equals(config));
        expect(restored.mode, AppMode.host);
        expect(restored.autoWithdrawEnabled, isFalse);
        expect(restored.autoWithdrawMinimumSats, 25000);
      });

      test('fromJson uses defaults for missing fields', () {
        final config = HostrUserConfig.fromJson({});
        expect(config.mode, AppMode.guest);
        expect(config.autoWithdrawEnabled, isTrue);
        expect(config.autoWithdrawMinimumSats, 10000);
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
    late InMemoryKeyValueStorage storage;
    late UserConfigStore store;

    setUp(() {
      storage = InMemoryKeyValueStorage();
      store = UserConfigStore(storage, CustomLogger());
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
        final saved = const HostrUserConfig(mode: AppMode.host).toJson();
        await storage.write('hostr_user_config', jsonEncode(saved));

        await store.initialize();
        final config = await store.state;
        expect(config.mode, AppMode.host);
      });

      test('is idempotent — second call does not reload', () async {
        await store.initialize();
        await store.update(const HostrUserConfig(mode: AppMode.host));

        // Write something different directly to storage
        final other = const HostrUserConfig(mode: AppMode.guest).toJson();
        await storage.write('hostr_user_config', jsonEncode(other));

        // Second initialize should be a no-op
        await store.initialize();
        final config = await store.state;
        expect(config.mode, AppMode.host);
      });

      test('handles corrupt storage gracefully', () async {
        await storage.write('hostr_user_config', 'not valid json}}}');
        await store.initialize();
        final config = await store.state;
        expect(config, equals(HostrUserConfig.defaults));
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
        final raw = await storage.read('hostr_user_config');
        expect(raw, isNotNull);
        final decoded = jsonDecode(raw as String) as Map<String, dynamic>;
        expect(decoded['mode'], 'host');
        expect(decoded['autoWithdrawEnabled'], isFalse);
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
          const HostrUserConfig(
            mode: AppMode.host,
            autoWithdrawEnabled: false,
            autoWithdrawMinimumSats: 50000,
          ),
        );

        // Create a new store pointing at the same storage
        final store2 = UserConfigStore(storage, CustomLogger());
        await store2.initialize();

        final config = await store2.state;
        expect(config.mode, AppMode.host);
        expect(config.autoWithdrawEnabled, isFalse);
        expect(config.autoWithdrawMinimumSats, 50000);

        store2.dispose();
      });
    });
  });
}
