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

import '../../../support/integration_test_harness.dart';

final _deployerKey = EthPrivateKey.fromHex(
  'ac0974bec39a17e36ba4a6b4d238ff944bacb478cbed5efcae784d7bf4f2ff80',
);

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
      expect(completedData.transactionInformation, isNotNull);
      final txHash = _extractTxHash(completedData.transactionInformation!);
      expect(txHash, isNotNull);

      expect(completedData.transactionReceipt, isNotNull);
      final receipt = completedData.transactionReceipt!;
      expect(_extractReceiptTxHash(receipt), equals(txHash));
      expect(_isReceiptSuccessful(receipt), isTrue);

      final claimedTrade = await contract.getTrade(tradeId);
      expect(claimedTrade, isNull);
    },
    timeout: const Timeout(Duration(seconds: 30)),
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
      expect(completedData.transactionInformation, isNotNull);
      final txHash = _extractTxHash(completedData.transactionInformation!);
      expect(txHash, isNotNull);

      expect(completedData.transactionReceipt, isNotNull);
      final receipt = completedData.transactionReceipt!;
      expect(_extractReceiptTxHash(receipt), equals(txHash));
      expect(_isReceiptSuccessful(receipt), isTrue);

      final releasedTrade = await contract.getTrade(tradeId);
      expect(releasedTrade, isNull);
    },
    timeout: const Timeout(Duration(seconds: 30)),
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

  final amount = configuredChain.resolveAmountInFundingToken(
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
      amount: amount.value,
      unlockAt: BigInt.from(
        trade.negotiateReservation.end.millisecondsSinceEpoch ~/ 1000,
      ),
      escrowFee: feeValue,
    ),
    credentials: _deployerKey,
    transaction: Transaction(value: amount.toEtherAmount()),
  );

  final receipt = await _waitForReceipt(configuredChain.client, txHash);
  expect(_isReceiptSuccessful(receipt), isTrue);
}

Future<TransactionReceipt> _waitForReceipt(
  Web3Client web3,
  String txHash,
) async {
  for (var i = 0; i < 30; i++) {
    final receipt = await web3.getTransactionReceipt(txHash);
    if (receipt != null) return receipt;
    await Future<void>.delayed(const Duration(milliseconds: 250));
  }
  fail('Timed out waiting for transaction receipt: $txHash');
}

String? _extractTxHash(TransactionInformation tx) {
  final dynamic d = tx;
  final hash = d.hash?.toString() ?? d.id?.toString();
  if (hash == null || hash.isEmpty) return null;
  return hash;
}

String? _extractReceiptTxHash(TransactionReceipt receipt) {
  final dynamic hash = (receipt as dynamic).transactionHash;
  if (hash == null) return null;
  if (hash is String) return hash;
  if (hash is List<int>) return bytesToHex(hash, include0x: true);
  final normalized = hash.toString();
  if (normalized.isEmpty) return null;
  return normalized;
}

bool _isReceiptSuccessful(TransactionReceipt receipt) {
  final dynamic status = (receipt as dynamic).status;
  if (status == null) return true;
  if (status is bool) return status;
  if (status is int) return status == 1;
  if (status is BigInt) return status == BigInt.one;
  final normalized = status.toString().toLowerCase();
  return normalized == '1' || normalized == '0x1' || normalized == 'true';
}
