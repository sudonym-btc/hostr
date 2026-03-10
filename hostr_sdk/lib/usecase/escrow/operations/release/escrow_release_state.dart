import 'package:web3dart/web3dart.dart';

import '../onchain_operation.dart';

// ── Escrow release recovery data ──────────────────────────────────────────

class EscrowReleaseData extends OnchainOperationData {
  final String tradeId;
  final String? errorMessage;

  const EscrowReleaseData({
    required this.tradeId,
    required super.contractAddress,
    required super.chainId,
    required super.accountIndex,
    super.gasPriceWei,
    super.gasLimit,
    super.swapId,
    super.txHash,
    super.transactionInformation,
    super.transactionReceipt,
    this.errorMessage,
  });

  @override
  String get operationId => tradeId;

  @override
  EscrowReleaseData copyWithSwapId(String? swapId) => copyWith(swapId: swapId);

  @override
  EscrowReleaseData copyWithTxHash(String? txHash) => copyWith(txHash: txHash);

  @override
  EscrowReleaseData copyWithTransactionInformation(
    TransactionInformation? transactionInformation,
  ) => copyWith(transactionInformation: transactionInformation);

  @override
  EscrowReleaseData copyWithTransactionReceipt(
    TransactionReceipt? transactionReceipt,
  ) => copyWith(transactionReceipt: transactionReceipt);

  @override
  EscrowReleaseData copyWithGasEstimate({
    required String gasPriceWei,
    required String gasLimit,
  }) => copyWith(gasPriceWei: gasPriceWei, gasLimit: gasLimit);

  EscrowReleaseData copyWith({
    String? gasPriceWei,
    String? gasLimit,
    String? swapId,
    String? txHash,
    TransactionInformation? transactionInformation,
    TransactionReceipt? transactionReceipt,
    String? errorMessage,
  }) => EscrowReleaseData(
    tradeId: tradeId,
    contractAddress: contractAddress,
    chainId: chainId,
    accountIndex: accountIndex,
    gasPriceWei: gasPriceWei ?? this.gasPriceWei,
    gasLimit: gasLimit ?? this.gasLimit,
    swapId: swapId ?? this.swapId,
    txHash: txHash ?? this.txHash,
    transactionInformation:
        transactionInformation ?? this.transactionInformation,
    transactionReceipt: transactionReceipt ?? this.transactionReceipt,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  @override
  Map<String, dynamic> toJson() => {
    'tradeId': tradeId,
    ...super.baseToJson(),
    if (errorMessage != null) 'errorMessage': errorMessage,
  };

  factory EscrowReleaseData.fromJson(Map<String, dynamic> json) =>
      EscrowReleaseData(
        tradeId: json['tradeId'] as String,
        contractAddress: json['contractAddress'] as String,
        chainId: json['chainId'] as int,
        accountIndex: json['accountIndex'] as int? ?? 0,
        gasPriceWei: json['gasPriceWei'] as String?,
        gasLimit: json['gasLimit'] as String?,
        swapId: json['swapId'] as String?,
        txHash: json['txHash'] as String?,
        transactionInformation: deserializeTransactionInformation(
          json['transactionInformation'] as Map<String, dynamic>?,
        ),
        transactionReceipt: deserializeTransactionReceipt(
          json['transactionReceipt'] as Map<String, dynamic>?,
        ),
        errorMessage: json['errorMessage'] as String?,
      );

  @override
  String toString() => 'EscrowReleaseData($tradeId)';
}
