import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../../../util/main.dart';

/// On-chain trade data returned by [SupportedEscrowContract.getTrade].
class OnChainTrade {
  final bool isActive;
  final EthereumAddress buyer;
  final EthereumAddress seller;
  final EthereumAddress arbiter;

  /// The escrowed amount in wei.
  final BigInt amount;
  final BigInt unlockAt;
  final BigInt escrowFee;

  OnChainTrade({
    required this.isActive,
    required this.buyer,
    required this.seller,
    required this.arbiter,
    required this.amount,
    required this.unlockAt,
    required this.escrowFee,
  });

  @override
  String toString() =>
      'OnChainTrade(active=$isActive, amount=$amount, buyer=$buyer, seller=$seller, arbiter=$arbiter)';
}

/// Gas parameters captured at estimation time.
///
/// Pinning these values ensures the actual transaction uses the exact gas
/// price and limit that the fee budget was calculated with — eliminating
/// variance from gas-price drift between estimation and broadcast.
class GasEstimate {
  final BitcoinAmount fee;
  final EtherAmount gasPrice;
  final BigInt gasLimit;

  const GasEstimate({
    required this.fee,
    required this.gasPrice,
    required this.gasLimit,
  });

  @override
  String toString() =>
      'GasEstimate(fee=${fee.getInSats} sats, '
      'gasPrice=${gasPrice.getInWei}, gasLimit=$gasLimit)';
}

abstract class SupportedEscrowContract<Contract extends GeneratedContract> {
  final Contract contract;
  final Web3Client client;
  final EthereumAddress address;

  SupportedEscrowContract({
    required this.contract,
    required this.client,
    required this.address,
  });

  /// Read the on-chain trade for [tradeId].
  ///
  /// Returns `null` if the trade does not exist or is not active.
  Future<OnChainTrade?> getTrade(String tradeId);

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

  Future<GasEstimate> estimateEscrowFundFee(ContractFundEscrowParams params);
  Future<GasEstimate> estimateClaimFee(ContractClaimEscrowParams params);
  Future<GasEstimate> estimateReleaseFee(ContractReleaseEscrowParams params);

  Future<bool> canClaim(ContractClaimEscrowParams params);
  Future<bool> canRelease(ContractReleaseEscrowParams params);

  depositArgs(ContractFundEscrowParams params);
  Future<TransactionInformation> deposit(ContractFundEscrowParams params);
  Future<TransactionInformation> claim(ContractClaimEscrowParams params);
  Future<TransactionInformation> release(ContractReleaseEscrowParams params);

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

  @override
  String toString() =>
      'ContractEventsParams(tradeId=$tradeId, buyer=$buyerEvmAddress, '
      'seller=$sellerEvmAddress, arbiter=$arbiterEvmAddress)';
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

  /// Flat escrow fee. Stored as a [BitcoinAmount] so it can be losslessly
  /// converted to wei when encoding the on-chain `createTrade` call.
  final BitcoinAmount? escrowFee;

  /// Gas parameters pinned at estimation time. When set, the deposit
  /// transaction uses these exact values instead of re-querying the node.
  final GasEstimate? gasEstimate;

  ContractFundEscrowParams({
    required this.tradeId,
    required this.amount,
    required this.sellerEvmAddress,
    required this.arbiterEvmAddress,
    required this.ethKey,
    required this.unlockAt,
    this.escrowFee,
    this.gasEstimate,
  });

  /// Returns a copy with pinned [gasEstimate].
  ContractFundEscrowParams withGasEstimate(GasEstimate estimate) {
    return ContractFundEscrowParams(
      tradeId: tradeId,
      amount: amount,
      sellerEvmAddress: sellerEvmAddress,
      arbiterEvmAddress: arbiterEvmAddress,
      ethKey: ethKey,
      unlockAt: unlockAt,
      escrowFee: escrowFee,
      gasEstimate: estimate,
    );
  }
}

class ContractClaimEscrowParams {
  final String tradeId;
  final EthPrivateKey ethKey;

  ContractClaimEscrowParams({required this.tradeId, required this.ethKey});
}

class ContractReleaseEscrowParams {
  final String tradeId;
  final EthPrivateKey ethKey;

  ContractReleaseEscrowParams({required this.tradeId, required this.ethKey});
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
  final String tradeId;
  final String transactionHash;

  EscrowReleasedEvent({
    required this.tradeId,
    required super.block,
    super.escrowService,
    required this.transactionHash,
  });
}

class EscrowArbitratedEvent extends EscrowEvent
    implements PaymentArbitratedEvent {
  final String tradeId;
  final String transactionHash;
  final double forwarded;
  EscrowArbitratedEvent({
    required this.tradeId,
    required super.block,
    super.escrowService,
    required this.transactionHash,
    required this.forwarded,
  });
}

class EscrowClaimedEvent extends EscrowEvent implements PaymentClaimedEvent {
  final String tradeId;
  final String transactionHash;
  EscrowClaimedEvent({
    required this.tradeId,
    required super.block,
    super.escrowService,
    required this.transactionHash,
  });
}
