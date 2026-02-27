@Tags(['unit'])
library;

import 'dart:convert';

import 'package:hostr_sdk/datasources/storage.dart';
import 'package:hostr_sdk/mocks/usecase_mocks.mocks.dart';
import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/evm/operations/swap_record.dart';
import 'package:hostr_sdk/usecase/evm/operations/swap_store.dart';
import 'package:hostr_sdk/util/custom_logger.dart';
import 'package:mockito/mockito.dart';
import 'package:models/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

void main() {
  late InMemoryKeyValueStorage storage;
  late Auth auth;
  late KeyPair? activeKeyPair;
  late SwapStore store;

  final userA = Bip340.fromPrivateKey('1' * 64);
  final userB = Bip340.fromPrivateKey('2' * 64);

  String keyFor(String pubkey) => 'pending_swaps:$pubkey';

  setUp(() {
    storage = InMemoryKeyValueStorage();
    activeKeyPair = userA;
    final mockAuth = MockAuth();
    when(mockAuth.activeKeyPair).thenAnswer((_) => activeKeyPair);
    auth = mockAuth;
    store = SwapStore(storage, CustomLogger(), auth);
  });

  SwapInRecord _swapIn({
    String boltzId = 'swap-in-1',
    SwapRecordStatus status = SwapRecordStatus.created,
  }) {
    final record = SwapInRecord.create(
      boltzId: boltzId,
      preimage: List<int>.generate(32, (i) => i),
      preimageHash: 'hash-$boltzId',
      onchainAmountSat: 50000,
      timeoutBlockHeight: 800000,
      chainId: 31,
    );
    if (status != SwapRecordStatus.created) {
      return record.copyWithStatus(status);
    }
    return record;
  }

  SwapOutRecord _swapOut({
    String boltzId = 'swap-out-1',
    SwapRecordStatus status = SwapRecordStatus.created,
  }) {
    final record = SwapOutRecord.create(
      boltzId: boltzId,
      invoice: 'lnbc1000...',
      invoicePreimageHashHex: 'deadbeef',
      claimAddress: '0xclaimaddr',
      lockedAmountWei: BigInt.from(1000000),
      lockerAddress: '0xlockeraddr',
      timeoutBlockHeight: 900000,
      chainId: 31,
    );
    if (status != SwapRecordStatus.created) {
      return record.copyWithStatus(status);
    }
    return record;
  }

  group('SwapStore', () {
    group('initialize', () {
      test('loads empty store when storage has nothing', () async {
        await store.initialize();
        final all = await store.getAll();
        expect(all, isEmpty);
      });

      test('loads records from storage', () async {
        // Pre-populate storage
        final record = _swapIn(boltzId: 'preloaded');
        await storage.write(
          keyFor(userA.publicKey),
          jsonEncode([record.toJson()]),
        );

        await store.initialize();
        final all = await store.getAll();
        expect(all, hasLength(1));
        expect(all.first.boltzId, 'preloaded');
      });

      test('is idempotent — second call does not reload', () async {
        await store.initialize();
        await store.save(_swapIn(boltzId: 'first'));

        // Write something different directly to storage
        final other = _swapIn(boltzId: 'other');
        await storage.write(
          keyFor(userA.publicKey),
          jsonEncode([other.toJson()]),
        );

        // Second initialize should be a no-op (cache already loaded)
        await store.initialize();
        final all = await store.getAll();
        expect(all, hasLength(1));
        expect(all.first.boltzId, 'first');
      });

      test('handles corrupt storage gracefully', () async {
        await storage.write(keyFor(userA.publicKey), 'not valid json}}}');
        await store.initialize();
        final all = await store.getAll();
        expect(all, isEmpty); // Should start fresh
      });
    });

    group('save', () {
      test('persists a record and flushes to storage', () async {
        final record = _swapIn();
        await store.save(record);

        // Verify it's retrievable
        final retrieved = await store.get('swap-in-1');
        expect(retrieved, isNotNull);
        expect(retrieved!.boltzId, 'swap-in-1');

        // Verify it's in underlying storage
        final raw = await storage.read(keyFor(userA.publicKey));
        final list = jsonDecode(raw) as List;
        expect(list, hasLength(1));
      });

      test('overwrites existing record with same id', () async {
        final record = _swapIn();
        await store.save(record);

        final updated = record.copyWithStatus(SwapRecordStatus.funded);
        await store.save(updated);

        final all = await store.getAll();
        expect(all, hasLength(1));
        expect(all.first.status, SwapRecordStatus.funded);
      });
    });

    group('updateStatus', () {
      test('updates status and optional fields', () async {
        await store.save(_swapIn());

        final updated = await store.updateStatus(
          'swap-in-1',
          SwapRecordStatus.funded,
          lastBoltzStatus: 'transaction.confirmed',
          refundAddress: '0xrefund',
        );

        expect(updated, isNotNull);
        expect(updated!.status, SwapRecordStatus.funded);
        expect(updated.lastBoltzStatus, 'transaction.confirmed');
        expect((updated as SwapInRecord).refundAddress, '0xrefund');
      });

      test('returns null for unknown record', () async {
        await store.initialize();
        final result = await store.updateStatus(
          'nonexistent',
          SwapRecordStatus.funded,
        );
        expect(result, isNull);
      });

      test('persists update to disk', () async {
        await store.save(_swapIn());
        await store.updateStatus('swap-in-1', SwapRecordStatus.completed);

        // Re-create store from same storage to verify persistence
        final store2 = SwapStore(storage, CustomLogger(), auth);
        await store2.initialize();
        final record = await store2.get('swap-in-1');
        expect(record!.status, SwapRecordStatus.completed);
      });
    });

    group('getPendingRecovery', () {
      test('returns only records that need recovery', () async {
        await store.save(
          _swapIn(boltzId: 'a', status: SwapRecordStatus.funded),
        );
        await store.save(
          _swapIn(boltzId: 'b', status: SwapRecordStatus.claiming),
        );
        await store.save(
          _swapIn(boltzId: 'c', status: SwapRecordStatus.needsAction),
        );
        // These should NOT appear:
        await store.save(
          _swapIn(boltzId: 'd', status: SwapRecordStatus.created),
        );
        await store.save(
          _swapIn(boltzId: 'e', status: SwapRecordStatus.completed),
        );
        await store.save(
          _swapIn(boltzId: 'f', status: SwapRecordStatus.failed),
        );

        final pending = await store.getPendingRecovery();
        expect(pending, hasLength(3));
        final ids = pending.map((r) => r.boltzId).toSet();
        expect(ids, containsAll(['a', 'b', 'c']));
      });

      test('returns empty list when no pending records', () async {
        await store.save(
          _swapIn(boltzId: 'done', status: SwapRecordStatus.completed),
        );
        final pending = await store.getPendingRecovery();
        expect(pending, isEmpty);
      });
    });

    group('getActive', () {
      test('returns non-terminal records', () async {
        await store.save(
          _swapIn(boltzId: 'active1', status: SwapRecordStatus.created),
        );
        await store.save(
          _swapIn(boltzId: 'active2', status: SwapRecordStatus.funded),
        );
        await store.save(
          _swapIn(boltzId: 'done', status: SwapRecordStatus.completed),
        );

        final active = await store.getActive();
        expect(active, hasLength(2));
      });
    });

    group('remove', () {
      test('removes a record by id', () async {
        await store.save(_swapIn(boltzId: 'to-remove'));
        await store.save(_swapIn(boltzId: 'to-keep'));

        await store.remove('to-remove');

        final all = await store.getAll();
        expect(all, hasLength(1));
        expect(all.first.boltzId, 'to-keep');
      });
    });

    group('pruneOlderThan', () {
      test('removes only terminal records older than cutoff', () async {
        final old = SwapInRecord(
          id: 'old',
          boltzId: 'old',
          status: SwapRecordStatus.completed,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
          preimageHex: 'aa',
          preimageHash: 'hh',
          onchainAmountSat: 1000,
          timeoutBlockHeight: 100,
          chainId: 31,
        );
        final recent = SwapInRecord(
          id: 'recent',
          boltzId: 'recent',
          status: SwapRecordStatus.completed,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          preimageHex: 'bb',
          preimageHash: 'hh2',
          onchainAmountSat: 2000,
          timeoutBlockHeight: 200,
          chainId: 31,
        );
        final oldButActive = SwapOutRecord(
          id: 'old-active',
          boltzId: 'old-active',
          status: SwapRecordStatus.funded,
          createdAt: DateTime(2025, 1, 1),
          updatedAt: DateTime(2025, 1, 1),
          invoice: 'inv',
          invoicePreimageHashHex: 'cc',
          claimAddress: '0xaddr',
          lockedAmountWeiHex: 'ff',
          lockerAddress: '0xlocker',
          timeoutBlockHeight: 300,
          chainId: 31,
        );

        await store.save(old);
        await store.save(recent);
        await store.save(oldButActive);

        final pruned = await store.pruneOlderThan(const Duration(days: 30));
        expect(pruned, 1);

        final all = await store.getAll();
        expect(all, hasLength(2));
        final ids = all.map((r) => r.boltzId).toSet();
        expect(ids, containsAll(['recent', 'old-active']));
      });

      test('returns 0 when nothing to prune', () async {
        await store.save(_swapIn(boltzId: 'fresh'));
        final pruned = await store.pruneOlderThan(const Duration(days: 30));
        expect(pruned, 0);
      });
    });

    group('persistence roundtrip', () {
      test('records survive store recreation', () async {
        await store.save(_swapIn(boltzId: 'persist-1'));
        await store.save(_swapOut(boltzId: 'persist-2'));

        // Create a new store instance pointing at the same storage
        final store2 = SwapStore(storage, CustomLogger(), auth);
        await store2.initialize();

        final all = await store2.getAll();
        expect(all, hasLength(2));

        final inRecord = all.firstWhere((r) => r.boltzId == 'persist-1');
        expect(inRecord, isA<SwapInRecord>());

        final outRecord = all.firstWhere((r) => r.boltzId == 'persist-2');
        expect(outRecord, isA<SwapOutRecord>());
      });

      test(
        'keeps data isolated per pubkey and survives auth changes',
        () async {
          await store.save(_swapIn(boltzId: 'user-a-swap'));

          activeKeyPair = userB;
          await store.initialize();
          expect(await store.getAll(), isEmpty);

          await store.save(_swapIn(boltzId: 'user-b-swap'));

          final rawA = await storage.read(keyFor(userA.publicKey));
          final rawB = await storage.read(keyFor(userB.publicKey));
          expect(rawA, isNotNull);
          expect(rawB, isNotNull);

          activeKeyPair = userA;
          await store.initialize();
          final allA = await store.getAll();
          expect(allA, hasLength(1));
          expect(allA.first.boltzId, 'user-a-swap');
        },
      );
    });
  });
}
