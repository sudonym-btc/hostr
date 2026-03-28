import 'package:web3dart/web3dart.dart';

import '../../evm/main.dart';

// ── Data class ──────────────────────────────────────────────────────────

/// Recovery data that every on-chain operation carries.
///
/// Holds the fields shared across all operations (account index, encoded call
/// intent, swap ID, chain/contract identifiers, tx hash).
class OnchainCallData {
  final String operationIdValue;
  final int accountIndex;
  final String contractAddress;
  final int chainId;

  /// Ordered map of calls this operation intends to execute as a single
  /// batched UserOperation. Keys are human-readable method names (for logging),
  /// values are the `permissionless.Call` instances.
  final Map<String, Call> calls;

  /// Chosen execution transport for [calls].
  final String? transport;

  /// The Boltz swap ID of the nested swap-in, if a swap was required.
  final String? swapId;

  /// The on-chain transaction hash, once broadcast.
  final String? txHash;

  /// Full transaction information, persisted for recovery and consumers.
  final TransactionInformation? transactionInformation;

  /// Full transaction receipt, persisted once confirmation completes.
  final TransactionReceipt? transactionReceipt;

  final String? errorMessage;

  const OnchainCallData({
    required this.operationIdValue,
    required this.contractAddress,
    required this.chainId,
    required this.accountIndex,
    this.calls = const {},
    this.transport,
    this.swapId,
    this.txHash,
    this.transactionInformation,
    this.transactionReceipt,
    this.errorMessage,
  });

  /// Unique identifier for this operation (e.g. tradeId).
  String get operationId => operationIdValue;

