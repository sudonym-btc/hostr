import 'dart:typed_data';

import 'package:convert/convert.dart';

import '../../../payments/operations/pay_state.dart';

// ── Swap-In recovery data ─────────────────────────────────────────────────

/// Immutable snapshot of swap-in recovery data.
///
/// Created when the Boltz swap is submitted and grows (via [copyWith]) as the
/// swap progresses. Threaded through every [SwapInState] variant after
/// [SwapInInitialised].
class SwapInData {
  final String boltzId;
  final String preimageHex;
  final String preimageHash;
  final int onchainAmountSat;
  final int timeoutBlockHeight;
  final int chainId;
  final int accountIndex;
  final int? creationBlockHeight;
  final String? invoiceString;
  final String? lockupTxHash;
  final String? refundAddress;
  final String? claimTxHash;
  final String? lastBoltzStatus;
  final String? errorMessage;

  const SwapInData({
    required this.boltzId,
    required this.preimageHex,
    required this.preimageHash,
    required this.onchainAmountSat,
    required this.timeoutBlockHeight,
    required this.chainId,
    required this.accountIndex,
    this.creationBlockHeight,
    this.invoiceString,
    this.lockupTxHash,
    this.refundAddress,
    this.claimTxHash,
    this.lastBoltzStatus,
    this.errorMessage,
  });

  /// Recover the preimage bytes from the stored hex.
  Uint8List get preimageBytes => Uint8List.fromList(hex.decode(preimageHex));

  SwapInData copyWith({
    int? creationBlockHeight,
    String? invoiceString,
    String? lockupTxHash,
    String? refundAddress,
    String? claimTxHash,
    String? lastBoltzStatus,
    String? errorMessage,
  }) => SwapInData(
    boltzId: boltzId,
    preimageHex: preimageHex,
    preimageHash: preimageHash,
    onchainAmountSat: onchainAmountSat,
    timeoutBlockHeight: timeoutBlockHeight,
    chainId: chainId,
    accountIndex: accountIndex,
    creationBlockHeight: creationBlockHeight ?? this.creationBlockHeight,
    invoiceString: invoiceString ?? this.invoiceString,
    lockupTxHash: lockupTxHash ?? this.lockupTxHash,
    refundAddress: refundAddress ?? this.refundAddress,
    claimTxHash: claimTxHash ?? this.claimTxHash,
    lastBoltzStatus: lastBoltzStatus ?? this.lastBoltzStatus,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  Map<String, dynamic> toJson() => {
    'boltzId': boltzId,
    'preimageHex': preimageHex,
    'preimageHash': preimageHash,
    'onchainAmountSat': onchainAmountSat,
    'timeoutBlockHeight': timeoutBlockHeight,
    'chainId': chainId,
    'accountIndex': accountIndex,
    if (creationBlockHeight != null) 'creationBlockHeight': creationBlockHeight,
    if (invoiceString != null) 'invoiceString': invoiceString,
    if (lockupTxHash != null) 'lockupTxHash': lockupTxHash,
    if (refundAddress != null) 'refundAddress': refundAddress,
    if (claimTxHash != null) 'claimTxHash': claimTxHash,
    if (lastBoltzStatus != null) 'lastBoltzStatus': lastBoltzStatus,
    if (errorMessage != null) 'errorMessage': errorMessage,
  };

  factory SwapInData.fromJson(Map<String, dynamic> json) => SwapInData(
    boltzId: json['boltzId'] as String,
    preimageHex: json['preimageHex'] as String,
    preimageHash: json['preimageHash'] as String,
    onchainAmountSat: json['onchainAmountSat'] as int,
    timeoutBlockHeight: json['timeoutBlockHeight'] as int,
    chainId: json['chainId'] as int,
    accountIndex: json['accountIndex'] as int? ?? 0,
    creationBlockHeight: json['creationBlockHeight'] as int?,
    invoiceString: json['invoiceString'] as String?,
    lockupTxHash: json['lockupTxHash'] as String?,
    refundAddress: json['refundAddress'] as String?,
    claimTxHash: json['claimTxHash'] as String?,
    lastBoltzStatus: json['lastBoltzStatus'] as String?,
    errorMessage: json['errorMessage'] as String?,
  );

  @override
  String toString() => 'SwapInData($boltzId)';
}

// ── Swap-In cubit states ──────────────────────────────────────────────────

sealed class SwapInState {
  const SwapInState();

  /// Persisted swap data. Non-null once the Boltz swap has been created.
  SwapInData? get data => null;

  /// Unique operation ID for persistence. Null before swap creation.
  String? get operationId => data?.boltzId;

  /// Whether this is a terminal state (completed or failed).
  bool get isTerminal => false;

  /// Serialise for [OperationStateStore] persistence.
  Map<String, dynamic> toJson();

