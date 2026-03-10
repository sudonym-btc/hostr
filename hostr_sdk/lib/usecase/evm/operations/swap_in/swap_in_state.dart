import 'dart:typed_data';

import 'package:convert/convert.dart';

import '../../../payments/operations/pay_state.dart';
import '../operation_machine.dart';

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

  /// When this swap is nested inside a parent operation (e.g. escrow-fund),
  /// this is the parent's operation ID (e.g. tradeId) so that progress
  /// notifications update the same OS notification.
  final String? parentOperationId;

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
    this.parentOperationId,
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
    parentOperationId: parentOperationId,
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
    if (parentOperationId != null) 'parentOperationId': parentOperationId,
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
    parentOperationId: json['parentOperationId'] as String?,
  );

  @override
  String toString() => 'SwapInData($boltzId)';
}

// ── Swap-In cubit states ──────────────────────────────────────────────────

sealed class SwapInState implements MachineState {
  const SwapInState();

  /// Persisted swap data. Non-null once the Boltz swap has been created.
  SwapInData? get data => null;

  /// Unique operation ID for persistence. Null before swap creation.
  @override
  String? get operationId => data?.boltzId;

  /// Whether this is a terminal state (completed or failed).
  @override
  bool get isTerminal => false;

  /// Short string key identifying this state variant.
  @override
  String get stateName;

  /// Only non-null for [SwapInFailed] with a recoverable step.
  @override
  String? get failedAtStep => null;

  /// Serialise for [OperationStateStore] persistence.
  @override
  Map<String, dynamic> toJson();

  /// Deserialise from persisted JSON.
  static SwapInState fromJson(Map<String, dynamic> json) {
    final state = json['state'] as String;
    return switch (state) {
      'initialised' => const SwapInInitialised(),
      'requestCreated' => SwapInRequestCreated(SwapInData.fromJson(json)),
      'paymentProgress' => SwapInPaymentProgress(SwapInData.fromJson(json)),
      'awaitingOnChain' => SwapInAwaitingOnChain(SwapInData.fromJson(json)),
      'invoicePaid' => SwapInInvoicePaid(SwapInData.fromJson(json)),
      'funded' => SwapInFunded(SwapInData.fromJson(json)),
      'claimed' => SwapInClaimed(SwapInData.fromJson(json)),
      'claimTxInMempool' => SwapInClaimTxInMempool(SwapInData.fromJson(json)),
      'completed' => SwapInCompleted(SwapInData.fromJson(json)),
      'failed' => SwapInFailed(
        json['errorMessage'] ?? 'Unknown error',
        data: SwapInData.fromJson(json),
        failedAtStep: json['failedAtStep'] as String?,
      ),
      'paymentDispatching' => SwapInPaymentDispatching(
        SwapInData.fromJson(json),
      ),
      'claimRelaying' => SwapInClaimRelaying(SwapInData.fromJson(json)),
      _ => const SwapInInitialised(),
    };
  }
}

final class SwapInInitialised extends SwapInState {
  const SwapInInitialised();
  @override
  String get stateName => 'initialised';
  @override
  Map<String, dynamic> toJson() => {'state': 'initialised'};
}

final class SwapInRequestCreated extends SwapInState {
  @override
  final SwapInData data;
  const SwapInRequestCreated(this.data);
  @override
  String get stateName => 'requestCreated';
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
  String get stateName => 'paymentProgress';
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
  String get stateName => 'awaitingOnChain';
  @override
  Map<String, dynamic> toJson() => {
    'state': 'awaitingOnChain',
    'id': data.boltzId,
    'isTerminal': false,
    'updatedAt': DateTime.now().toIso8601String(),
    ...data.toJson(),
  };
}

/// Boltz has confirmed the Lightning invoice is settled.
///
/// This is an **emit-only** (non-persisted) state used purely for UI
/// feedback and OS notifications.  It fires as soon as the Boltz WebSocket
/// reports `invoice.settled`, before the on-chain lockup appears.
final class SwapInInvoicePaid extends SwapInState {
  @override
  final SwapInData data;
  const SwapInInvoicePaid(this.data);
  @override
  String get stateName => 'invoicePaid';
  @override
  Map<String, dynamic> toJson() => {
    'state': 'invoicePaid',
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
  String get stateName => 'funded';
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
  String get stateName => 'claimed';
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
  String get stateName => 'claimTxInMempool';
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
  String get stateName => 'completed';
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

  /// The step that was executing when the failure occurred.
  /// Used by [OperationMachine.run] to re-enter the correct step on
  /// recovery without subclass-specific hooks.
  @override
  final String? failedAtStep;

  const SwapInFailed(
    this.error, {
    this.data,
    this.stackTrace,
    this.failedAtStep,
  });

  @override
  String get stateName => 'failed';

  /// A failed swap-in is **not** terminal when either:
  /// - [failedAtStep] is set (the run loop knows where to retry), or
  /// - funds are locked on-chain but haven't been claimed yet.
  @override
  bool get isTerminal {
    if (failedAtStep != null) return false;
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
    if (failedAtStep != null) 'failedAtStep': failedAtStep,
  };
}

/// The Lightning payment is being dispatched to Boltz.
///
/// This is a **busy/CAS lock** state: it is persisted before the payment
/// side-effect begins so that another process reading the store will see
/// it and back off. If the process crashes, the [StepGuard.staleTimeout]
/// allows a future recovery attempt to reclaim it.
final class SwapInPaymentDispatching extends SwapInState {
  @override
  final SwapInData data;
  const SwapInPaymentDispatching(this.data);
  @override
  String get stateName => 'paymentDispatching';
  @override
  Map<String, dynamic> toJson() => {
    'state': 'paymentDispatching',
    'id': data.boltzId,
    'isTerminal': false,
    'updatedAt': DateTime.now().toIso8601String(),
    ...data.toJson(),
  };
}

/// The on-chain claim is being relayed via RIF Relay.
///
/// This is a **busy/CAS lock** state, analogous to
/// [SwapInPaymentDispatching] — see that class for details.
final class SwapInClaimRelaying extends SwapInState {
  @override
  final SwapInData data;
  const SwapInClaimRelaying(this.data);
  @override
  String get stateName => 'claimRelaying';
  @override
  Map<String, dynamic> toJson() => {
    'state': 'claimRelaying',
    'id': data.boltzId,
    'isTerminal': false,
    'updatedAt': DateTime.now().toIso8601String(),
    ...data.toJson(),
  };
}
