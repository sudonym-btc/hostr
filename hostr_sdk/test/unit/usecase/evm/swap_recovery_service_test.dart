@Tags(['unit'])
library;

import 'package:hostr_sdk/mocks/usecase_mocks.mocks.dart';
import 'package:hostr_sdk/usecase/evm/operations/operation_state_store.dart';
import 'package:hostr_sdk/usecase/evm/operations/swap_in/swap_in_state.dart';
import 'package:hostr_sdk/usecase/evm/operations/swap_out/swap_out_state.dart';
import 'package:hostr_sdk/util/custom_logger.dart';
import 'package:mockito/mockito.dart';
import 'package:models/bip340.dart';
import 'package:sqlite3/common.dart';
import 'package:sqlite3/sqlite3.dart' as native_sqlite3;
import 'package:test/test.dart';

/// These tests verify the persistence layer used by [SwapRecoverer]:
/// round-trip serialisation of swap states to/from [OperationStateStore],
/// filtering of terminal vs non-terminal entries, and pruning.
///
/// Full integration tests that exercise actual recovery (Boltz API, claim
/// transactions, etc.) are in the integration_test/ directory.
void main() {
  late CommonDatabase db;
  late OperationStateStore store;

  final userA = Bip340.fromPrivateKey('1' * 64);

  setUp(() {
    db = native_sqlite3.sqlite3.openInMemory();
    final mockAuth = MockAuth();
    when(mockAuth.activeKeyPair).thenAnswer((_) => userA);
    store = OperationStateStore(db, CustomLogger(), mockAuth);
  });

  tearDown(() {
    store.dispose();
    db.dispose();
  });

  // ── Helpers ───────────────────────────────────────────────────────────

  /// A minimal SwapInRequestCreated JSON, the earliest recoverable state.
  /// Matches the flat layout produced by SwapInRequestCreated.toJson().
  Map<String, dynamic> _swapInJson({
    String boltzId = 'swap-in-1',
    bool terminal = false,
  }) => {
    'state': 'requestCreated',
    'id': boltzId,
    'isTerminal': terminal,
    'updatedAt': DateTime.now().toIso8601String(),
    // SwapInData fields at top level (spread by toJson)
    'boltzId': boltzId,
    'preimageHex': 'aa' * 32,
    'preimageHash': 'hh',
    'onchainAmountSat': 50000,
    'timeoutBlockHeight': 800000,
    'chainId': 31,
    'accountIndex': 0,
  };

  /// A minimal SwapOutAwaitingOnChain JSON, the earliest recoverable state.
  /// Matches the flat layout produced by SwapOutAwaitingOnChain.toJson().
  Map<String, dynamic> _swapOutJson({
    String boltzId = 'swap-out-1',
    bool terminal = false,
  }) => {
    'state': 'awaitingOnChain',
    'id': boltzId,
    'isTerminal': terminal,
    'updatedAt': DateTime.now().toIso8601String(),
    // SwapOutData fields at top level (spread by toJson)
    'boltzId': boltzId,
    'invoice': 'lnbc50000...',
    'invoicePreimageHashHex': 'deadbeef',
    'claimAddress': '0xclaimaddr',
    'lockedAmountWeiHex': 'b5e620f48000',
    'lockerAddress': '0xlockeraddr',
    'timeoutBlockHeight': 900000,
    'chainId': 31,
    'accountIndex': 0,
  };

  group('swap state persistence', () {
    test('swap-in state round-trips through store', () async {
      final json = _swapInJson(boltzId: 'in-1');
      await store.write('swap_in', 'in-1', json);

      final loaded = await store.read('swap_in', 'in-1');
      expect(loaded, isNotNull);
      expect(loaded!['id'], 'in-1');

      // Verify it deserialises back to a real state
      final state = SwapInState.fromJson(loaded);
      expect(state, isA<SwapInRequestCreated>());
      expect(state.data?.boltzId, 'in-1');
    });

    test('swap-out state round-trips through store', () async {
      final json = _swapOutJson(boltzId: 'out-1');
      await store.write('swap_out', 'out-1', json);

      final loaded = await store.read('swap_out', 'out-1');
      expect(loaded, isNotNull);

      final state = SwapOutState.fromJson(loaded!);
      expect(state, isA<SwapOutAwaitingOnChain>());
      expect(state.data?.boltzId, 'out-1');
    });

    test('readAll returns all entries for a namespace', () async {
      await store.write('swap_in', 'a', _swapInJson(boltzId: 'a'));
      await store.write('swap_in', 'b', _swapInJson(boltzId: 'b'));
      await store.write('swap_out', 'c', _swapOutJson(boltzId: 'c'));

      final swapIns = await store.readAll('swap_in');
      expect(swapIns, hasLength(2));

      final swapOuts = await store.readAll('swap_out');
      expect(swapOuts, hasLength(1));
    });
  });

  group('terminal filtering', () {
    test('hasNonTerminal returns true for non-terminal entries', () async {
      await store.write('swap_in', 'active', _swapInJson(boltzId: 'active'));
      expect(await store.hasNonTerminal('swap_in'), isTrue);
    });

    test(
      'hasNonTerminal returns false when all entries are terminal',
      () async {
        await store.write(
          'swap_in',
          'done',
          _swapInJson(boltzId: 'done', terminal: true),
        );
        expect(await store.hasNonTerminal('swap_in'), isFalse);
      },
    );

    test('hasNonTerminal returns false for empty namespace', () async {
      expect(await store.hasNonTerminal('swap_in'), isFalse);
    });
  });

  group('pruning', () {
    test('prunes terminal entries older than 30 days', () async {
      final oldDate = DateTime(2025, 1, 1).toIso8601String();
      final recentDate = DateTime.now().toIso8601String();

      final oldEntry = _swapInJson(boltzId: 'old', terminal: true);
      oldEntry['updatedAt'] = oldDate;

      final recentEntry = _swapInJson(boltzId: 'recent', terminal: true);
      recentEntry['updatedAt'] = recentDate;

      final activeEntry = _swapInJson(boltzId: 'active');
      activeEntry['updatedAt'] = oldDate;

      await store.write('swap_in', 'old', oldEntry);
      await store.write('swap_in', 'recent', recentEntry);
      await store.write('swap_in', 'active', activeEntry);

      final pruned = await store.pruneTerminal(
        'swap_in',
        const Duration(days: 30),
      );
      expect(pruned, 1);

      final remaining = await store.readAll('swap_in');
      expect(remaining, hasLength(2));
      final ids = remaining.map((e) => e['id']).toSet();
      expect(ids, containsAll(['recent', 'active']));
    });

    test('returns 0 when nothing to prune', () async {
      await store.write('swap_in', 'fresh', _swapInJson(boltzId: 'fresh'));
      final pruned = await store.pruneTerminal(
        'swap_in',
        const Duration(days: 30),
      );
      expect(pruned, 0);
    });
  });

  group('persistence round-trip (storage recreation)', () {
    test('entries survive store recreation', () async {
      await store.write('swap_in', 'in-1', _swapInJson(boltzId: 'in-1'));
      await store.write('swap_out', 'out-1', _swapOutJson(boltzId: 'out-1'));
      store.dispose();

      // Create fresh store from same database
      final mockAuth = MockAuth();
      when(mockAuth.activeKeyPair).thenAnswer((_) => userA);
      final store2 = OperationStateStore(db, CustomLogger(), mockAuth);

      final swapIns = await store2.readAll('swap_in');
      final swapOuts = await store2.readAll('swap_out');
      expect(swapIns, hasLength(1));
      expect(swapOuts, hasLength(1));

      // Verify deserialization still works
      final state = SwapInState.fromJson(swapIns.first);
      expect(state, isA<SwapInRequestCreated>());
      store2.dispose();
    });
  });
}
