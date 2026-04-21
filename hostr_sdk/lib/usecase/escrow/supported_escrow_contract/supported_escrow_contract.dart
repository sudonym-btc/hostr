import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../../../util/main.dart';
import '../../evm/chain/evm_chain.dart';
import '../../evm/evm_call.dart';

export '../../evm/evm_call.dart';

/// On-chain trade data returned by [SupportedEscrowContract.getTrade].
class OnChainTrade {
  final bool isActive;
  final EthereumAddress buyer;
  final EthereumAddress seller;
  final EthereumAddress arbiter;

  /// The ERC-20 token address, or zero-address for native RBTC.
  final EthereumAddress token;

  /// The escrowed payment amount in wei (native) or token smallest-units (ERC-20).
  final BigInt paymentAmount;

  /// The escrowed bond (security deposit) amount. Escrow fee is NOT charged on this.
  final BigInt bondAmount;
  final BigInt unlockAt;
  final BigInt escrowFee;

  OnChainTrade({
    required this.isActive,
    required this.buyer,
    required this.seller,
    required this.arbiter,
    required this.token,
    required this.paymentAmount,
    required this.bondAmount,
    required this.unlockAt,
    required this.escrowFee,
  });

  @override
  String toString() =>
      'OnChainTrade(active=$isActive, payment=$paymentAmount, bond=$bondAmount, buyer=$buyer, seller=$seller, arbiter=$arbiter)';
}

class FundArgs {
  final String tradeId;
  final TokenAmount amount;
  final TokenAmount? bondAmount;
  final String sellerEvmAddress;
  final String arbiterEvmAddress;
  final int unlockAt;
  final TokenAmount? escrowFee;
  final EthPrivateKey ethKey;

  /// The ERC-20 token to fund with.
  /// When `null` or `token.isNative`, the trade is funded with native RBTC.
  final Token? token;

  const FundArgs({
    required this.tradeId,
    required this.amount,
    this.bondAmount,
    required this.sellerEvmAddress,
    required this.arbiterEvmAddress,
    required this.unlockAt,
    this.escrowFee,
    required this.ethKey,
    this.token,
  });
}

class ReleaseArgs {
  final String tradeId;
  final EthPrivateKey ethKey;

  /// The EVM address of the actor performing the release (buyer or seller).
  /// Used as the `actor` parameter in the EIP-712 signed release.
  final EthereumAddress? actor;

  const ReleaseArgs({required this.tradeId, required this.ethKey, this.actor});
}

class WithdrawArgs {
  final EthereumAddress token;
  final EthPrivateKey ethKey;

  /// The address that was awarded funds during settlement (buyer, seller, or
  /// arbiter). Must match a non-zero entry in `balances[beneficiary][token]`.
  final EthereumAddress beneficiary;

  /// Where to send the tokens. Can differ from [beneficiary] — this is what
  /// makes the pull pattern flexible (e.g. withdraw to an exchange address).
  final EthereumAddress destination;

  const WithdrawArgs({
    required this.token,
    required this.ethKey,
    required this.beneficiary,
    required this.destination,
  });
}

abstract class SupportedEscrowContract<Contract extends GeneratedContract> {
  static final EthereumAddress zeroAddress = EthereumAddress.fromHex(
    '0x0000000000000000000000000000000000000000',
  );

  final Contract contract;
  final Web3Client client;
  final EthereumAddress address;

  SupportedEscrowContract({
    required this.contract,
    required this.client,
    required this.address,
  });

  /// Public API
  Future<bool> canClaim({required String tradeId});
  Future<bool> canRelease(ReleaseArgs args);

  Call fund(FundArgs args);
  Call claim({required String tradeId, required EthPrivateKey ethKey});
  Call release(ReleaseArgs args);
  Call arbitrate({
    required String tradeId,
    required double paymentForward,
    required double bondForward,
    required EthPrivateKey ethKey,
  });
  Call withdraw(WithdrawArgs args);

  /// Read the total balance a [beneficiary] can withdraw for a given [token].
  /// Returns `BigInt.zero` if nothing is pending.
  Future<BigInt> balanceOf({
    required EthereumAddress beneficiary,
    required EthereumAddress token,
  });

  /// Read all token balances a [beneficiary] can withdraw.
  ///
  /// Returns a map of token address → amount (wei / smallest-unit).
  /// Only non-zero balances are included.
  Future<Map<EthereumAddress, BigInt>> allBalances({
    required EthereumAddress beneficiary,
  });