  /// Deserialise from persisted JSON.
  static SwapInState fromJson(Map<String, dynamic> json) {
    final state = json['state'] as String;
    return switch (state) {
      'initialised' => const SwapInInitialised(),
      'requestCreated' => SwapInRequestCreated(SwapInData.fromJson(json)),
      'paymentProgress' => SwapInPaymentProgress(SwapInData.fromJson(json)),
      'awaitingOnChain' => SwapInAwaitingOnChain(SwapInData.fromJson(json)),
      'funded' => SwapInFunded(SwapInData.fromJson(json)),
      'claimed' => SwapInClaimed(SwapInData.fromJson(json)),
      'claimTxInMempool' => SwapInClaimTxInMempool(SwapInData.fromJson(json)),
      'completed' => SwapInCompleted(SwapInData.fromJson(json)),
      'failed' => SwapInFailed(
        json['errorMessage'] ?? 'Unknown error',
        data: SwapInData.fromJson(json),
      ),
      _ => const SwapInInitialised(),
    };
  }
}

final class SwapInInitialised extends SwapInState {
  const SwapInInitialised();
  @override
  Map<String, dynamic> toJson() => {'state': 'initialised'};
}

final class SwapInRequestCreated extends SwapInState {
  @override
  final SwapInData data;
  const SwapInRequestCreated(this.data);
  @override
  Map<String, dynamic> toJson() => {
    'state': 'requestCreated',
    'id': data.boltzId,
    'isTerminal': false,
    'updatedAt': DateTime.now().toIso8601String(),
    ...data.toJson(),
  };
}

final class SwapInPaymentProgress extends SwapInState {
  @override
  final SwapInData data;

  /// The live payment state. Null when restored from persisted JSON.
  final PayState? paymentState;
  const SwapInPaymentProgress(this.data, {this.paymentState});

  @override
  Map<String, dynamic> toJson() => {
    'state': 'paymentProgress',
    'id': data.boltzId,
    'isTerminal': false,
    'updatedAt': DateTime.now().toIso8601String(),
    ...data.toJson(),
  };
}

final class SwapInAwaitingOnChain extends SwapInState {
  @override
  final SwapInData data;
  const SwapInAwaitingOnChain(this.data);
  @override
  Map<String, dynamic> toJson() => {
    'state': 'awaitingOnChain',
    'id': data.boltzId,
    'isTerminal': false,
    'updatedAt': DateTime.now().toIso8601String(),
    ...data.toJson(),
  };
}

final class SwapInFunded extends SwapInState {
  @override
  final SwapInData data;
  const SwapInFunded(this.data);
  @override
  Map<String, dynamic> toJson() => {
    'state': 'funded',
    'id': data.boltzId,
    'isTerminal': false,
    'updatedAt': DateTime.now().toIso8601String(),
    ...data.toJson(),
  };
}

final class SwapInClaimed extends SwapInState {
  @override
  final SwapInData data;
  const SwapInClaimed(this.data);
  @override
  Map<String, dynamic> toJson() => {
    'state': 'claimed',
    'id': data.boltzId,
    'isTerminal': false,
    'updatedAt': DateTime.now().toIso8601String(),
    ...data.toJson(),
  };
}

/// The claim transaction has been detected in the mempool.
///
/// This is a visual-feedback-only state between [SwapInClaimed] (broadcast)
/// and [SwapInCompleted] (receipt confirmed). It does not gate any logic.
final class SwapInClaimTxInMempool extends SwapInState {
  @override
  final SwapInData data;
  const SwapInClaimTxInMempool(this.data);
  @override
  Map<String, dynamic> toJson() => {
    'state': 'claimTxInMempool',
    'id': data.boltzId,
    'isTerminal': false,
    'updatedAt': DateTime.now().toIso8601String(),
    ...data.toJson(),
  };
}

final class SwapInCompleted extends SwapInState {
  @override
  final SwapInData data;
  const SwapInCompleted(this.data);
  @override
  bool get isTerminal => true;
  @override
  Map<String, dynamic> toJson() => {
    'state': 'completed',
    'id': data.boltzId,
    'isTerminal': true,
    'updatedAt': DateTime.now().toIso8601String(),
    ...data.toJson(),
  };
}

final class SwapInFailed extends SwapInState {
  @override
  final SwapInData? data;
  final Object error;
  final StackTrace? stackTrace;
  const SwapInFailed(this.error, {this.data, this.stackTrace});

  /// A failed swap-in is **not** terminal when funds are locked on-chain
  /// but haven't been claimed yet. The claim can be retried (e.g. after a
  /// transient RIF Relay failure or network outage).
  @override
  bool get isTerminal {
    final d = data;
    if (d == null) return true;
    // Funds locked but not claimed → recoverable.
    if (d.lockupTxHash != null && d.claimTxHash == null) return false;
    return true;
  }

  @override
  Map<String, dynamic> toJson() => {
    'state': 'failed',
    if (data != null) 'id': data!.boltzId,
    'isTerminal': isTerminal,
    'updatedAt': DateTime.now().toIso8601String(),
    if (data != null) ...data!.toJson(),
    'errorMessage': error.toString(),
  };
}
