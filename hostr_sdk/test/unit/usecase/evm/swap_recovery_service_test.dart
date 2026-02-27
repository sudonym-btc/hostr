@Tags(['unit'])
library;

import 'package:convert/convert.dart';
import 'package:get_it/get_it.dart';
import 'package:hostr_sdk/datasources/storage.dart';
import 'package:hostr_sdk/mocks/usecase_mocks.mocks.dart';
import 'package:hostr_sdk/usecase/evm/chain/evm_chain.dart';
import 'package:hostr_sdk/usecase/evm/chain/rootstock/operations/swap_in/swap_in_operation.dart';
import 'package:hostr_sdk/usecase/evm/chain/rootstock/operations/swap_out/swap_out_operation.dart';
import 'package:hostr_sdk/usecase/evm/operations/swap_record.dart';
import 'package:hostr_sdk/usecase/evm/operations/swap_recovery_service.dart';
import 'package:hostr_sdk/usecase/evm/operations/swap_store.dart';
import 'package:hostr_sdk/util/custom_logger.dart';
import 'package:mockito/mockito.dart';
import 'package:models/bip340.dart';
import 'package:test/test.dart';
import 'package:web3dart/web3dart.dart' show EthPrivateKey;

import '../../fakes/fake_boltz_client.dart';
import '../../fakes/fake_evm_chain.dart';
import '../../fakes/fake_swap_operations.dart';