  Object decodeWriteError(Object error) => error;

  StreamWithStatus<EscrowEvent> allEvents(
    ContractEventsParams params,
    EscrowServiceSelected? selectedEscrow, {
    bool includeLive = true,
    bool batch = true,
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

  Call buildCall({
    required String functionName,
    required List<dynamic> args,
    BigInt? value,
  }) {
    final function = contract.self.abi.functions.firstWhere(
      (f) => f.name == functionName && f.parameters.length == args.length,
    );
    return callFromEncoded(
      to: contract.self.address,
      data: function.encodeCall(args),
      value: value,
    );
  }
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

abstract class PaymentEvent {
  final String tradeId;

  PaymentEvent({required this.tradeId});
}

class PaymentFundedEvent extends PaymentEvent {
  final TokenAmount amount;
  PaymentFundedEvent({required super.tradeId, required this.amount});
}

class PaymentReleasedEvent extends PaymentEvent {
  PaymentReleasedEvent({required super.tradeId});
}

class PaymentArbitratedEvent extends PaymentEvent {
  PaymentArbitratedEvent({required super.tradeId});
}

class PaymentClaimedEvent extends PaymentEvent {
  PaymentClaimedEvent({required super.tradeId});
}

/// Zap payment types
abstract interface class ZapEvent implements PaymentEvent {}

class ZapFundedEvent extends PaymentFundedEvent implements ZapEvent {
  final Nip01EventModel event;
  final ZapReceipt zapReceipt;

  ZapFundedEvent({
    required super.tradeId,
    required this.zapReceipt,
    required super.amount,
    required this.event,
  });
}

class ZapReleasedEvent extends PaymentReleasedEvent implements ZapEvent {
  final ZapReceipt zapReceipt;
  final TokenAmount amount;
  ZapReleasedEvent({
    required super.tradeId,
    required this.zapReceipt,
    required this.amount,
  });
}

/// Escrow payment types
sealed class EscrowEvent extends PaymentEvent {
  final EscrowServiceSelected? escrowService;
  final int blockNum;
  final BlockInformation? block;

  /// The EVM chain this event was emitted on.
  /// Non-null when the event was sourced from an [EvmChain]-backed escrow.
  final EvmChain? chain;

  /// The escrow contract that emitted this event.
  /// Non-null when the event was sourced from a known [SupportedEscrowContract].
  final SupportedEscrowContract? contract;

  EscrowEvent({
    required super.tradeId,
    required this.blockNum,
    required this.block,
    this.escrowService,
    this.chain,
    this.contract,
  });
}

class UnknownEscrowEvent extends EscrowEvent {
  UnknownEscrowEvent({
    required super.tradeId,
    required super.blockNum,
    required super.block,
    super.escrowService,
    super.chain,
    super.contract,
  });
}

class EscrowFundedEvent extends EscrowEvent implements PaymentFundedEvent {
  final String transactionHash;
  @override
  final TokenAmount amount;

  /// The security-deposit (bond) locked alongside the payment, if any.
  final TokenAmount? bondAmount;

  /// The unix timestamp (seconds) after which the buyer can claim back funds.
  final int unlockAt;

  EscrowFundedEvent({
    required super.tradeId,
    required super.blockNum,
    required super.block,
    super.escrowService,
    super.chain,
    super.contract,
    required this.transactionHash,
    required this.amount,
    this.bondAmount,
    required this.unlockAt,
  });
}

class EscrowReleasedEvent extends EscrowEvent implements PaymentReleasedEvent {
  final String transactionHash;

  EscrowReleasedEvent({
    required super.tradeId,
    required super.blockNum,
    required super.block,
    super.escrowService,
    super.chain,
    super.contract,
    required this.transactionHash,
  });
}

class EscrowArbitratedEvent extends EscrowEvent
    implements PaymentArbitratedEvent {
  final String transactionHash;
  final double paymentForwarded;
  final double bondForwarded;
  EscrowArbitratedEvent({
    required super.tradeId,
    required super.blockNum,
    required super.block,
    super.escrowService,
    super.chain,
    super.contract,
    required this.transactionHash,
    required this.paymentForwarded,
    required this.bondForwarded,
  });
}

class EscrowClaimedEvent extends EscrowEvent implements PaymentClaimedEvent {
  final String transactionHash;
  EscrowClaimedEvent({
    required super.tradeId,
    required super.blockNum,
    required super.block,
    super.escrowService,
    super.chain,
    super.contract,
    required this.transactionHash,
  });
}
