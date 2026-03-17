import 'dart:typed_data';

import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../../../util/main.dart';
import '../../evm/chain/rootstock/rif_relay/rif_relay.dart';
import '../../evm/contract_call_intent.dart';

export '../../evm/contract_call_intent.dart';

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

class FundArgs {
  final String tradeId;
  final BitcoinAmount amount;
  final String sellerEvmAddress;
  final String arbiterEvmAddress;
  final int unlockAt;
  final BitcoinAmount? escrowFee;
  final EthPrivateKey ethKey;
  final GasEstimate? gasEstimate;

  const FundArgs({
    required this.tradeId,
    required this.amount,
    required this.sellerEvmAddress,
    required this.arbiterEvmAddress,
    required this.unlockAt,
    this.escrowFee,
    required this.ethKey,
    this.gasEstimate,
  });
}

class ClaimSwapAndFundArgs {
  final EthereumAddress swapContract;
  final ClaimArgs claimArgs;
  final FundArgs fundArgs;

  const ClaimSwapAndFundArgs({
    required this.swapContract,
    required this.claimArgs,
    required this.fundArgs,
  });
}

class ReleaseArgs {
  final String tradeId;
  final EthPrivateKey ethKey;

  const ReleaseArgs({required this.tradeId, required this.ethKey});
}

typedef AuthorizationHashFn =
    Future<Uint8List> Function(
      ({Uint8List tradeId, dynamic relayFeeQuote}) args,
    );

abstract class SupportedEscrowContract<Contract extends GeneratedContract> {
  static final EthereumAddress _zeroAddress = EthereumAddress.fromHex(
    '0x0000000000000000000000000000000000000000',
  );
  static final List<dynamic> zeroedRelayFeeQuote = [
    _zeroAddress,
    BigInt.zero,
    BigInt.zero,
  ];

  final Contract contract;
  final Web3Client client;
  final EthereumAddress address;
  final RifRelay? rifRelay;
  final bool supportsClaimSwapAndFund;

  SupportedEscrowContract({
    required this.contract,
    required this.client,
    required this.address,
    this.rifRelay,
    this.supportsClaimSwapAndFund = false,
  });

  /// Public API
  Future<GasEstimate> estimateEscrowFundFee(FundArgs args) =>
      estimateFee(fund(args), stateOverrideBalance: args.amount.getInWei);

  Future<GasEstimate> estimateClaimFee({
    required String tradeId,
    required EthPrivateKey ethKey,
  }) => estimateFee(claim(tradeId: tradeId, ethKey: ethKey));

  Future<GasEstimate> estimateReleaseFee(ReleaseArgs args) =>
      estimateFee(release(args));

  Future<bool> canClaim({required String tradeId});
  Future<bool> canRelease(ReleaseArgs args);

