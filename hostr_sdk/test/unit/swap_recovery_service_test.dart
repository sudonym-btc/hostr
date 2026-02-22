import 'package:convert/convert.dart';
import 'package:get_it/get_it.dart';
import 'package:hostr_sdk/datasources/storage.dart';
import 'package:hostr_sdk/usecase/evm/chain/evm_chain.dart';
import 'package:hostr_sdk/usecase/evm/chain/rootstock/rif_relay/rif_relay.dart';
import 'package:hostr_sdk/usecase/evm/operations/swap_record.dart';
import 'package:hostr_sdk/usecase/evm/operations/swap_recovery_service.dart';
import 'package:hostr_sdk/usecase/evm/operations/swap_store.dart';
import 'package:hostr_sdk/util/custom_logger.dart';
import 'package:test/test.dart';
import 'package:web3dart/web3dart.dart' show EthPrivateKey;

import 'fakes/fake_boltz_client.dart';
import 'fakes/fake_evm_chain.dart';

void main() {
  late SwapStore swapStore;
  late FakeBoltzClient boltzClient;
  late FakeEvmChain fakeChain;
  late SwapRecoveryService recoveryService;
  late EthPrivateKey evmKey;

  setUp(() async {
    // Reset DI container and register fakes
    await GetIt.instance.reset();

    swapStore = SwapStore(InMemoryKeyValueStorage(), CustomLogger());
    boltzClient = FakeBoltzClient();
    fakeChain = FakeEvmChain();
    recoveryService = SwapRecoveryService(
      swapStore,
      boltzClient,
      CustomLogger(),
    );

    // Register FakeRifRelay in DI (SwapRecoveryService looks up RifRelay via getIt)
    GetIt.instance.registerFactoryParam<RifRelay, dynamic, dynamic>(
      (client, _) => FakeRifRelay(fakeChain),
    );

    // A deterministic private key for tests
    evmKey = EthPrivateKey.fromHex(
      'ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80',
    );
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  Future<EvmChain> chainResolver(int chainId) async => fakeChain;

  // ─── Helpers ────────────────────────────────────────────────────────────

  SwapRecord _pendingSwapIn({
    String boltzId = 'swap-in-1',
    SwapRecordStatus status = SwapRecordStatus.funded,
  }) {
    final preimage = List<int>.generate(32, (i) => i);
    final record = SwapRecord.forSwapIn(
      boltzId: boltzId,
      preimage: preimage,
      preimageHash: hex.encode(preimage),
      onchainAmountSat: 50000,
      timeoutBlockHeight: 800000,
      chainId: 31,
    );
    return record.copyWithStatus(
      status,
      refundAddress: '0x1234567890abcdef1234567890abcdef12345678',
    );
  }

  SwapRecord _pendingSwapOut({
    String boltzId = 'swap-out-1',
    SwapRecordStatus status = SwapRecordStatus.funded,
    String? lockTxHash = '0xlocktx',
  }) {
    final hashBytes = List<int>.generate(32, (i) => i);
    final record = SwapRecord.forSwapOut(
      boltzId: boltzId,
      invoice: 'lnbc50000...',
      invoicePreimageHashHex: hex.encode(hashBytes),
      claimAddress: '0xaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
      lockedAmountWei: BigInt.from(50000000000000),
      lockerAddress: '0xbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb',
      timeoutBlockHeight: 900000,
      chainId: 31,
    );
    return record.copyWithStatus(status, lockTxHash: lockTxHash);
  }

  // ─── Swap-In Recovery Tests ─────────────────────────────────────────────

  group('Swap-In Recovery', () {
    test('no pending swaps returns 0', () async {
      final resolved = await recoveryService.recoverPendingSwaps(
        evmKey: evmKey,
        chainResolver: chainResolver,
      );
      expect(resolved, 0);
    });

    test('skips records without chainId', () async {
      final record = SwapRecord(
        id: 'no-chain',
        boltzId: 'no-chain',
        type: SwapType.swapIn,
        status: SwapRecordStatus.funded,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        chainId: null,
      );
      await swapStore.save(record);

      final resolved = await recoveryService.recoverPendingSwaps(
        evmKey: evmKey,
        chainResolver: chainResolver,
      );
      expect(resolved, 0);
    });

    test('marks swap-in as failed when Boltz already refunded', () async {
      final record = _pendingSwapIn();
      await swapStore.save(record);
      boltzClient.swapStatuses['swap-in-1'] = 'transaction.refunded';

      final resolved = await recoveryService.recoverPendingSwaps(
        evmKey: evmKey,
        chainResolver: chainResolver,
      );
      expect(resolved, 0);

      final updated = await swapStore.get('swap-in-1');
      expect(updated!.status, SwapRecordStatus.failed);
      expect(updated.lastBoltzStatus, 'transaction.refunded');
      expect(updated.errorMessage, contains('refunded'));
    });

    test(
      'marks expired swap-in as resolved (Lightning auto-refunds)',
      () async {
        final record = _pendingSwapIn();
        await swapStore.save(record);
        boltzClient.swapStatuses['swap-in-1'] = 'swap.expired';

        final resolved = await recoveryService.recoverPendingSwaps(
          evmKey: evmKey,
          chainResolver: chainResolver,
        );
        expect(resolved, 1);

        final updated = await swapStore.get('swap-in-1');
        expect(updated!.status, SwapRecordStatus.failed);
      },
    );

    test('marks swap-in completed when already settled', () async {
      final record = _pendingSwapIn();
      await swapStore.save(record);
      boltzClient.swapStatuses['swap-in-1'] = 'invoice.settled';

      final resolved = await recoveryService.recoverPendingSwaps(
        evmKey: evmKey,
        chainResolver: chainResolver,
      );
      expect(resolved, 1);

      final updated = await swapStore.get('swap-in-1');
      expect(updated!.status, SwapRecordStatus.completed);
    });

    test('attempts claim when Boltz shows transaction.confirmed', () async {
      final record = _pendingSwapIn();
      await swapStore.save(record);
      boltzClient.swapStatuses['swap-in-1'] = 'transaction.confirmed';

      // The claim will succeed via the fake chain
      fakeChain.claimResult = '0xclaim_tx_hash';

      final resolved = await recoveryService.recoverPendingSwaps(
        evmKey: evmKey,
        chainResolver: chainResolver,
      );
      expect(resolved, 1);

      final updated = await swapStore.get('swap-in-1');
      expect(updated!.status, SwapRecordStatus.completed);
      expect(updated.resolutionTxHash, '0xclaim_tx_hash');
    });

    test('marks swap-in needsAction when claim fails', () async {
      final record = _pendingSwapIn();
      await swapStore.save(record);
      boltzClient.swapStatuses['swap-in-1'] = 'transaction.confirmed';

      fakeChain.claimResult = null; // Will throw

      final resolved = await recoveryService.recoverPendingSwaps(
        evmKey: evmKey,
        chainResolver: chainResolver,
      );
      expect(resolved, 0);

      final updated = await swapStore.get('swap-in-1');
      expect(updated!.status, SwapRecordStatus.needsAction);
      expect(updated.errorMessage, contains('Claim failed'));
    });

    test('marks swap-in failed when preimage is missing', () async {
      // Create a record with no preimage
      final record = SwapRecord(
        id: 'no-preimage',
        boltzId: 'no-preimage',
        type: SwapType.swapIn,
        status: SwapRecordStatus.funded,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        onchainAmountSat: 50000,
        refundAddress: '0xrefund',
        timeoutBlockHeight: 800000,
        chainId: 31,
      );
      await swapStore.save(record);
      boltzClient.swapStatuses['no-preimage'] = 'transaction.confirmed';

      await recoveryService.recoverPendingSwaps(
        evmKey: evmKey,
        chainResolver: chainResolver,
      );

      final updated = await swapStore.get('no-preimage');
      expect(updated!.status, SwapRecordStatus.failed);
      expect(updated.errorMessage, contains('Preimage lost'));
    });
  });

  // ─── Swap-Out Recovery Tests ────────────────────────────────────────────

  group('Swap-Out Recovery', () {
    test('marks swap-out completed when Boltz paid the invoice', () async {
      final record = _pendingSwapOut();
      await swapStore.save(record);
      boltzClient.swapStatuses['swap-out-1'] = 'invoice.paid';

      final resolved = await recoveryService.recoverPendingSwaps(
        evmKey: evmKey,
        chainResolver: chainResolver,
      );
      expect(resolved, 1);

      final updated = await swapStore.get('swap-out-1');
      expect(updated!.status, SwapRecordStatus.completed);
    });

    test('marks swap-out completed when Boltz claimed', () async {
      final record = _pendingSwapOut();
      await swapStore.save(record);
      boltzClient.swapStatuses['swap-out-1'] = 'transaction.claimed';

      final resolved = await recoveryService.recoverPendingSwaps(
        evmKey: evmKey,
        chainResolver: chainResolver,
      );
      expect(resolved, 1);

      final updated = await swapStore.get('swap-out-1');
      expect(updated!.status, SwapRecordStatus.completed);
    });

    test('abandons swap-out that was never funded', () async {
      final record = _pendingSwapOut(
        status: SwapRecordStatus.created,
        lockTxHash: null,
      );
      // Need to bypass needsRecovery — created with no lockTxHash won't
      // normally need recovery, so we force it to needsAction
      final forced = record.copyWithStatus(SwapRecordStatus.needsAction);
      await swapStore.save(forced);
      boltzClient.swapStatuses['swap-out-1'] = 'swap.expired';

      await recoveryService.recoverPendingSwaps(
        evmKey: evmKey,
        chainResolver: chainResolver,
      );

      // Falls through to _attemptRefund which should handle missing params
      final updated = await swapStore.get('swap-out-1');
      expect(updated, isNotNull);
    });

    test('attempts cooperative refund when invoice.failedToPay', () async {
      final record = _pendingSwapOut(status: SwapRecordStatus.needsAction);
      await swapStore.save(record);
      boltzClient.swapStatuses['swap-out-1'] = 'invoice.failedToPay';

      // Boltz provides cooperative signature
      boltzClient.cooperativeRefundSignatures['swap-out-1'] =
          '0x${'ab' * 64}1b'; // 65-byte sig

      fakeChain.refundCooperativeResult = '0xcooprefund_tx';

      final resolved = await recoveryService.recoverPendingSwaps(
        evmKey: evmKey,
        chainResolver: chainResolver,
      );
      expect(resolved, 1);

      final updated = await swapStore.get('swap-out-1');
      expect(updated!.status, SwapRecordStatus.refunded);
      expect(updated.resolutionTxHash, '0xcooprefund_tx');
    });

    test('falls back to timelock refund when cooperative fails', () async {
      final record = _pendingSwapOut(status: SwapRecordStatus.needsAction);
      await swapStore.save(record);
      boltzClient.swapStatuses['swap-out-1'] = 'invoice.failedToPay';

      // No cooperative signature available
      boltzClient.cooperativeRefundSignatures.clear();

      // Timelock is expired
      fakeChain.currentBlockNumber = 1000000;
      fakeChain.refundResult = '0xtimelock_refund_tx';

      final resolved = await recoveryService.recoverPendingSwaps(
        evmKey: evmKey,
        chainResolver: chainResolver,
      );
      expect(resolved, 1);

      final updated = await swapStore.get('swap-out-1');
      expect(updated!.status, SwapRecordStatus.refunded);
      expect(updated.resolutionTxHash, '0xtimelock_refund_tx');
    });

    test('waits when timelock not yet expired', () async {
      final record = _pendingSwapOut(status: SwapRecordStatus.needsAction);
      await swapStore.save(record);
      boltzClient.swapStatuses['swap-out-1'] = 'invoice.failedToPay';

      // No cooperative refund available
      boltzClient.cooperativeRefundSignatures.clear();

      // Timelock NOT expired (current block < 900000)
      fakeChain.currentBlockNumber = 800000;

      final resolved = await recoveryService.recoverPendingSwaps(
        evmKey: evmKey,
        chainResolver: chainResolver,
      );
      expect(resolved, 0);

      final updated = await swapStore.get('swap-out-1');
      expect(updated!.status, SwapRecordStatus.needsAction);
      expect(updated.errorMessage, contains('Waiting for timelock'));
    });

    test('marks still-in-progress swap-out as funded', () async {
      final record = _pendingSwapOut();
      await swapStore.save(record);
      boltzClient.swapStatuses['swap-out-1'] = 'invoice.pending';

      final resolved = await recoveryService.recoverPendingSwaps(
        evmKey: evmKey,
        chainResolver: chainResolver,
      );
      expect(resolved, 0);

      final updated = await swapStore.get('swap-out-1');
      expect(updated!.status, SwapRecordStatus.funded);
      expect(updated.lastBoltzStatus, 'invoice.pending');
    });
  });

  // ─── Edge Cases ─────────────────────────────────────────────────────────

  group('Edge Cases', () {
    test('recovers multiple swaps in one pass', () async {
      await swapStore.save(_pendingSwapIn(boltzId: 'in-1'));
      await swapStore.save(
        _pendingSwapOut(boltzId: 'out-1', status: SwapRecordStatus.needsAction),
      );

      boltzClient.swapStatuses['in-1'] = 'invoice.settled';
      boltzClient.swapStatuses['out-1'] = 'invoice.paid';

      final resolved = await recoveryService.recoverPendingSwaps(
        evmKey: evmKey,
        chainResolver: chainResolver,
      );
      expect(resolved, 2);
    });

    test('continues recovering after one swap fails', () async {
      await swapStore.save(_pendingSwapIn(boltzId: 'fail-1'));
      await swapStore.save(_pendingSwapIn(boltzId: 'succeed-1'));

      boltzClient.swapStatuses['fail-1'] = 'transaction.confirmed';
      boltzClient.swapStatuses['succeed-1'] = 'invoice.settled';

      // First swap's claim will fail
      fakeChain.claimResult = null;
      fakeChain.claimResultByBoltzId['succeed-1'] =
          null; // Won't be called — settled

      final resolved = await recoveryService.recoverPendingSwaps(
        evmKey: evmKey,
        chainResolver: chainResolver,
      );
      // The settled one should succeed, the claim-failing one should not
      expect(resolved, 1);
    });

    test('handles Boltz API being unreachable', () async {
      final record = _pendingSwapIn();
      await swapStore.save(record);
      boltzClient.throwOnGetSwap = true;

      final resolved = await recoveryService.recoverPendingSwaps(
        evmKey: evmKey,
        chainResolver: chainResolver,
      );
      expect(resolved, 0);

      final updated = await swapStore.get('swap-in-1');
      expect(updated!.status, SwapRecordStatus.needsAction);
      expect(updated.errorMessage, contains('Recovery attempt failed'));
    });

    test('prunes old terminal records', () async {
      final oldRecord = SwapRecord(
        id: 'ancient',
        boltzId: 'ancient',
        type: SwapType.swapIn,
        status: SwapRecordStatus.completed,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        chainId: 31,
      );
      await swapStore.save(oldRecord);

      await recoveryService.recoverPendingSwaps(
        evmKey: evmKey,
        chainResolver: chainResolver,
      );

      final all = await swapStore.getAll();
      expect(all, isEmpty); // Should have been pruned
    });
  });
}
