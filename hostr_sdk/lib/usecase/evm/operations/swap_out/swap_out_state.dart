import 'dart:typed_data';

import 'package:convert/convert.dart';

import '../../../../util/main.dart';
import '../../../payments/operations/pay_state.dart';

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
    lockTxHash: json['lockTxHash'] as String?,
    resolutionTxHash: json['resolutionTxHash'] as String?,
    lastBoltzStatus: json['lastBoltzStatus'] as String?,
    errorMessage: json['errorMessage'] as String?,
  );

  @override
  String toString() => 'SwapOutData($boltzId)';
}

// ── Swap-Out cubit states ─────────────────────────────────────────────────

sealed class SwapOutState {
  const SwapOutState();

  /// Persisted swap data. Non-null once funds are committed on-chain.
  SwapOutData? get data => null;

  /// Unique operation ID for persistence.
  String? get operationId => data?.boltzId;

  /// Whether this is a terminal state.
  bool get isTerminal => false;

  /// Serialise for [OperationStateStore] persistence.
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
      'refunded' => SwapOutRefunded(SwapOutData.fromJson(json)),
      'failed' => SwapOutFailed(
        json['errorMessage'] ?? 'Unknown error',
        data: SwapOutData.fromJson(json),
      ),
      _ => const SwapOutInitialised(),
    };
  }
}

// ── Pre-data states (ephemeral, not persisted) ────────────────────────────

final class SwapOutInitialised extends SwapOutState {
  const SwapOutInitialised();
  @override
  Map<String, dynamic> toJson() => {'state': 'initialised'};
}

final class SwapOutRequestCreated extends SwapOutState {
  const SwapOutRequestCreated();
  @override
  Map<String, dynamic> toJson() => {'state': 'requestCreated'};
}

final class SwapOutExternalInvoiceRequired extends SwapOutState {
  final BitcoinAmount invoiceAmount;
  const SwapOutExternalInvoiceRequired(this.invoiceAmount);
  @override
  Map<String, dynamic> toJson() => {'state': 'externalInvoiceRequired'};
}

final class SwapOutInvoiceCreated extends SwapOutState {
  final String invoice;
  const SwapOutInvoiceCreated(this.invoice);
  @override
  Map<String, dynamic> toJson() => {'state': 'invoiceCreated'};
}

final class SwapOutPaymentProgress extends SwapOutState {
  final PayState paymentState;
  const SwapOutPaymentProgress({required this.paymentState});
  @override
  Map<String, dynamic> toJson() => {'state': 'paymentProgress'};
}

// ── Data-bearing states (persisted) ───────────────────────────────────────

final class SwapOutAwaitingOnChain extends SwapOutState {
  @override
  final SwapOutData data;
  const SwapOutAwaitingOnChain(this.data);
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
  const SwapOutFailed(this.error, {this.data, this.stackTrace});
  @override
  bool get isTerminal => true;
  @override
  Map<String, dynamic> toJson() => {
    'state': 'failed',
    if (data != null) 'id': data!.boltzId,
    'isTerminal': true,
    'updatedAt': DateTime.now().toIso8601String(),
    if (data != null) ...data!.toJson(),
    'errorMessage': error.toString(),
  };
}
