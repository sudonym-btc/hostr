import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../../../../util/bitcoin_amount.dart';
import '../../supported_escrow_contract/supported_escrow_contract.dart';
import '../onchain_operation.dart';

// ── Escrow fund recovery data ─────────────────────────────────────────────

/// Immutable snapshot of escrow-fund recovery data.
///
/// Created at the start of [EscrowFundOperation.execute] and threaded through
/// every state from [EscrowFundSwapProgress] onward.
class EscrowFundData extends OnchainOperationData {
  final String tradeId;
  final String reservedAmountWeiHex;
  final String sellerEvmAddress;
  final String arbiterEvmAddress;
  final int unlockAt;

  /// The escrow fee as a wei hex string, persisted so the deposit call uses
  /// the same value that was included in the gas estimation calldata.
  final String? escrowFeeWeiHex;

  final String? errorMessage;

  const EscrowFundData({
    required this.tradeId,
    required this.reservedAmountWeiHex,
    required this.sellerEvmAddress,
    required this.arbiterEvmAddress,
    required super.contractAddress,
    required super.chainId,
    required this.unlockAt,
    required super.accountIndex,
    super.gasPriceWei,
    super.gasLimit,
    this.escrowFeeWeiHex,
    super.swapId,
    super.txHash,
    this.errorMessage,
  });

  @override
  String get operationId => tradeId;

  @override
  EscrowFundData copyWithSwapId(String? swapId) => copyWith(swapId: swapId);

  @override
  EscrowFundData copyWithTxHash(String? txHash) => copyWith(txHash: txHash);

  @override
  EscrowFundData copyWithGasEstimate({
    required String gasPriceWei,
    required String gasLimit,
  }) => copyWith(gasPriceWei: gasPriceWei, gasLimit: gasLimit);

  EscrowFundData copyWith({
    String? gasPriceWei,
    String? gasLimit,
    String? escrowFeeWeiHex,
    String? swapId,
    String? txHash,
    String? errorMessage,
  }) => EscrowFundData(
    tradeId: tradeId,
    reservedAmountWeiHex: reservedAmountWeiHex,
    sellerEvmAddress: sellerEvmAddress,
    arbiterEvmAddress: arbiterEvmAddress,
    contractAddress: contractAddress,
    chainId: chainId,
    unlockAt: unlockAt,
    accountIndex: accountIndex,
    gasPriceWei: gasPriceWei ?? this.gasPriceWei,
    gasLimit: gasLimit ?? this.gasLimit,
    escrowFeeWeiHex: escrowFeeWeiHex ?? this.escrowFeeWeiHex,
    swapId: swapId ?? this.swapId,
    txHash: txHash ?? this.txHash,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  /// Reconstruct [ContractFundEscrowParams] for the deposit call.
  ///
  /// If [gasPriceWei] and [gasLimit] were persisted, the returned params
  /// carry the original [GasEstimate] so the deposit uses the exact gas
  /// parameters the swap-in budget was calculated against.
  ContractFundEscrowParams toContractParams(EthPrivateKey ethKey) {
    GasEstimate? estimate;
    if (gasPriceWei != null && gasLimit != null) {
      final price = BigInt.parse(gasPriceWei!);
      final limit = BigInt.parse(gasLimit!);
      estimate = GasEstimate(
        fee: BitcoinAmount.inWei(price * limit),
        gasPrice: EtherAmount.inWei(price),
        gasLimit: limit,
      );
    }
    return ContractFundEscrowParams(
      tradeId: tradeId,
      amount: BitcoinAmount.inWei(
        BigInt.parse(reservedAmountWeiHex, radix: 16),
      ),
      sellerEvmAddress: sellerEvmAddress,
      arbiterEvmAddress: arbiterEvmAddress,
      ethKey: ethKey,
      unlockAt: unlockAt,
      escrowFee: escrowFeeWeiHex != null
          ? BitcoinAmount.inWei(BigInt.parse(escrowFeeWeiHex!, radix: 16))
          : null,
      gasEstimate: estimate,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'tradeId': tradeId,
    'reservedAmountWeiHex': reservedAmountWeiHex,
    'sellerEvmAddress': sellerEvmAddress,
    'arbiterEvmAddress': arbiterEvmAddress,
    ...super.baseToJson(),
    'unlockAt': unlockAt,
    if (escrowFeeWeiHex != null) 'escrowFeeWeiHex': escrowFeeWeiHex,
    if (errorMessage != null) 'errorMessage': errorMessage,
  };

  factory EscrowFundData.fromJson(Map<String, dynamic> json) => EscrowFundData(
    tradeId: json['tradeId'] as String,
    reservedAmountWeiHex: json['reservedAmountWeiHex'] as String,
    sellerEvmAddress: json['sellerEvmAddress'] as String,
    arbiterEvmAddress: json['arbiterEvmAddress'] as String,
    contractAddress: json['contractAddress'] as String,
    chainId: json['chainId'] as int,
    unlockAt: json['unlockAt'] as int,
    accountIndex: json['accountIndex'] as int? ?? 0,
    gasPriceWei: json['gasPriceWei'] as String?,
    gasLimit: json['gasLimit'] as String?,
    escrowFeeWeiHex:
        json['escrowFeeWeiHex'] as String? ??
        (json['escrowFee'] != null
            ? BitcoinAmount.fromInt(
                BitcoinUnit.sat,
                json['escrowFee'] as int,
              ).getInWei.toRadixString(16)
            : null),
    swapId: json['swapId'] as String?,
    txHash: json['txHash'] as String?,
    errorMessage: json['errorMessage'] as String?,
  );

  @override
  String toString() => 'EscrowFundData($tradeId)';
}