void main() {
  late SwapStore swapStore;
  late FakeBoltzClient boltzClient;
  late FakeEvmChain fakeChain;
  late SwapRecoveryService recoveryService;
  late EthPrivateKey evmKey;
  late FakeSwapInOperation fakeSwapInOperation;
  late FakeSwapOutOperation fakeSwapOutOperation;

  setUp(() async {
    await GetIt.instance.reset();

    final mockAuth = MockAuth();
    final fakeUser = Bip340.fromPrivateKey('1' * 64);
    when(mockAuth.activeKeyPair).thenAnswer((_) => fakeUser);

    swapStore = SwapStore(InMemoryKeyValueStorage(), CustomLogger(), mockAuth);
    boltzClient = FakeBoltzClient();
    fakeChain = FakeEvmChain();
    recoveryService = SwapRecoveryService(
      swapStore,
      boltzClient,
      CustomLogger(),
    );

    fakeSwapInOperation = FakeSwapInOperation();
    fakeSwapOutOperation = FakeSwapOutOperation();

    GetIt.instance
        .registerFactoryParam<RootstockSwapInOperation, dynamic, dynamic>(
          (_, __) => fakeSwapInOperation,
        );
    GetIt.instance
        .registerFactoryParam<RootstockSwapOutOperation, dynamic, dynamic>(
          (_, __) => fakeSwapOutOperation,
        );

    evmKey = EthPrivateKey.fromHex(
      'ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80',
    );
  });

  tearDown(() async {
    await GetIt.instance.reset();
  });

  Future<EvmChain> chainResolver(int chainId) async => fakeChain;

  SwapInRecord _pendingSwapIn({
    String boltzId = 'swap-in-1',
    SwapRecordStatus status = SwapRecordStatus.funded,
  }) {
    final preimage = List<int>.generate(32, (i) => i);
    final record = SwapInRecord.create(
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

  SwapOutRecord _pendingSwapOut({
    String boltzId = 'swap-out-1',
    SwapRecordStatus status = SwapRecordStatus.funded,
    String? lockTxHash = '0xlocktx',
  }) {
    final hashBytes = List<int>.generate(32, (i) => i);
    final record = SwapOutRecord.create(
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

  group('SwapRecoveryService orchestration', () {
    test('no pending swaps returns 0 and does not call cubits', () async {
      final resolved = await recoveryService.recoverPendingSwaps(
        evmKey: evmKey,
        chainResolver: chainResolver,
      );

      expect(resolved, 0);
      expect(fakeSwapInOperation.recoverCalls, isEmpty);
      expect(fakeSwapOutOperation.recoverCalls, isEmpty);
    });

    test('delegates swap-in records to swap-in cubit', () async {
      await swapStore.save(_pendingSwapIn(boltzId: 'in-1'));
      boltzClient.swapStatuses['in-1'] = 'transaction.confirmed';

      final resolved = await recoveryService.recoverPendingSwaps(
        evmKey: evmKey,
        chainResolver: chainResolver,
      );

      expect(resolved, 1);
      expect(fakeSwapInOperation.recoverCalls, hasLength(1));
      expect(fakeSwapInOperation.recoverCalls.first.record.boltzId, 'in-1');
      expect(
        fakeSwapInOperation.recoverCalls.first.boltzStatus,
        'transaction.confirmed',
      );
      expect(fakeSwapOutOperation.recoverCalls, isEmpty);
    });

    test('delegates swap-out records to swap-out cubit', () async {
      await swapStore.save(_pendingSwapOut(boltzId: 'out-1'));
      boltzClient.swapStatuses['out-1'] = 'invoice.failedToPay';

      final resolved = await recoveryService.recoverPendingSwaps(
        evmKey: evmKey,
        chainResolver: chainResolver,
      );

      expect(resolved, 1);
      expect(fakeSwapOutOperation.recoverCalls, hasLength(1));
      expect(fakeSwapOutOperation.recoverCalls.first.record.boltzId, 'out-1');
      expect(
        fakeSwapOutOperation.recoverCalls.first.boltzStatus,
        'invoice.failedToPay',
      );
      expect(fakeSwapInOperation.recoverCalls, isEmpty);
    });

    test('counts only successful recoveries', () async {
      await swapStore.save(_pendingSwapIn(boltzId: 'in-1'));
      await swapStore.save(_pendingSwapOut(boltzId: 'out-1'));
      boltzClient.swapStatuses['in-1'] = 'invoice.settled';
      boltzClient.swapStatuses['out-1'] = 'invoice.pending';

      fakeSwapInOperation.recoverResult = true;
      fakeSwapOutOperation.recoverResult = false;

      final resolved = await recoveryService.recoverPendingSwaps(
        evmKey: evmKey,
        chainResolver: chainResolver,
      );

      expect(resolved, 1);
      expect(fakeSwapInOperation.recoverCalls, hasLength(1));
      expect(fakeSwapOutOperation.recoverCalls, hasLength(1));
    });

    test('marks record needsAction when cubit recovery throws', () async {
      await swapStore.save(_pendingSwapIn(boltzId: 'in-1'));
      boltzClient.swapStatuses['in-1'] = 'transaction.confirmed';
      fakeSwapInOperation.recoverError = Exception('boom');

      final resolved = await recoveryService.recoverPendingSwaps(
        evmKey: evmKey,
        chainResolver: chainResolver,
      );

      expect(resolved, 0);
      final updated = await swapStore.get('in-1');
      expect(updated, isNotNull);
      expect(updated!.status, SwapRecordStatus.needsAction);
      expect(updated.errorMessage, contains('Recovery attempt failed'));
    });

    test('continues after one failure and still recovers others', () async {
      await swapStore.save(_pendingSwapIn(boltzId: 'fail-1'));
      await swapStore.save(_pendingSwapOut(boltzId: 'ok-1'));
      boltzClient.swapStatuses['fail-1'] = 'transaction.confirmed';
      boltzClient.swapStatuses['ok-1'] = 'invoice.paid';

      fakeSwapInOperation.recoverError = Exception('claim failed');
      fakeSwapOutOperation.recoverResult = true;

      final resolved = await recoveryService.recoverPendingSwaps(
        evmKey: evmKey,
        chainResolver: chainResolver,
      );

      expect(resolved, 1);
      final failed = await swapStore.get('fail-1');
      expect(failed, isNotNull);
      expect(failed!.status, SwapRecordStatus.needsAction);
    });

    test('handles Boltz API failure by marking needsAction', () async {
      await swapStore.save(_pendingSwapIn(boltzId: 'in-1'));
      boltzClient.throwOnGetSwap = true;

      final resolved = await recoveryService.recoverPendingSwaps(
        evmKey: evmKey,
        chainResolver: chainResolver,
      );

      expect(resolved, 0);
      final updated = await swapStore.get('in-1');
      expect(updated, isNotNull);
      expect(updated!.status, SwapRecordStatus.needsAction);
      expect(updated.errorMessage, contains('Recovery attempt failed'));
    });

    test('prunes old terminal records before recovering', () async {
      final oldRecord = SwapInRecord(
        id: 'ancient',
        boltzId: 'ancient',
        status: SwapRecordStatus.completed,
        createdAt: DateTime(2025, 1, 1),
        updatedAt: DateTime(2025, 1, 1),
        timeoutBlockHeight: 123,
        chainId: 31,
        preimageHex: '00',
        preimageHash: '00',
        onchainAmountSat: 1,
      );
      await swapStore.save(oldRecord);

      await recoveryService.recoverPendingSwaps(
        evmKey: evmKey,
        chainResolver: chainResolver,
      );

      final all = await swapStore.getAll();
      expect(all, isEmpty);
    });
  });
}
