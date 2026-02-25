import 'dart:convert';

import 'package:hostr_sdk/datasources/storage.dart';
import 'package:hostr_sdk/mocks/usecase_mocks.mocks.dart';
import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/evm/operations/auto_withdraw/escrow_lock.dart';
import 'package:hostr_sdk/usecase/evm/operations/auto_withdraw/escrow_lock_registry.dart';
import 'package:hostr_sdk/util/bitcoin_amount.dart';
import 'package:hostr_sdk/util/custom_logger.dart';
import 'package:mockito/mockito.dart';
import 'package:models/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

void main() {
  late InMemoryKeyValueStorage storage;
  late Auth auth;
  late KeyPair? activeKeyPair;
  late EscrowLockRegistry registry;

  final userA = Bip340.fromPrivateKey('1' * 64);
  final userB = Bip340.fromPrivateKey('2' * 64);

  String keyFor(String pubkey) => 'escrow_locks:$pubkey';

  setUp(() {
    storage = InMemoryKeyValueStorage();
    activeKeyPair = userA;
    final mockAuth = MockAuth();
    when(mockAuth.activeKeyPair).thenAnswer((_) => activeKeyPair);
    auth = mockAuth;
    registry = EscrowLockRegistry(storage, CustomLogger(), auth);
  });

  tearDown(() {
    registry.dispose();
  });

  group('EscrowLock model', () {
    test('toJson / fromJson roundtrip', () {
      final lock = EscrowLock(
        tradeId: 'trade-42',
        reservedAmountWei: BigInt.from(100000),
        acquiredAt: DateTime(2025, 6, 15, 12, 0, 0),
      );

      final json = lock.toJson();
      final restored = EscrowLock.fromJson(json);

      expect(restored.tradeId, 'trade-42');
      expect(restored.reservedAmountWei, BigInt.from(100000));
      expect(
        restored.acquiredAt.millisecondsSinceEpoch,
        lock.acquiredAt.millisecondsSinceEpoch,
      );
    });

    test('serialises reservedAmountWei as hex string', () {
      final lock = EscrowLock(
        tradeId: 'hex-test',
        reservedAmountWei: BigInt.parse(
          'de0b6b3a7640000',
          radix: 16,
        ), // 1 ether
        acquiredAt: DateTime.now(),
      );

      final json = lock.toJson();
      expect(json['reservedAmountWei'], isA<String>());
      expect(json['reservedAmountWei'], 'de0b6b3a7640000');
    });
  });

  group('EscrowLockRegistry', () {
    group('initialize', () {
      test('loads empty registry when storage is empty', () async {
        await registry.initialize();
        final all = await registry.getAll();
        expect(all, isEmpty);
      });

      test('loads locks from storage', () async {
        final lock = EscrowLock(
          tradeId: 'preloaded',
          reservedAmountWei: BigInt.from(50000),
          acquiredAt: DateTime.now(),
        );
        await storage.write(
          keyFor(userA.publicKey),
          jsonEncode([lock.toJson()]),
        );

        await registry.initialize();
        final all = await registry.getAll();
        expect(all, hasLength(1));
        expect(all.first.tradeId, 'preloaded');
      });

      test('is idempotent — second call does not reload', () async {
        await registry.initialize();
        await registry.acquire(
          'first',
          BitcoinAmount.fromInt(BitcoinUnit.sat, 1000),
        );

        // Write something different directly to storage
        final other = EscrowLock(
          tradeId: 'other',
          reservedAmountWei: BigInt.from(999),
          acquiredAt: DateTime.now(),
        );
        await storage.write(
          keyFor(userA.publicKey),
          jsonEncode([other.toJson()]),
        );

        // Second initialize should be a no-op
        await registry.initialize();
        final all = await registry.getAll();
        expect(all, hasLength(1));
        expect(all.first.tradeId, 'first');
      });

      test('handles corrupt storage gracefully', () async {
        await storage.write(keyFor(userA.publicKey), 'not valid json}}}');
        await registry.initialize();
        final all = await registry.getAll();
        expect(all, isEmpty);
      });
    });

    group('acquire', () {
      test('persists a lock and flushes to storage', () async {
        final lock = await registry.acquire(
          'trade-1',
          BitcoinAmount.fromInt(BitcoinUnit.sat, 50000),
        );

        expect(lock.tradeId, 'trade-1');

        // Verify it's retrievable
        final retrieved = await registry.get('trade-1');
        expect(retrieved, isNotNull);
        expect(retrieved!.tradeId, 'trade-1');

        // Verify it's in underlying storage
        final raw = await storage.read(keyFor(userA.publicKey));
        final list = jsonDecode(raw) as List;
        expect(list, hasLength(1));
      });

      test('replaces existing lock with same tradeId (idempotent)', () async {
        await registry.acquire(
          'trade-1',
          BitcoinAmount.fromInt(BitcoinUnit.sat, 10000),
        );
        await registry.acquire(
          'trade-1',
          BitcoinAmount.fromInt(BitcoinUnit.sat, 20000),
        );

        final all = await registry.getAll();
        expect(all, hasLength(1));
        // Should have the newer amount
        expect(
          all.first.reservedAmountWei,
          BitcoinAmount.fromInt(BitcoinUnit.sat, 20000).getInWei,
        );
      });
    });

    group('release', () {
      test('removes a lock by tradeId', () async {
        await registry.acquire(
          'to-release',
          BitcoinAmount.fromInt(BitcoinUnit.sat, 1000),
        );
        await registry.acquire(
          'to-keep',
          BitcoinAmount.fromInt(BitcoinUnit.sat, 2000),
        );

        await registry.release('to-release');

        final all = await registry.getAll();
        expect(all, hasLength(1));
        expect(all.first.tradeId, 'to-keep');
      });

      test(
        'is a no-op for unknown tradeId (safe for finally blocks)',
        () async {
          await registry.initialize();
          // Should not throw
          await registry.release('nonexistent');
          final all = await registry.getAll();
          expect(all, isEmpty);
        },
      );

      test('persists removal to disk', () async {
        await registry.acquire(
          'temp',
          BitcoinAmount.fromInt(BitcoinUnit.sat, 500),
        );
        await registry.release('temp');

        // Re-create registry from same storage
        final registry2 = EscrowLockRegistry(storage, CustomLogger(), auth);
        await registry2.initialize();
        final all = await registry2.getAll();
        expect(all, isEmpty);
        registry2.dispose();
      });
    });

    group('hasActiveLocks', () {
      test('returns false when empty', () async {
        expect(await registry.hasActiveLocks, isFalse);
      });

      test('returns true when locks are held', () async {
        await registry.acquire(
          'trade-1',
          BitcoinAmount.fromInt(BitcoinUnit.sat, 1000),
        );
        expect(await registry.hasActiveLocks, isTrue);
      });

      test('returns false after all locks are released', () async {
        await registry.acquire(
          'trade-1',
          BitcoinAmount.fromInt(BitcoinUnit.sat, 1000),
        );
        await registry.release('trade-1');
        expect(await registry.hasActiveLocks, isFalse);
      });
    });

    group('hasActiveLocksStream', () {
      test('emits changes as locks are acquired and released', () async {
        final emissions = <bool>[];
        final sub = registry.hasActiveLocksStream.listen(emissions.add);

        // Allow the initial seeded value to propagate
        await Future<void>.delayed(Duration.zero);

        await registry.acquire(
          'trade-1',
          BitcoinAmount.fromInt(BitcoinUnit.sat, 1000),
        );
        await registry.release('trade-1');

        // Allow stream to propagate
        await Future<void>.delayed(Duration.zero);

        await sub.cancel();

        // Expect: seeded false, then true (acquire), then false (release)
        expect(emissions, containsAllInOrder([false, true, false]));
      });
    });

    group('totalReservedAmount', () {
      test('returns zero when empty', () async {
        final total = await registry.totalReservedAmount;
        expect(total, equals(BitcoinAmount.zero()));
      });

      test('sums all active lock amounts', () async {
        await registry.acquire(
          'trade-1',
          BitcoinAmount.fromInt(BitcoinUnit.sat, 10000),
        );
        await registry.acquire(
          'trade-2',
          BitcoinAmount.fromInt(BitcoinUnit.sat, 20000),
        );

        final total = await registry.totalReservedAmount;
        final expected = BitcoinAmount.fromInt(BitcoinUnit.sat, 30000);
        expect(total, equals(expected));
      });

      test('decreases after release', () async {
        await registry.acquire(
          'trade-1',
          BitcoinAmount.fromInt(BitcoinUnit.sat, 10000),
        );
        await registry.acquire(
          'trade-2',
          BitcoinAmount.fromInt(BitcoinUnit.sat, 20000),
        );
        await registry.release('trade-1');

        final total = await registry.totalReservedAmount;
        final expected = BitcoinAmount.fromInt(BitcoinUnit.sat, 20000);
        expect(total, equals(expected));
      });
    });

    group('activeTradeIds', () {
      test('returns all held trade IDs', () async {
        await registry.acquire(
          'a',
          BitcoinAmount.fromInt(BitcoinUnit.sat, 1000),
        );
        await registry.acquire(
          'b',
          BitcoinAmount.fromInt(BitcoinUnit.sat, 2000),
        );

        final ids = await registry.activeTradeIds;
        expect(ids, containsAll(['a', 'b']));
      });
    });

    group('pruneOlderThan', () {
      test('removes locks older than cutoff', () async {
        // Directly seed storage with an old lock
        final oldLock = EscrowLock(
          tradeId: 'old-lock',
          reservedAmountWei: BigInt.from(1000),
          acquiredAt: DateTime(2024, 1, 1),
        );
        final recentLock = EscrowLock(
          tradeId: 'recent-lock',
          reservedAmountWei: BigInt.from(2000),
          acquiredAt: DateTime.now(),
        );
        await storage.write(
          keyFor(userA.publicKey),
          jsonEncode([oldLock.toJson(), recentLock.toJson()]),
        );

        final registry2 = EscrowLockRegistry(storage, CustomLogger(), auth);
        final pruned = await registry2.pruneOlderThan(const Duration(days: 30));
        expect(pruned, 1);

        final all = await registry2.getAll();
        expect(all, hasLength(1));
        expect(all.first.tradeId, 'recent-lock');
        registry2.dispose();
      });

      test('returns 0 when nothing to prune', () async {
        await registry.acquire(
          'fresh',
          BitcoinAmount.fromInt(BitcoinUnit.sat, 500),
        );
        final pruned = await registry.pruneOlderThan(const Duration(days: 30));
        expect(pruned, 0);
      });
    });

    group('persistence roundtrip', () {
      test('locks survive registry recreation', () async {
        await registry.acquire(
          'persist-1',
          BitcoinAmount.fromInt(BitcoinUnit.sat, 10000),
        );
        await registry.acquire(
          'persist-2',
          BitcoinAmount.fromInt(BitcoinUnit.sat, 20000),
        );

        // Create a new registry pointing at the same storage
        final registry2 = EscrowLockRegistry(storage, CustomLogger(), auth);
        await registry2.initialize();

        final all = await registry2.getAll();
        expect(all, hasLength(2));

        final ids = all.map((l) => l.tradeId).toSet();
        expect(ids, containsAll(['persist-1', 'persist-2']));
        registry2.dispose();
      });

      test('amounts are preserved exactly through serialisation', () async {
        // Use a large amount to exercise BigInt hex serialisation
        final amount = BitcoinAmount.fromBigInt(
          BitcoinUnit.wei,
          BigInt.parse('de0b6b3a7640000', radix: 16), // 1 ether in wei
        );
        await registry.acquire('big-amount', amount);

        final registry2 = EscrowLockRegistry(storage, CustomLogger(), auth);
        await registry2.initialize();

        final lock = await registry2.get('big-amount');
        expect(lock, isNotNull);
        expect(lock!.reservedAmountWei, amount.getInWei);
        registry2.dispose();
      });

      test(
        'keeps locks isolated per pubkey and survives auth changes',
        () async {
          await registry.acquire(
            'user-a-lock',
            BitcoinAmount.fromInt(BitcoinUnit.sat, 1000),
          );

          activeKeyPair = userB;
          await registry.initialize();
          expect(await registry.getAll(), isEmpty);

          await registry.acquire(
            'user-b-lock',
            BitcoinAmount.fromInt(BitcoinUnit.sat, 2000),
          );

          final rawA = await storage.read(keyFor(userA.publicKey));
          final rawB = await storage.read(keyFor(userB.publicKey));
          expect(rawA, isNotNull);
          expect(rawB, isNotNull);

          activeKeyPair = userA;
          await registry.initialize();
          final locksA = await registry.getAll();
          expect(locksA, hasLength(1));
          expect(locksA.first.tradeId, 'user-a-lock');
        },
      );
    });
  });
}
