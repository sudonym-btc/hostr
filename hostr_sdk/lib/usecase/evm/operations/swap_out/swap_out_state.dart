import 'dart:typed_data';

import 'package:convert/convert.dart';

import '../../../../util/main.dart';
import '../../../payments/operations/pay_state.dart';
import '../operation_machine.dart';

// ── Swap-Out recovery data ────────────────────────────────────────────────

/// Immutable snapshot of swap-out recovery data.
///
/// Created when the Boltz swap is submitted and funds are about to be locked.
/// Threaded through every [SwapOutState] variant from [SwapOutAwaitingOnChain]
/// onward.
class SwapOutData {
  final String boltzId;
  final String invoice;
  final String invoicePreimageHashHex;
  final String claimAddress;
  final String lockedAmountWeiHex;
  final String lockerAddress;
  final int timeoutBlockHeight;
  final int chainId;
  final int accountIndex;
  final int? creationBlockHeight;
  final String? lockTxHash;
  final String? resolutionTxHash;
  final String? lastBoltzStatus;
  final String? errorMessage;

  const SwapOutData({
    required this.boltzId,
    required this.invoice,
    required this.invoicePreimageHashHex,
    required this.claimAddress,
    required this.lockedAmountWeiHex,
    required this.lockerAddress,
    required this.timeoutBlockHeight,
    required this.chainId,
    required this.accountIndex,
    this.creationBlockHeight,
    this.lockTxHash,
    this.resolutionTxHash,
    this.lastBoltzStatus,
    this.errorMessage,
  });

  /// Recover the invoice preimage hash bytes from stored hex.
  Uint8List get invoicePreimageHashBytes =>
      Uint8List.fromList(hex.decode(invoicePreimageHashHex));

  /// Recover the locked amount as BigInt from hex.
  BigInt get lockedAmountWei => BigInt.parse(lockedAmountWeiHex, radix: 16);

  SwapOutData copyWith({
    int? creationBlockHeight,
    String? lockTxHash,
    String? resolutionTxHash,
    String? lastBoltzStatus,
    String? errorMessage,
  }) => SwapOutData(
    boltzId: boltzId,
    invoice: invoice,
    invoicePreimageHashHex: invoicePreimageHashHex,
    claimAddress: claimAddress,
    lockedAmountWeiHex: lockedAmountWeiHex,
    lockerAddress: lockerAddress,
    timeoutBlockHeight: timeoutBlockHeight,
    chainId: chainId,
    accountIndex: accountIndex,
    creationBlockHeight: creationBlockHeight ?? this.creationBlockHeight,
    lockTxHash: lockTxHash ?? this.lockTxHash,
    resolutionTxHash: resolutionTxHash ?? this.resolutionTxHash,
    lastBoltzStatus: lastBoltzStatus ?? this.lastBoltzStatus,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  Map<String, dynamic> toJson() => {
    'boltzId': boltzId,
    'invoice': invoice,
    'invoicePreimageHashHex': invoicePreimageHashHex,
    'claimAddress': claimAddress,
    'lockedAmountWeiHex': lockedAmountWeiHex,
    'lockerAddress': lockerAddress,
    'timeoutBlockHeight': timeoutBlockHeight,
    'chainId': chainId,
    'accountIndex': accountIndex,
    if (creationBlockHeight != null) 'creationBlockHeight': creationBlockHeight,
    if (lockTxHash != null) 'lockTxHash': lockTxHash,
    if (resolutionTxHash != null) 'resolutionTxHash': resolutionTxHash,
    if (lastBoltzStatus != null) 'lastBoltzStatus': lastBoltzStatus,
    if (errorMessage != null) 'errorMessage': errorMessage,
  };

  factory SwapOutData.fromJson(Map<String, dynamic> json) => SwapOutData(
    boltzId: json['boltzId'] as String,
    invoice: json['invoice'] as String,
    invoicePreimageHashHex: json['invoicePreimageHashHex'] as String,
    claimAddress: json['claimAddress'] as String,
    lockedAmountWeiHex: json['lockedAmountWeiHex'] as String,
    lockerAddress: json['lockerAddress'] as String,
    timeoutBlockHeight: json['timeoutBlockHeight'] as int,
    chainId: json['chainId'] as int,
    accountIndex: json['accountIndex'] as int? ?? 0,
    creationBlockHeight: json['creationBlockHeight'] as int?,
    lockTxHash: json['lockTxHash'] as String?,
    resolutionTxHash: json['resolutionTxHash'] as String?,
    lastBoltzStatus: json['lastBoltzStatus'] as String?,
    errorMessage: json['errorMessage'] as String?,
  );

  @override
  String toString() => 'SwapOutData($boltzId)';
}

// ── Swap-Out cubit states ─────────────────────────────────────────────────

sealed class SwapOutState implements MachineState {
  const SwapOutState();

  /// Persisted swap data. Non-null once funds are committed on-chain.
  SwapOutData? get data => null;

  /// Unique operation ID for persistence.
  @override
  String? get operationId => data?.boltzId;

  /// Whether this is a terminal state.
  @override
  bool get isTerminal => false;

  /// Short string key identifying this state variant.
  @override
  String get stateName;

  /// Only non-null for [SwapOutFailed] with a recoverable step.
  @override
  String? get failedAtStep => null;

  /// Serialise for [OperationStateStore] persistence.
  @override
  Map<String, dynamic> toJson();

