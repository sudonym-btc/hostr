@Tags(['integration', 'docker'])
library;

import 'package:hostr_sdk/config/generated/test_env.g.dart' as env;
import 'package:hostr_sdk/datasources/contracts/escrow/MultiEscrow.g.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/seed/seed.dart';
import 'package:hostr_sdk/usecase/payments/constants.dart';
import 'package:hostr_sdk/util/deterministic_key_derivation.dart';
import 'package:logger/logger.dart';
import 'package:models/main.dart';
import 'package:test/test.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';

import '../../../support/evm_test_helpers.dart';
import '../../../support/integration_test_harness.dart';

void main() {
  late IntegrationTestHarness harness;

  setUp(() async {
    harness = await IntegrationTestHarness.create(
      name: 'hostr_escrow_claim_release_it',
      seed: DateTime.now().microsecondsSinceEpoch,
      logLevel: Level.debug,
      cleanHydratedStorage: true,
    );
  });

  tearDownAll(() {
    IntegrationTestHarness.resetLogLevel();
  });

  tearDown(() async {
    await harness.dispose();
  });

  test(
    'escrow claim emits expected state flow and confirms transaction for unlockable trade',
    () async {
      final hostr = harness.hostr;
      final trade = await harness.seeds.freshTrade(
        hostHasEvm: true,
        now: DateTime.now().toUtc().subtract(const Duration(days: 400)),
      );
      await hostr.auth.signin(trade.guest.privateKey);

      final escrowService = await _resolveEscrowService(harness);
      final tradeId = trade.negotiateReservation.getDtag()!;
      await _fundTradeWithoutSwap(
        harness: harness,
        hostr: hostr,
        trade: trade,
        escrowService: escrowService,
      );

      await hostr.auth.signin(trade.host.privateKey);

      final contract = hostr.evm
          .getChainForEscrowService(escrowService)
          .escrow
          .getSupportedEscrowContract(escrowService);
      final fundedTrade = await contract.getTrade(tradeId);
      expect(fundedTrade, isNotNull);
      expect(fundedTrade!.isActive, isTrue);
      expect(
        DateTime.now().millisecondsSinceEpoch ~/ 1000 >
            fundedTrade.unlockAt.toInt(),
        isTrue,
        reason: 'Expected funded trade to already be unlockable',
      );

      final operation = hostr.escrow.claim(
        EscrowClaimParams(escrowService: escrowService, tradeId: tradeId),
      );

      final emittedStates = <OnchainOperationState>[operation.state];
      final sub = operation.stream.listen(emittedStates.add);

      await operation.execute();
      emittedStates.add(operation.state);
      await sub.cancel();

      expect(emittedStates.first, isA<OnchainInitialised>());
      expect(operation.state, isA<OnchainTxConfirmed>());
      expect(emittedStates.whereType<OnchainTxConfirmed>(), isNotEmpty);

      final completed = operation.state as OnchainTxConfirmed;
      final completedData = completed.data;
      final txHash = completedData.txHash;
      expect(txHash, isNotNull);

      expect(completedData.transactionReceipt, isNotNull);
      final receipt = completedData.transactionReceipt!;
      expect(extractReceiptTxHash(receipt), equals(txHash));
      expect(isReceiptSuccessful(receipt), isTrue);

      final claimedTrade = await contract.getTrade(tradeId);
      expect(claimedTrade, isNull);
    },
  );

  test(
    'escrow release emits expected state flow and confirms transaction',
    () async {
      final hostr = harness.hostr;
      final trade = await harness.seeds.freshTrade(hostHasEvm: true);
      await hostr.auth.signin(trade.guest.privateKey);

      final escrowService = await _resolveEscrowService(harness);
      final tradeId = trade.negotiateReservation.getDtag()!;
      await _fundTradeWithoutSwap(
        harness: harness,
        hostr: hostr,
        trade: trade,
        escrowService: escrowService,
      );

      final contract = hostr.evm
          .getChainForEscrowService(escrowService)
          .escrow
          .getSupportedEscrowContract(escrowService);
      final fundedTrade = await contract.getTrade(tradeId);
      expect(fundedTrade, isNotNull);
      expect(fundedTrade!.isActive, isTrue);

      final operation = hostr.escrow.release(
        EscrowReleaseParams(escrowService: escrowService, tradeId: tradeId),
      );

      final emittedStates = <OnchainOperationState>[operation.state];
      final sub = operation.stream.listen(emittedStates.add);

      await operation.execute();
      emittedStates.add(operation.state);
      await sub.cancel();

      expect(emittedStates.first, isA<OnchainInitialised>());
      expect(operation.state, isA<OnchainTxConfirmed>());
      expect(emittedStates.whereType<OnchainTxConfirmed>(), isNotEmpty);

      final completed = operation.state as OnchainTxConfirmed;
      final completedData = completed.data;
      final txHash = completedData.txHash;
      expect(txHash, isNotNull);

      expect(completedData.transactionReceipt, isNotNull);
      final receipt = completedData.transactionReceipt!;
      expect(extractReceiptTxHash(receipt), equals(txHash));
      expect(isReceiptSuccessful(receipt), isTrue);

      final releasedTrade = await contract.getTrade(tradeId);
      expect(releasedTrade, isNull);
    },
  );
}

Future<EscrowService> _resolveEscrowService(
  IntegrationTestHarness harness,
) async {
  return (await harness.seeds.factory.buildEscrowServices(
    contractAddress: env.evmConfig.chains.first.escrowContractAddress!,
  )).first;
}

Future<void> _fundTradeWithoutSwap({
  required IntegrationTestHarness harness,
  required Hostr hostr,
  required TestTrade trade,
  required EscrowService escrowService,
}) async {
  final configuredChain = hostr.evm.getChainForEscrowService(escrowService);
  final contract = configuredChain.escrow.getSupportedEscrowContract(
    escrowService,
  );

  final amount = await configuredChain.resolveAmountInFundingToken(
    trade.negotiateReservation.amount!,
  );
  const zeroAddress = '0x0000000000000000000000000000000000000000';
  final feeValue = escrowService.escrowFee(
    amount.value,
    tokenAddress: 'native',
  );
  final multiEscrow = MultiEscrow(
    address: contract.address,
    client: configuredChain.client,
  );
  final buyerAddress = (await deriveEvmKey(trade.guest.privateKey)).address;
  final sellerAddress = (await deriveEvmKey(trade.host.privateKey)).address;

  final txHash = await multiEscrow.createTrade(
    (
      tradeId: getBytes32(trade.negotiateReservation.getDtag()!),
      buyer: buyerAddress,
      seller: sellerAddress,
      arbiter: EthereumAddress.fromHex(escrowService.evmAddress),
      token: EthereumAddress.fromHex(zeroAddress),
      paymentAmount: amount.value,
      bondAmount: BigInt.zero,
      unlockAt: BigInt.from(
        trade.negotiateReservation.end!.millisecondsSinceEpoch ~/ 1000,
      ),
      escrowFee: feeValue,
    ),
    credentials: anvilDeployerKey,
    transaction: Transaction(value: amount.toEtherAmount()),
  );

  final receipt = await waitForReceipt(configuredChain.client, txHash);
  expect(isReceiptSuccessful(receipt), isTrue);
}
