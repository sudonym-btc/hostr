@Tags(['unit'])
library;

import 'dart:convert';

import 'package:hostr_sdk/datasources/storage.dart';
import 'package:hostr_sdk/mocks/usecase_mocks.mocks.dart';
import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/evm/operations/operation_state_store.dart';
import 'package:hostr_sdk/util/custom_logger.dart';
import 'package:mockito/mockito.dart';
import 'package:models/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

void main() {
  late InMemoryKeyValueStorage storage;
  late Auth auth;
  late KeyPair? activeKeyPair;
  late OperationStateStore store;

  final userA = Bip340.fromPrivateKey('1' * 64);
  final userB = Bip340.fromPrivateKey('2' * 64);

  String keyFor(String pubkey, String ns) => 'ops:$pubkey:$ns';

  Map<String, dynamic> _entry({
    required String id,
    bool isTerminal = false,
    String? updatedAt,
  }) => {'id': id, 'isTerminal': isTerminal, 'updatedAt': ?updatedAt};

  setUp(() {
    storage = InMemoryKeyValueStorage();
    activeKeyPair = userA;
    final mockAuth = MockAuth();
    when(mockAuth.activeKeyPair).thenAnswer((_) => activeKeyPair);
    auth = mockAuth;
    store = OperationStateStore(storage, CustomLogger(), auth);
  });

  tearDown(() {
    store.dispose();
  });

  group('OperationStateStore', () {
    group('initialize', () {
      test('loads empty store when storage has nothing', () async {
        await store.initialize('swap_in');
        final all = await store.readAll('swap_in');
        expect(all, isEmpty);
      });

      test('loads entries from storage', () async {
        final entry = _entry(id: 'preloaded');
        await storage.write(
          keyFor(userA.publicKey, 'swap_in'),
          jsonEncode([entry]),
        );

        await store.initialize('swap_in');
        final all = await store.readAll('swap_in');
        expect(all, hasLength(1));
        expect(all.first['id'], 'preloaded');
      });

      test('is idempotent — second call does not reload', () async {
        await store.initialize('swap_in');
        await store.write('swap_in', 'first', _entry(id: 'first'));

        // Write something different directly to storage
        await storage.write(
          keyFor(userA.publicKey, 'swap_in'),
          jsonEncode([_entry(id: 'other')]),
        );

        // Second initialize should be a no-op (cache already loaded)
        await store.initialize('swap_in');
        final all = await store.readAll('swap_in');
        expect(all, hasLength(1));
        expect(all.first['id'], 'first');
      });

      test('handles corrupt storage gracefully', () async {
        await storage.write(
          keyFor(userA.publicKey, 'swap_in'),
          'not valid json}}}',
        );
        await store.initialize('swap_in');
        final all = await store.readAll('swap_in');
        expect(all, isEmpty);
      });
    });

    group('write / read', () {
      test('persists an entry and flushes to storage', () async {
        final entry = _entry(id: 'item-1');
        await store.write('swap_in', 'item-1', entry);

        // Verify it's retrievable
        final retrieved = await store.read('swap_in', 'item-1');
        expect(retrieved, isNotNull);
        expect(retrieved!['id'], 'item-1');

        // Verify it's in underlying storage
        final raw = await storage.read(keyFor(userA.publicKey, 'swap_in'));
        final list = jsonDecode(raw) as List;
        expect(list, hasLength(1));
      });

      test('overwrites existing entry with same id', () async {
        await store.write('swap_in', 'x', {'id': 'x', 'v': 1});
        await store.write('swap_in', 'x', {'id': 'x', 'v': 2});

        final all = await store.readAll('swap_in');
        expect(all, hasLength(1));
        expect(all.first['v'], 2);
      });
    });

    group('remove', () {
      test('removes an entry by id', () async {
        await store.write('swap_in', 'to-remove', _entry(id: 'to-remove'));
        await store.write('swap_in', 'to-keep', _entry(id: 'to-keep'));

        await store.remove('swap_in', 'to-remove');

        final all = await store.readAll('swap_in');
        expect(all, hasLength(1));
        expect(all.first['id'], 'to-keep');
      });
    });

    group('hasNonTerminal', () {
      test('returns true when non-terminal entries exist', () async {
        await store.write(
          'escrow_fund',
          'active',
          _entry(id: 'active', isTerminal: false),
        );
        expect(await store.hasNonTerminal('escrow_fund'), isTrue);
      });

      test('returns false when all entries are terminal', () async {
        await store.write(
          'escrow_fund',
          'done',
          _entry(id: 'done', isTerminal: true),
        );
        expect(await store.hasNonTerminal('escrow_fund'), isFalse);
      });

      test('returns false for empty namespace', () async {
        expect(await store.hasNonTerminal('escrow_fund'), isFalse);
      });
    });

    group('pruneTerminal', () {
      test('removes only terminal entries older than cutoff', () async {
        final oldDate = DateTime(2025, 1, 1).toIso8601String();
        final recentDate = DateTime.now().toIso8601String();

        await store.write(
          'swap_in',
          'old-done',
          _entry(id: 'old-done', isTerminal: true, updatedAt: oldDate),
        );
        await store.write(
          'swap_in',
          'recent-done',
          _entry(id: 'recent-done', isTerminal: true, updatedAt: recentDate),
        );
        await store.write(
          'swap_in',
          'old-active',
          _entry(id: 'old-active', isTerminal: false, updatedAt: oldDate),
        );

        final pruned = await store.pruneTerminal(
          'swap_in',
          const Duration(days: 30),
        );
        expect(pruned, 1);

        final all = await store.readAll('swap_in');
        expect(all, hasLength(2));
        final ids = all.map((e) => e['id']).toSet();
        expect(ids, containsAll(['recent-done', 'old-active']));
      });

      test('returns 0 when nothing to prune', () async {
        await store.write('swap_in', 'fresh', _entry(id: 'fresh'));
        final pruned = await store.pruneTerminal(
          'swap_in',
          const Duration(days: 30),
        );
        expect(pruned, 0);
      });
    });

    group('namespace isolation', () {
      test('different namespaces are independent', () async {
        await store.write('swap_in', 'a', _entry(id: 'a'));
        await store.write('swap_out', 'b', _entry(id: 'b'));

        final swapInAll = await store.readAll('swap_in');
        final swapOutAll = await store.readAll('swap_out');
        expect(swapInAll, hasLength(1));
        expect(swapOutAll, hasLength(1));
        expect(swapInAll.first['id'], 'a');
        expect(swapOutAll.first['id'], 'b');
      });
    });

    group('persistence roundtrip', () {
      test('entries survive store recreation', () async {
        await store.write('swap_in', 'persist-1', _entry(id: 'persist-1'));
        await store.write('swap_out', 'persist-2', _entry(id: 'persist-2'));
        store.dispose();

        // Create a new store instance pointing at the same storage
        final store2 = OperationStateStore(storage, CustomLogger(), auth);
        final swapIn = await store2.readAll('swap_in');
        final swapOut = await store2.readAll('swap_out');
        expect(swapIn, hasLength(1));
        expect(swapOut, hasLength(1));
        store2.dispose();
      });

      test('keeps data isolated per pubkey', () async {
        await store.write('swap_in', 'user-a', _entry(id: 'user-a'));

        // Switch user
        activeKeyPair = userB;
        // Force reload by creating new store
        store.dispose();
        store = OperationStateStore(storage, CustomLogger(), auth);
        final allB = await store.readAll('swap_in');
        expect(allB, isEmpty);

        await store.write('swap_in', 'user-b', _entry(id: 'user-b'));

        // Verify storage has both
        final rawA = await storage.read(keyFor(userA.publicKey, 'swap_in'));
        final rawB = await storage.read(keyFor(userB.publicKey, 'swap_in'));
        expect(rawA, isNotNull);
        expect(rawB, isNotNull);

        // Switch back to user A
        activeKeyPair = userA;
        store.dispose();
        store = OperationStateStore(storage, CustomLogger(), auth);
        final allA = await store.readAll('swap_in');
        expect(allA, hasLength(1));
        expect(allA.first['id'], 'user-a');
      });
    });

    group('onChanged', () {
      test('fires on write', () async {
        var changeCount = 0;
        store.onChanged.listen((_) => changeCount++);

        await store.write('swap_in', 'x', _entry(id: 'x'));
        // Allow microtask to process
        await Future.delayed(Duration.zero);
        expect(changeCount, 1);
      });

      test('fires on remove', () async {
        await store.write('swap_in', 'x', _entry(id: 'x'));

        var changeCount = 0;
        store.onChanged.listen((_) => changeCount++);
        await store.remove('swap_in', 'x');
        await Future.delayed(Duration.zero);
        expect(changeCount, 1);
      });
    });
  });
}
