import '../onchain_operation.dart';

// ── Escrow claim recovery data ────────────────────────────────────────────

class EscrowClaimData extends OnchainOperationData {
  final String tradeId;
  final String? errorMessage;

  const EscrowClaimData({
    required this.tradeId,
    required super.contractAddress,
    required super.chainId,
    required super.accountIndex,
    super.gasPriceWei,
    super.gasLimit,
    super.swapId,
    super.txHash,
    this.errorMessage,
  });

  @override
  String get operationId => tradeId;

  @override
  EscrowClaimData copyWithSwapId(String? swapId) => copyWith(swapId: swapId);

  @override
  EscrowClaimData copyWithTxHash(String? txHash) => copyWith(txHash: txHash);

  @override
  EscrowClaimData copyWithGasEstimate({
    required String gasPriceWei,
    required String gasLimit,
  }) => copyWith(gasPriceWei: gasPriceWei, gasLimit: gasLimit);

  EscrowClaimData copyWith({
    String? gasPriceWei,
    String? gasLimit,
    String? swapId,
    String? txHash,
    String? errorMessage,
  }) => EscrowClaimData(
    tradeId: tradeId,
    contractAddress: contractAddress,
    chainId: chainId,
    accountIndex: accountIndex,
    gasPriceWei: gasPriceWei ?? this.gasPriceWei,
    gasLimit: gasLimit ?? this.gasLimit,
    swapId: swapId ?? this.swapId,
    txHash: txHash ?? this.txHash,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  @override
  Map<String, dynamic> toJson() => {
    'tradeId': tradeId,
    ...super.baseToJson(),
    if (errorMessage != null) 'errorMessage': errorMessage,
  };

  factory EscrowClaimData.fromJson(Map<String, dynamic> json) =>
      EscrowClaimData(
        tradeId: json['tradeId'] as String,
        contractAddress: json['contractAddress'] as String,
        chainId: json['chainId'] as int,
        accountIndex: json['accountIndex'] as int? ?? 0,
        gasPriceWei: json['gasPriceWei'] as String?,
        gasLimit: json['gasLimit'] as String?,
        swapId: json['swapId'] as String?,
        txHash: json['txHash'] as String?,
        errorMessage: json['errorMessage'] as String?,
      );

  @override
  String toString() => 'EscrowClaimData($tradeId)';
}
