import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
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

  Future<void> ensureDeployed() async {
    final code = await contract.client.getCode(contract.self.address);
    if (code.isEmpty) {
      throw StateError(
        'Escrow contract not deployed at ${contract.self.address}. '
        'This address appears to be an EOA or empty address. '
        'Funding can succeed with no logs in that case because no contract code executes.',
      );
    }
  }

  Future<BitcoinAmount> estimateDespositFee(ContractFundEscrowParams params);
  Future<BitcoinAmount> estimateClaimFee(ContractClaimEscrowParams params);
  // Future<BigInt> estimateRefundFee(EscrowParams params);

  depositArgs(ContractFundEscrowParams params);
  Future<TransactionInformation> deposit(ContractFundEscrowParams params);
  Future<bool> canClaim(ContractClaimEscrowParams params);
  Future<TransactionInformation> claim(ContractClaimEscrowParams params);
  // Future<TransactionInformation> refund(ContractFundEscrowParams params);

  StreamWithStatus<EscrowEvent> allEvents(
    ContractEventsParams params,
    EscrowServiceSelected? selectedEscrow,
  );

  arbitrateArgs(ContractArbitrateParams params);
  arbitrate(ContractArbitrateParams params);
  listTrades(ContractListTradesParams params);
}

class SupportedEscrowContractFactory {
  static SupportedEscrowContract? getSupportedContract({
    required String bytecodeHash,
  }) {
    return null;
  }
}

class ContractEventsParams {
  final String? tradeId;
  final EthereumAddress? buyerEvmAddress;
  final EthereumAddress? sellerEvmAddress;
  final EthereumAddress? arbiterEvmAddress;

  ContractEventsParams({
    this.tradeId,
    this.buyerEvmAddress,
    this.sellerEvmAddress,
    this.arbiterEvmAddress,
  });
}

class ContractArbitrateParams {
  final String tradeId;
  final double forward;
  final EthPrivateKey ethKey;

  ContractArbitrateParams({
    required this.tradeId,
    required this.forward,
    required this.ethKey,
  });
}

class ContractListTradesParams {
  final String? buyerEvmAddress;
  final String? sellerEvmAddress;
  final String? arbiterEvmAddress;

  ContractListTradesParams({
    this.buyerEvmAddress,
    this.sellerEvmAddress,
    this.arbiterEvmAddress,
  });
}

class ContractFundEscrowParams {
  final String tradeId;
  final BitcoinAmount amount;
  final String sellerEvmAddress;
  final String arbiterEvmAddress;
  final EthPrivateKey ethKey;
  final int unlockAt;
  final int? escrowFee;

  ContractFundEscrowParams({
    required this.tradeId,
    required this.amount,
    required this.sellerEvmAddress,
    required this.arbiterEvmAddress,
    required this.ethKey,
    required this.unlockAt,
    this.escrowFee,
  });
}

class ContractClaimEscrowParams {
  final String tradeId;
  final EthPrivateKey ethKey;

  ContractClaimEscrowParams({required this.tradeId, required this.ethKey});
}

abstract class PaymentEvent {}

class PaymentFundedEvent extends PaymentEvent {
  final BitcoinAmount amount;
  PaymentFundedEvent({required this.amount});
}

class PaymentReleasedEvent extends PaymentEvent {}

class PaymentArbitratedEvent extends PaymentEvent {}

class PaymentClaimedEvent extends PaymentEvent {}

/// Zap payment types
abstract interface class ZapEvent implements PaymentEvent {}

class ZapFundedEvent extends PaymentFundedEvent implements ZapEvent {
  final Nip01EventModel event;
  final ZapReceipt zapReceipt;

  ZapFundedEvent({
    required this.zapReceipt,
    required super.amount,
    required this.event,
  });
}

class ZapReleasedEvent extends PaymentReleasedEvent implements ZapEvent {
  final ZapReceipt zapReceipt;
  final BitcoinAmount amount;
  ZapReleasedEvent({required this.zapReceipt, required this.amount});
}

/// Escrow payment types
abstract class EscrowEvent extends PaymentEvent {
  final EscrowServiceSelected? escrowService;
  final BlockInformation block;
  EscrowEvent({required this.block, this.escrowService});
}

class UnknownEscrowEvent extends EscrowEvent {
  UnknownEscrowEvent({required super.block, super.escrowService});
}

class EscrowFundedEvent extends EscrowEvent implements PaymentFundedEvent {
  final String tradeId;
  final String transactionHash;
  @override
  final BitcoinAmount amount;

  EscrowFundedEvent({
    required this.tradeId,
    required super.block,
    super.escrowService,
    required this.transactionHash,
    required this.amount,
  });
}

class EscrowReleasedEvent extends EscrowEvent implements PaymentReleasedEvent {
  final String transactionHash;

  EscrowReleasedEvent({
    required super.block,
    super.escrowService,
    required this.transactionHash,
  });
}

class EscrowArbitratedEvent extends EscrowEvent
    implements PaymentArbitratedEvent {
  final String transactionHash;
  final double forwarded;
  EscrowArbitratedEvent({
    required super.block,
    super.escrowService,
    required this.transactionHash,
    required this.forwarded,
  });
}

class EscrowClaimedEvent extends EscrowEvent implements PaymentClaimedEvent {
  final String transactionHash;
  EscrowClaimedEvent({
    required super.block,
    super.escrowService,
    required this.transactionHash,
  });
}
