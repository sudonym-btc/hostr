import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../../../util/main.dart';

abstract class SupportedEscrowContract<Contract extends GeneratedContract> {
  final Contract contract;
  final Web3Client client;
  final EthereumAddress address;

  SupportedEscrowContract({
    required this.contract,
    required this.client,
    required this.address,
  });

  Future<BitcoinAmount> estimateDespositFee(ContractFundEscrowParams params);
  // Future<BigInt> estimateRefundFee(EscrowParams params);

  depositArgs(ContractFundEscrowParams params);
  Future<TransactionInformation> deposit(ContractFundEscrowParams params);
  // Future<TransactionInformation> refund(ContractFundEscrowParams params);

  StreamWithStatus<EscrowEvent> allEvents(String tradeId);
}

class SupportedEscrowContractFactory {
  static SupportedEscrowContract? getSupportedContract({
    required String bytecodeHash,
  }) {
    return null;
  }
}

class ContractFundEscrowParams {
  final String tradeId;
  final BitcoinAmount amount;
  final String sellerEvmAddress;
  final String arbiterEvmAddress;
  final EthPrivateKey ethKey;
  final int timelock;
  final int? escrowFee;

  ContractFundEscrowParams({
    required this.tradeId,
    required this.amount,
    required this.sellerEvmAddress,
    required this.arbiterEvmAddress,
    required this.ethKey,
    required this.timelock,
    this.escrowFee,
  });
}

class EscrowEvent {}

class FundedEvent extends EscrowEvent {
  final String transactionHash;
  final BitcoinAmount amount;

  FundedEvent({required this.transactionHash, required this.amount});
}

class ReleasedEvent extends EscrowEvent {
  final String transactionHash;

  ReleasedEvent({required this.transactionHash});
}

class ArbitratedEvent extends EscrowEvent {
  final String transactionHash;
  final double forwarded;
  ArbitratedEvent({required this.transactionHash, required this.forwarded});
}

class ClaimedEvent extends EscrowEvent {
  final String transactionHash;
  ClaimedEvent({required this.transactionHash});
}
