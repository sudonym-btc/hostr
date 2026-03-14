import 'package:web3dart/web3dart.dart';

import '../../supported_escrow_contract/supported_escrow_contract.dart';
import '../onchain_operation.dart';

// ── Escrow fund recovery data ─────────────────────────────────────────────

/// Immutable snapshot of escrow-fund recovery data.
///
/// Created at the start of [EscrowFundOperation.execute] and threaded through
/// every state from [EscrowFundSwapProgress] onward.
class EscrowFundData extends OnchainOperationData {
  final String tradeId;

  final String? errorMessage;

  const EscrowFundData({
    required this.tradeId,
    required super.contractAddress,
    required super.chainId,
    required super.accountIndex,
    super.callIntent,
    super.transport,
    super.swapId,
    super.txHash,
    super.transactionInformation,
    super.transactionReceipt,
    this.errorMessage,
  });

  @override
  String get operationId => tradeId;

  @override
  EscrowFundData copyWithSwapId(String? swapId) => copyWith(swapId: swapId);

  @override
  EscrowFundData copyWithTxHash(String? txHash) => copyWith(txHash: txHash);

  @override
  EscrowFundData copyWithTransactionInformation(
    TransactionInformation? transactionInformation,
  ) => copyWith(transactionInformation: transactionInformation);

  @override
  EscrowFundData copyWithTransactionReceipt(
    TransactionReceipt? transactionReceipt,
  ) => copyWith(transactionReceipt: transactionReceipt);

  @override
  EscrowFundData copyWithCallIntent(ContractCallIntent? callIntent) =>
      copyWith(callIntent: callIntent);

  @override
  EscrowFundData copyWithTransport(String? transport) =>
      copyWith(transport: transport);

  EscrowFundData copyWith({
    ContractCallIntent? callIntent,
    String? transport,
    String? swapId,
    String? txHash,
    TransactionInformation? transactionInformation,
    TransactionReceipt? transactionReceipt,
    String? errorMessage,
  }) => EscrowFundData(
    tradeId: tradeId,
    contractAddress: contractAddress,
    chainId: chainId,
    accountIndex: accountIndex,
    callIntent: callIntent ?? this.callIntent,
    transport: transport ?? this.transport,
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

  factory EscrowFundData.fromJson(Map<String, dynamic> json) => EscrowFundData(
    tradeId: json['tradeId'] as String,
    contractAddress: json['contractAddress'] as String,
    chainId: json['chainId'] as int,
    accountIndex: json['accountIndex'] as int? ?? 0,
    callIntent: json['callIntent'] != null
        ? ContractCallIntent.fromJson(
            json['callIntent'] as Map<String, dynamic>,
          )
        : null,
    transport: json['transport'] as String?,
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
  String toString() => 'EscrowFundData($tradeId)';
}