  /// Deserialise from persisted JSON.
  static SwapOutState fromJson(Map<String, dynamic> json) {
    final state = json['state'] as String;
    return switch (state) {
      'initialised' => const SwapOutInitialised(),
      'requestCreated' => const SwapOutRequestCreated(),
      'awaitingOnChain' => SwapOutAwaitingOnChain(SwapOutData.fromJson(json)),
      'funded' => SwapOutFunded(SwapOutData.fromJson(json)),
      'claimed' => SwapOutClaimed(SwapOutData.fromJson(json)),
      'completed' => SwapOutCompleted(SwapOutData.fromJson(json)),
      'refunding' => SwapOutRefunding(SwapOutData.fromJson(json)),
      'locking' => SwapOutLocking(SwapOutData.fromJson(json)),
      'refunded' => SwapOutRefunded(SwapOutData.fromJson(json)),
      'failed' => SwapOutFailed(
        json['errorMessage'] ?? 'Unknown error',
        data: SwapOutData.fromJson(json),
        failedAtStep: json['failedAtStep'] as String?,
      ),
      _ => const SwapOutInitialised(),
    };
  }
}

// ── Pre-data states (ephemeral, not persisted) ────────────────────────────

final class SwapOutInitialised extends SwapOutState {
  const SwapOutInitialised();
  @override
  String get stateName => 'initialised';
  @override
  Map<String, dynamic> toJson() => {'state': 'initialised'};
}

final class SwapOutRequestCreated extends SwapOutState {
  const SwapOutRequestCreated();
  @override
  String get stateName => 'requestCreated';
  @override
  Map<String, dynamic> toJson() => {'state': 'requestCreated'};
}

final class SwapOutExternalInvoiceRequired extends SwapOutState {
  final BitcoinAmount invoiceAmount;
  const SwapOutExternalInvoiceRequired(this.invoiceAmount);
  @override
  String get stateName => 'externalInvoiceRequired';
  @override
  Map<String, dynamic> toJson() => {'state': 'externalInvoiceRequired'};
}

final class SwapOutInvoiceCreated extends SwapOutState {
  final String invoice;
  const SwapOutInvoiceCreated(this.invoice);
  @override
  String get stateName => 'invoiceCreated';
  @override
  Map<String, dynamic> toJson() => {'state': 'invoiceCreated'};
}

final class SwapOutPaymentProgress extends SwapOutState {
  final PayState paymentState;
  const SwapOutPaymentProgress({required this.paymentState});
  @override
  String get stateName => 'paymentProgress';
  @override
  Map<String, dynamic> toJson() => {'state': 'paymentProgress'};
}

// ── Data-bearing states (persisted) ───────────────────────────────────────

final class SwapOutAwaitingOnChain extends SwapOutState {
  @override
  final SwapOutData data;
  const SwapOutAwaitingOnChain(this.data);
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

final class SwapOutFunded extends SwapOutState {
  @override
  final SwapOutData data;
  const SwapOutFunded(this.data);
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

final class SwapOutClaimed extends SwapOutState {
  @override
  final SwapOutData data;
  const SwapOutClaimed(this.data);
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

final class SwapOutCompleted extends SwapOutState {
  @override
  final SwapOutData data;
  const SwapOutCompleted(this.data);
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

final class SwapOutRefunding extends SwapOutState {
  @override
  final SwapOutData data;
  const SwapOutRefunding(this.data);
  @override
  String get stateName => 'refunding';
  @override
  Map<String, dynamic> toJson() => {
    'state': 'refunding',
    'id': data.boltzId,
    'isTerminal': false,
    'updatedAt': DateTime.now().toIso8601String(),
    ...data.toJson(),
  };
}

final class SwapOutRefunded extends SwapOutState {
  @override
  final SwapOutData data;
  const SwapOutRefunded(this.data);
  @override
  String get stateName => 'refunded';
  @override
  bool get isTerminal => true;
  @override
  Map<String, dynamic> toJson() => {
    'state': 'refunded',
    'id': data.boltzId,
    'isTerminal': true,
    'updatedAt': DateTime.now().toIso8601String(),
    ...data.toJson(),
  };
}

final class SwapOutFailed extends SwapOutState {
  @override
  final SwapOutData? data;
  final Object error;
  final StackTrace? stackTrace;

  /// The step that was executing when the failure occurred.
  /// Used by [OperationMachine.run] to re-enter the correct step on
  /// recovery without subclass-specific hooks.
  @override
  final String? failedAtStep;

  const SwapOutFailed(
    this.error, {
    this.data,
    this.stackTrace,
    this.failedAtStep,
  });

  @override
  String get stateName => 'failed';

  /// A failed swap-out is **not** terminal when either:
  /// - [failedAtStep] is set (the run loop knows where to retry), or
  /// - the user has locked funds on-chain and no resolution tx exists.
  @override
  bool get isTerminal {
    if (failedAtStep != null) return false;
    final d = data;
    if (d == null) return true;
    // Funds locked but no resolution tx → recoverable.
    if (d.lockTxHash != null && d.resolutionTxHash == null) return false;
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

/// Funds are being locked in the EtherSwap contract.
///
/// This is a **busy/CAS lock** state: persisted before the lock
/// side-effect begins so that another process reading the store
/// will see it and back off.
final class SwapOutLocking extends SwapOutState {
  @override
  final SwapOutData data;
  const SwapOutLocking(this.data);
  @override
  String get stateName => 'locking';
  @override
  Map<String, dynamic> toJson() => {
    'state': 'locking',
    'id': data.boltzId,
    'isTerminal': false,
    'updatedAt': DateTime.now().toIso8601String(),
    ...data.toJson(),
  };
}