  ContractCallIntent fund(FundArgs args);
  Future<ContractCallIntent> fundRelayed(FundArgs args) async => fund(args);
  ContractCallIntent claim({
    required String tradeId,
    required EthPrivateKey ethKey,
  });
  Future<ContractCallIntent> claimRelayed({
    required String tradeId,
    required EthPrivateKey ethKey,
  }) async => claim(tradeId: tradeId, ethKey: ethKey);
  ContractCallIntent claimSwapAndFund(ClaimSwapAndFundArgs args);
  Future<ContractCallIntent> claimSwapAndFundRelayed(
    ClaimSwapAndFundArgs args,
  ) async => claimSwapAndFund(args);
  ContractCallIntent release(ReleaseArgs args);
  Future<ContractCallIntent> releaseRelayed(ReleaseArgs args) async =>
      release(args);
  ContractCallIntent arbitrate({
    required String tradeId,
    required double forward,
    required EthPrivateKey ethKey,
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

  List<dynamic> relayFeeQuote({BigInt? deadline}) => [
    _zeroAddress,
    BigInt.zero,
    deadline ?? BigInt.zero,
  ];

  Uint8List packSignature(Uint8List hash, EthPrivateKey key) {
    final sig = sign(hash, key.privateKey);
    final r = padUint8ListTo32(unsignedIntToBytes(sig.r));
    final s = padUint8ListTo32(unsignedIntToBytes(sig.s));
    final v = Uint8List.fromList([sig.v]);

    final packedSignature = Uint8List(65);
    packedSignature.setRange(0, 32, r);
    packedSignature.setRange(32, 64, s);
    packedSignature.setRange(64, 65, v);
    return packedSignature;
  }

  Future<GasEstimate> estimateFee(
    ContractCallIntent intent, {
    BigInt? stateOverrideBalance,
  }) async {
    final gasPrice = await contract.client.getGasPrice();

    try {
      final call = <String, dynamic>{
        if (intent.from != null) 'from': intent.from!.eip55With0x,
        'to': contract.self.address.eip55With0x,
        'data': bytesToHex(intent.data, include0x: true),
        'value': '0x${intent.value.getInWei.toRadixString(16)}',
      };
      final rpcArgs = <dynamic>[call, 'latest'];

      if (stateOverrideBalance != null && intent.from != null) {
        rpcArgs.add({
          intent.from!.eip55With0x: {
            'balance': '0x${stateOverrideBalance.toRadixString(16)}',
          },
        });
      }

      final gasHex = await client.makeRPCCall<String>(
        'eth_estimateGas',
        rpcArgs,
      );
      final gasLimit = BigInt.parse(gasHex.substring(2), radix: 16);
      return GasEstimate(
        fee: BitcoinAmount.inWei(gasPrice.getInWei * gasLimit),
        gasPrice: gasPrice,
        gasLimit: gasLimit,
      );
    } catch (_) {
      final gasLimit = BigInt.from(intent.maxGas ?? 200000);
      return GasEstimate(
        fee: BitcoinAmount.inWei(gasPrice.getInWei * gasLimit),
        gasPrice: gasPrice,
        gasLimit: gasLimit,
      );
    }
  }

  Future<GasEstimate> estimateRelayFee(
    ContractCallIntent intent,
    EthPrivateKey ethKey,
  ) async {
    final relay = rifRelay;
    if (relay == null) {
      return estimateFee(intent);
    }

    try {
      final estimate = await relay.estimateRelayCall(ethKey, intent);
      final gasLimit =
          BigInt.tryParse(estimate.estimation ?? '') ??
          BigInt.from(intent.maxGas ?? 200000);
      final gasPriceWei =
          BigInt.tryParse(estimate.gasPrice ?? '') ?? BigInt.zero;
      final relayFeeWei =
          BigInt.tryParse(estimate.requiredTokenAmount ?? '') ?? BigInt.zero;

      return GasEstimate(
        fee: BitcoinAmount.inWei(relayFeeWei),
        gasPrice: EtherAmount.inWei(gasPriceWei),
        gasLimit: gasLimit,
      );
    } catch (_) {
      return estimateFee(intent);
    }
  }

  ContractCallIntent buildIntent({
    required String functionName,
    required List<dynamic> args,
    required EthereumAddress from,
    required String methodName,
    EtherAmount? value,
    EtherAmount? gasPrice,
    int? maxGas,
  }) {
    final function = contract.self.abi.functions.firstWhere(
      (f) => f.name == functionName && f.parameters.length == args.length,
    );
    final data = function.encodeCall(args);
    return ContractCallIntent(
      to: contract.self.address,
      data: data,
      value: value ?? EtherAmount.zero(),
      gasPrice: gasPrice,
      maxGas: maxGas,
      from: from,
      methodName: methodName,
    );
  }

  Future<ContractCallIntent> buildAuthorizedRelayIntent({
    required Uint8List tradeId,
    required EthPrivateKey ethKey,
    required AuthorizationHashFn authorizationHashFn,
    required String functionName,
    required String methodName,
  }) async {
    final feeQuote = relayFeeQuote(
      deadline: BigInt.from(
        DateTime.now()
                .toUtc()
                .add(const Duration(minutes: 10))
                .millisecondsSinceEpoch ~/
            1000,
      ),
    );

    final authorizationHash = await authorizationHashFn((
      tradeId: tradeId,
      relayFeeQuote: feeQuote,
    ));
    final packedSignature = packSignature(authorizationHash, ethKey);

    return buildIntent(
      functionName: functionName,
      args: [tradeId, feeQuote, packedSignature],
      from: ethKey.address,
      methodName: methodName,
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
  final BitcoinAmount amount;
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
  final BitcoinAmount amount;
  ZapReleasedEvent({
    required super.tradeId,
    required this.zapReceipt,
    required this.amount,
  });
}

/// Escrow payment types
sealed class EscrowEvent extends PaymentEvent {
  final EscrowServiceSelected? escrowService;
  final BlockInformation block;
  EscrowEvent({
    required super.tradeId,
    required this.block,
    this.escrowService,
  });
}

class UnknownEscrowEvent extends EscrowEvent {
  UnknownEscrowEvent({
    required super.tradeId,
    required super.block,
    super.escrowService,
  });
}

class EscrowFundedEvent extends EscrowEvent implements PaymentFundedEvent {
  final String transactionHash;
  @override
  final BitcoinAmount amount;

  /// The unix timestamp (seconds) after which the buyer can claim back funds.
  final int unlockAt;

  EscrowFundedEvent({
    required super.tradeId,
    required super.block,
    super.escrowService,
    required this.transactionHash,
    required this.amount,
    required this.unlockAt,
  });
}

class EscrowReleasedEvent extends EscrowEvent implements PaymentReleasedEvent {
  final String transactionHash;

  EscrowReleasedEvent({
    required super.tradeId,
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
    required super.tradeId,
    required super.block,
    super.escrowService,
    required this.transactionHash,
    required this.forwarded,
  });
}

class EscrowClaimedEvent extends EscrowEvent implements PaymentClaimedEvent {
  final String transactionHash;
  EscrowClaimedEvent({
    required super.tradeId,
    required super.block,
    super.escrowService,
    required this.transactionHash,
  });
}