  OnchainCallData copyWith({
    Map<String, Call>? calls,
    String? transport,
    String? swapId,
    String? txHash,
    TransactionInformation? transactionInformation,
    TransactionReceipt? transactionReceipt,
    String? errorMessage,
  }) => OnchainCallData(
    operationIdValue: operationIdValue,
    contractAddress: contractAddress,
    chainId: chainId,
    accountIndex: accountIndex,
    calls: calls ?? this.calls,
    transport: transport ?? this.transport,
    swapId: swapId ?? this.swapId,
    txHash: txHash ?? this.txHash,
    transactionInformation:
        transactionInformation ?? this.transactionInformation,
    transactionReceipt: transactionReceipt ?? this.transactionReceipt,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  Map<String, dynamic> toJson() => {
    'operationId': operationIdValue,
    'accountIndex': accountIndex,
    'contractAddress': contractAddress,
    'chainId': chainId,
    if (calls.isNotEmpty) 'callIntents': serializeNamedCalls(calls),
    if (transport != null) 'transport': transport,
    if (swapId != null) 'swapId': swapId,
    if (txHash != null) 'txHash': txHash,
    if (transactionInformation != null)
      'transactionInformation': serializeTransactionInformation(
        transactionInformation!,
      ),
    if (transactionReceipt != null)
      'transactionReceipt': serializeTransactionReceipt(transactionReceipt!),
    if (errorMessage != null) 'errorMessage': errorMessage,
  };

  factory OnchainCallData.fromJson(Map<String, dynamic> json) {
    final calls = parseCalls(json);
    return OnchainCallData(
      operationIdValue:
          (json['operationId'] ?? json['tradeId'] ?? json['id']) as String,
      contractAddress: json['contractAddress'] as String,
      chainId: json['chainId'] as int,
      accountIndex: json['accountIndex'] as int? ?? 0,
      calls: calls,
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
  }
}

/// Parse calls from persisted JSON.
Map<String, Call> parseCalls(Map<String, dynamic> json) {
  if (json['callIntents'] is List) {
    return deserializeNamedCalls(json['callIntents'] as List);
  }
  return const {};
}

// ── State hierarchy ─────────────────────────────────────────────────────

/// Closed set of states for any on-chain operation.
///
/// Because this is [sealed], switch statements over it are exhaustive.
sealed class OnchainOperationState implements MachineState {
  const OnchainOperationState();

  /// The recovery data, non-null once the operation has started.
  OnchainCallData? get data => null;

  /// Unique operation ID for persistence.
  @override
  String? get operationId => data?.operationId;

  /// Whether this is a terminal state (completed / failed).
  @override
  bool get isTerminal => false;

  /// Short string key identifying this state variant.
  @override
  String get stateName;

  /// Always `null` for on-chain operations ([OnchainError] is always
  /// terminal, so recovery via `failedAtStep` does not apply).
  @override
  String? get failedAtStep => null;

  @override
  Map<String, dynamic> toJson();

  /// Deserialise from persisted JSON.
  ///
  /// [dataFromJson] is the concrete [OnchainCallData] factory
  /// (e.g. [OnchainCallData.fromJson]).
  static OnchainOperationState fromJson(
    Map<String, dynamic> json,
    OnchainCallData Function(Map<String, dynamic>) dataFromJson,
  ) {
    final stateName = json['state'] as String;
    return switch (stateName) {
      'initialised' => const OnchainInitialised(),
      'swapProgress' => OnchainSwapProgress(dataFromJson(json)),
      'txBroadcast' => OnchainTxBroadcast(dataFromJson(json)),
      'txBroadcasting' => OnchainTxBroadcasting(dataFromJson(json)),
      'txSent' => OnchainTxSent(dataFromJson(json)),
      'txConfirmed' => OnchainTxConfirmed(dataFromJson(json)),
      'error' => OnchainError(
        json['errorMessage'] ?? 'Unknown error',
        data: dataFromJson(json),
      ),
      _ => const OnchainInitialised(),
    };
  }
}

/// Nothing has happened yet.
class OnchainInitialised extends OnchainOperationState {
  const OnchainInitialised();
  @override
  String get stateName => 'initialised';
  @override
  Map<String, dynamic> toJson() => {'state': 'initialised'};
}

/// A swap-in is in progress to fund the on-chain address.
class OnchainSwapProgress extends OnchainOperationState {
  @override
  final OnchainCallData data;

  /// Live swap state for UI. Null when restored from persisted JSON.
  final SwapInState? swapState;
  OnchainSwapProgress(this.data, {this.swapState});

  @override
  String get stateName => 'swapProgress';
  @override
  Map<String, dynamic> toJson() => {
    'state': 'swapProgress',
    'id': data.operationId,
    'isTerminal': false,
    'updatedAt': DateTime.now().toIso8601String(),
    ...data.toJson(),
  };
}

/// The on-chain transaction has been (or is about to be) broadcast.
class OnchainTxBroadcast extends OnchainOperationState {
  @override
  final OnchainCallData data;
  OnchainTxBroadcast(this.data);

  @override
  String get stateName => 'txBroadcast';
  @override
  Map<String, dynamic> toJson() => {
    'state': 'txBroadcast',
    'id': data.operationId,
    'isTerminal': false,
    'updatedAt': DateTime.now().toIso8601String(),
    ...data.toJson(),
  };
}

/// The on-chain transaction is actively being broadcast.
///
/// This is a **busy state** — written to the store atomically via CAS
/// before `_stepBroadcastTx` begins.  A second process seeing this state
/// will back off (or reclaim it after `staleTimeout`).
class OnchainTxBroadcasting extends OnchainOperationState {
  @override
  final OnchainCallData data;
  OnchainTxBroadcasting(this.data);

  @override
  String get stateName => 'txBroadcasting';
  @override
  Map<String, dynamic> toJson() => {
    'state': 'txBroadcasting',
    'id': data.operationId,
    'isTerminal': false,
    'updatedAt': DateTime.now().toIso8601String(),
    ...data.toJson(),
  };
}

/// The on-chain transaction has been broadcast and the txHash is persisted.
///
/// This is the post-side-effect state for `broadcastTx`.  The idempotent
/// `confirmTx` step picks up from here — any process can run it.
class OnchainTxSent extends OnchainOperationState {
  @override
  final OnchainCallData data;
  OnchainTxSent(this.data);

  @override
  String get stateName => 'txSent';
  @override
  Map<String, dynamic> toJson() => {
    'state': 'txSent',
    'id': data.operationId,
    'isTerminal': false,
    'updatedAt': DateTime.now().toIso8601String(),
    ...data.toJson(),
  };
}

/// The on-chain transaction has been confirmed.
class OnchainTxConfirmed extends OnchainOperationState {
  @override
  final OnchainCallData data;
  OnchainTxConfirmed(this.data);

  @override
  String get stateName => 'txConfirmed';
  @override
  bool get isTerminal => true;

  @override
  Map<String, dynamic> toJson() => {
    'state': 'txConfirmed',
    'id': data.operationId,
    'isTerminal': true,
    'updatedAt': DateTime.now().toIso8601String(),
    ...data.toJson(),
  };
}

/// The operation has failed.
class OnchainError extends OnchainOperationState {
  @override
  final OnchainCallData? data;
  final dynamic error;
  final StackTrace? stackTrace;
  OnchainError(this.error, {this.data, this.stackTrace});

  @override
  String get stateName => 'error';
  @override
  bool get isTerminal => true;

  @override
  Map<String, dynamic> toJson() => {
    'state': 'error',
    if (data != null) 'id': data!.operationId,
    'isTerminal': true,
    'updatedAt': DateTime.now().toIso8601String(),
    if (data != null) ...data!.toJson(),
    'errorMessage': error.toString(),
  };
}

// ── Transaction serialisation helpers ────────────────────────────────────

Map<String, dynamic> serializeTransactionInformation(
  TransactionInformation tx,
) => {
  if (tx.blockHash != null) 'blockHash': tx.blockHash,
  if (!tx.blockNumber.isPending)
    'blockNumber': tx.blockNumber.blockNum.toString(),
  'from': tx.from.toString(),
  'gas': tx.gas.toString(),
  'gasPrice': tx.gasPrice.getInWei.toString(),
  'hash': tx.hash,
  'input': bytesToHex(tx.input, include0x: true),
  'nonce': tx.nonce.toString(),
  if (tx.to != null) 'to': tx.to.toString(),
  if (tx.transactionIndex != null)
    'transactionIndex': tx.transactionIndex.toString(),
  'value': tx.value.getInWei.toString(),
  'v': tx.v.toString(),
  'r': toHexQuantity(tx.r),
  's': toHexQuantity(tx.s),
};

Map<String, dynamic> serializeTransactionReceipt(TransactionReceipt receipt) =>
    {
      'transactionHash': bytesToHex(receipt.transactionHash, include0x: true),
      'transactionIndex': toHexQuantity(receipt.transactionIndex),
      'blockHash': bytesToHex(receipt.blockHash, include0x: true),
      if (!receipt.blockNumber.isPending)
        'blockNumber': receipt.blockNumber.blockNum.toString(),
      if (receipt.from != null) 'from': receipt.from.toString(),
      if (receipt.to != null) 'to': receipt.to.toString(),
      'cumulativeGasUsed': toHexQuantity(receipt.cumulativeGasUsed),
      if (receipt.gasUsed != null) 'gasUsed': toHexQuantity(receipt.gasUsed!),
      if (receipt.effectiveGasPrice != null)
        'effectiveGasPrice': receipt.effectiveGasPrice!.getInWei.toString(),
      if (receipt.contractAddress != null)
        'contractAddress': receipt.contractAddress.toString(),
      if (receipt.status != null) 'status': receipt.status! ? '0x1' : '0x0',
      'logs': receipt.logs.map(serializeFilterEvent).toList(),
    };

Map<String, dynamic> serializeFilterEvent(FilterEvent event) => {
  if (event.removed != null) 'removed': event.removed,
  if (event.logIndex != null) 'logIndex': toHexQuantity(event.logIndex!),
  if (event.transactionIndex != null)
    'transactionIndex': toHexQuantity(event.transactionIndex!),
  if (event.transactionHash != null) 'transactionHash': event.transactionHash,
  if (event.blockHash != null) 'blockHash': event.blockHash,
  if (event.blockNum != null) 'blockNumber': toHexQuantity(event.blockNum!),
  if (event.address != null) 'address': event.address.toString(),
  if (event.data != null) 'data': event.data,
  if (event.topics != null) 'topics': event.topics,
};

TransactionInformation? deserializeTransactionInformation(
  Map<String, dynamic>? json,
) => json == null ? null : TransactionInformation.fromMap(json);

TransactionReceipt? deserializeTransactionReceipt(Map<String, dynamic>? json) =>
    json == null ? null : TransactionReceipt.fromMap(json);

String toHexQuantity(Object value) {
  final bigint = switch (value) {
    int v => BigInt.from(v),
    BigInt v => v,
    _ => throw ArgumentError('Unsupported quantity type: ${value.runtimeType}'),
  };
  return '0x${bigint.toRadixString(16)}';
}
