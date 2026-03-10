@Tags(['unit'])
library;

import 'dart:convert';

import 'package:hostr_sdk/mocks/usecase_mocks.mocks.dart';
import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/evm/operations/operation_state_store.dart';
import 'package:hostr_sdk/util/custom_logger.dart';
import 'package:mockito/mockito.dart';
import 'package:models/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart' as native_sqlite3;
import 'package:test/test.dart';

void main() {
  late CommonDatabase db;
  late Auth auth;
  late KeyPair? activeKeyPair;
  late OperationStateStore store;

  final userA = Bip340.fromPrivateKey('1' * 64);
  final userB = Bip340.fromPrivateKey('2' * 64);

  Map<String, dynamic> _entry({
    required String id,
    bool isTerminal = false,
    String? updatedAt,
  }) => {'id': id, 'isTerminal': isTerminal, 'updatedAt': ?updatedAt};

  setUp(() {
    db = native_sqlite3.sqlite3.openInMemory();
    activeKeyPair = userA;
    final mockAuth = MockAuth();
    when(mockAuth.activeKeyPair).thenAnswer((_) => activeKeyPair);
    auth = mockAuth;
    store = OperationStateStore(db, CustomLogger(), auth);
  });

  tearDown(() {
    store.dispose();
    db.dispose();
  });

  group('OperationStateStore', () {
    group('reads', () {
      test('returns empty when database has nothing', () async {
        final all = await store.readAll('swap_in');
        expect(all, isEmpty);
      });

      test('reads entries inserted directly into database', () async {
        final entry = _entry(id: 'preloaded');
        db.execute(
          '''INSERT INTO operations
             (pubkey, namespace, id, state, is_terminal, updated_at, data)
             VALUES (?, ?, ?, ?, ?, ?, ?)''',
          [
            userA.publicKey,
            'swap_in',
            'preloaded',
            null,
            0,
            null,
            jsonEncode(entry),
          ],
        );

        final all = await store.readAll('swap_in');
        expect(all, hasLength(1));
        expect(all.first['id'], 'preloaded');
      });

      test('always reads fresh from database (no stale cache)', () async {
        await store.write('swap_in', 'first', _entry(id: 'first'));

        // Mutate directly in database (simulating another isolate)
        final newEntry = _entry(id: 'first');
        newEntry['extra'] = 'updated';
        db.execute(
          'UPDATE operations SET data = ? WHERE id = ?',
          [jsonEncode(newEntry), 'first'],
        );

        final retrieved = await store.read('swap_in', 'first');
        expect(retrieved, isNotNull);
        expect(retrieved!['extra'], 'updated');
      });

      test('handles corrupt JSON in data column gracefully', () async {
        db.execute(
          '''INSERT INTO operations
             (pubkey, namespace, id, state, is_terminal, data)
             VALUES (?, ?, ?, ?, ?, ?)''',
          [userA.publicKey, 'swap_in', 'corrupt', null, 0, 'not valid json}}}'],
        );
        final all = await store.readAll('swap_in');
        expect(all, isEmpty);
      });
    });

    group('write / read', () {
      test('persists an entry and reads it back', () async {
        final entry = _entry(id: 'item-1');
        await store.write('swap_in', 'item-1', entry);

        final retrieved = await store.read('swap_in', 'item-1');
        expect(retrieved, isNotNull);
        expect(retrieved!['id'], 'item-1');

        // Verify it's in the underlying database
        final rows = db.select(
          'SELECT data FROM operations WHERE id = ?',
          ['item-1'],
        );
        expect(rows, hasLength(1));
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
      test('entries survive store recreation (same db)', () async {
        await store.write('swap_in', 'persist-1', _entry(id: 'persist-1'));
        await store.write('swap_out', 'persist-2', _entry(id: 'persist-2'));
        store.dispose();

        // Create a new store instance pointing at the same database
        final store2 = OperationStateStore(db, CustomLogger(), auth);
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
        store.dispose();
        store = OperationStateStore(db, CustomLogger(), auth);
        final allB = await store.readAll('swap_in');
        expect(allB, isEmpty);

        await store.write('swap_in', 'user-b', _entry(id: 'user-b'));

        // Verify database has both users' data
        final rowsA = db.select(
          'SELECT * FROM operations WHERE pubkey = ? AND namespace = ?',
          [userA.publicKey, 'swap_in'],
        );
        final rowsB = db.select(
          'SELECT * FROM operations WHERE pubkey = ? AND namespace = ?',
          [userB.publicKey, 'swap_in'],
        );
        expect(rowsA, hasLength(1));
        expect(rowsB, hasLength(1));

        // Switch back to user A
        activeKeyPair = userA;
        store.dispose();
        store = OperationStateStore(db, CustomLogger(), auth);
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

    group('atomicClaim', () {
      test('claims when persisted state is in allowed set', () async {
        await store.write('swap_in', 'op1', {
          'id': 'op1',
          'state': 'funded',
          'isTerminal': false,
          'updatedAt': DateTime.now().toIso8601String(),
        });

        final result = store.atomicClaim(
          namespace: 'swap_in',
          id: 'op1',
          allowedStates: {'funded'},
          busyStateName: 'claimRelaying',
          busyStateJson: {
            'id': 'op1',
            'state': 'claimRelaying',
            'isTerminal': false,
            'updatedAt': DateTime.now().toIso8601String(),
          },
          staleTimeout: const Duration(minutes: 30),
        );

        expect(result.outcome, CasOutcome.claimed);

        // Verify the busy state was written
        final persisted = await store.read('swap_in', 'op1');
        expect(persisted?['state'], 'claimRelaying');
      });

      test('returns raceForward when state is not in allowed set', () async {
        await store.write('swap_in', 'op1', {
          'id': 'op1',
          'state': 'claimed',
          'isTerminal': false,
          'updatedAt': DateTime.now().toIso8601String(),
        });

        final result = store.atomicClaim(
          namespace: 'swap_in',
          id: 'op1',
          allowedStates: {'funded'},
          busyStateName: 'claimRelaying',
          busyStateJson: {
            'id': 'op1',
            'state': 'claimRelaying',
            'isTerminal': false,
            'updatedAt': DateTime.now().toIso8601String(),
          },
          staleTimeout: const Duration(minutes: 30),
        );

        expect(result.outcome, CasOutcome.raceForward);
        expect(result.persistedJson, isNotNull);
        expect(result.persistedJson!['state'], 'claimed');
      });

      test('returns busyBackoff when busy state is fresh', () async {
        await store.write('swap_in', 'op1', {
          'id': 'op1',
          'state': 'claimRelaying',
          'isTerminal': false,
          'updatedAt': DateTime.now().toIso8601String(),
        });

        final result = store.atomicClaim(
          namespace: 'swap_in',
          id: 'op1',
          allowedStates: {'funded', 'claimRelaying'},
          busyStateName: 'claimRelaying',
          busyStateJson: {
            'id': 'op1',
            'state': 'claimRelaying',
            'isTerminal': false,
            'updatedAt': DateTime.now().toIso8601String(),
          },
          staleTimeout: const Duration(minutes: 30),
        );

        expect(result.outcome, CasOutcome.busyBackoff);
        expect(result.busyAge, isNotNull);
      });

      test('reclaims stale busy state', () async {
        final staleTime = DateTime.now()
            .subtract(const Duration(minutes: 31))
            .toIso8601String();

        await store.write('swap_in', 'op1', {
          'id': 'op1',
          'state': 'claimRelaying',
          'isTerminal': false,
          'updatedAt': staleTime,
        });

        final result = store.atomicClaim(
          namespace: 'swap_in',
          id: 'op1',
          allowedStates: {'funded', 'claimRelaying'},
          busyStateName: 'claimRelaying',
          busyStateJson: {
            'id': 'op1',
            'state': 'claimRelaying',
            'isTerminal': false,
            'updatedAt': DateTime.now().toIso8601String(),
          },
          staleTimeout: const Duration(minutes: 30),
        );

        expect(result.outcome, CasOutcome.claimed);
      });

      test('claims when entry does not exist', () {
        final result = store.atomicClaim(
          namespace: 'swap_in',
          id: 'nonexistent',
          allowedStates: {'funded'},
          busyStateName: 'claimRelaying',
          busyStateJson: {'id': 'nonexistent', 'state': 'claimRelaying'},
          staleTimeout: const Duration(minutes: 30),
        );

        expect(result.outcome, CasOutcome.claimed);
      });
    });

    group('writeIfOwned', () {
      test('writes when state matches expected', () async {
        await store.write('swap_in', 'op1', {
          'id': 'op1',
          'state': 'claimRelaying',
          'isTerminal': false,
        });

        final result = store.writeIfOwned(
          namespace: 'swap_in',
          id: 'op1',
          expectedState: 'claimRelaying',
          json: {
            'id': 'op1',
            'state': 'claimed',
            'isTerminal': false,
            'updatedAt': DateTime.now().toIso8601String(),
          },
        );

        expect(result.written, isTrue);
        final persisted = await store.read('swap_in', 'op1');
        expect(persisted?['state'], 'claimed');
      });

      test('rejects when state does not match', () async {
        await store.write('swap_in', 'op1', {
          'id': 'op1',
          'state': 'claimed',
          'isTerminal': false,
        });

        final result = store.writeIfOwned(
          namespace: 'swap_in',
          id: 'op1',
          expectedState: 'claimRelaying',
          json: {
            'id': 'op1',
            'state': 'newState',
            'isTerminal': false,
          },
        );

        expect(result.written, isFalse);
        expect(result.persistedJson, isNotNull);
        expect(result.persistedJson!['state'], 'claimed');

        // Verify original state unchanged
        final persisted = await store.read('swap_in', 'op1');
        expect(persisted?['state'], 'claimed');
      });

      test('inserts when entry does not exist', () {
        final result = store.writeIfOwned(
          namespace: 'swap_in',
          id: 'new-op',
          expectedState: 'anything',
          json: {
            'id': 'new-op',
            'state': 'funded',
            'isTerminal': false,
          },
        );

        expect(result.written, isTrue);
      });
    });
  });
}
