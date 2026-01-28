import 'package:hostr/core/main.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/payments/swap.dart';
import 'package:hostr/logic/cubit/payment/payment.manager.cubit.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';

/// Workflow handling multi-phase swap operations.
/// Manages swap lifecycle: initiated → payment → onchain → claimed → completed
@injectable
class SwapWorkflow {
  final CustomLogger _logger = CustomLogger();

  /// Maps swap progress enum to status snapshot.
  SwapStatusSnapshot mapProgressToStatus(SwapProgress progress) {
    switch (progress) {
      case SwapProgress.initiated:
        return SwapStatusSnapshot.initiated;
      case SwapProgress.paymentCreated:
        return SwapStatusSnapshot.paymentCreated;
      case SwapProgress.paymentInFlight:
        return SwapStatusSnapshot.paymentInFlight;
      case SwapProgress.waitingOnchain:
        return SwapStatusSnapshot.waitingOnchain;
      case SwapProgress.claimed:
        return SwapStatusSnapshot.claimed;
      case SwapProgress.completed:
        return SwapStatusSnapshot.completed;
      case SwapProgress.failed:
        return SwapStatusSnapshot.failed;
    }
  }

  /// Synchronizes payment state into swap records.
  /// Returns updated swap list with latest payment data.
  List<SwapRecord> syncPaymentsIntoSwaps({
    required List<SwapRecord> swaps,
    required List<PaymentRecord> payments,
  }) {
    _logger.d('Syncing ${payments.length} payments into ${swaps.length} swaps');

    return swaps.map((swap) {
      if (swap.payment == null) return swap;

      final payment = payments.firstWhere(
        (p) => p.id == swap.payment!.id,
        orElse: () => swap.payment!,
      );

      return swap.copyWith(payment: payment, updatedAt: DateTime.now());
    }).toList();
  }

  /// Validates swap parameters before initiation.
  void validateSwapInParams({required int amountSats}) {
    if (amountSats <= 0) {
      throw ArgumentError('Swap amount must be positive');
    }
    // Add more validation as needed
    _logger.d('Swap-in params validated: $amountSats sats');
  }

  /// Validates escrow parameters before deposit.
  void validateEscrowParams({
    required String eventId,
    required Amount amount,
    required String sellerPubkey,
    required String escrowPubkey,
    required String escrowContractAddress,
    required int timelock,
  }) {
    if (eventId.isEmpty) throw ArgumentError('Event ID required');
    if (amount.value <= 0) throw ArgumentError('Amount must be positive');
    if (sellerPubkey.isEmpty) throw ArgumentError('Seller pubkey required');
    if (escrowPubkey.isEmpty) throw ArgumentError('Escrow pubkey required');
    if (escrowContractAddress.isEmpty) {
      throw ArgumentError('Contract address required');
    }
    if (timelock <= 0) throw ArgumentError('Timelock must be positive');

    _logger.d('Escrow params validated');
  }

  /// Generates unique swap ID.
  String generateSwapId() {
    return DateTime.now().microsecondsSinceEpoch.toString();
  }

  /// Creates initial swap record.
  SwapRecord createSwapRecord({
    required String id,
    required SwapType type,
    required Map<String, dynamic> params,
  }) {
    _logger.i('Creating swap record: $id (${type.name})');

    return SwapRecord(
      id: id,
      type: type,
      params: params,
      status: SwapStatusSnapshot.initiated,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
  }

  /// Updates existing swap record with new status/error/payment.
  SwapRecord updateSwapRecord({
    required SwapRecord swap,
    SwapStatusSnapshot? status,
    String? error,
    PaymentRecord? payment,
  }) {
    _logger.d('Updating swap ${swap.id}: status=${status?.name}');

    return swap.copyWith(
      status: status ?? swap.status,
      error: error ?? swap.error,
      payment: payment ?? swap.payment,
      updatedAt: DateTime.now(),
    );
  }

  /// Finds swap by payment ID.
  SwapRecord? findSwapByPaymentId({
    required List<SwapRecord> swaps,
    required String paymentId,
  }) {
    try {
      return swaps.firstWhere((s) => s.payment?.id == paymentId);
    } catch (_) {
      return null;
    }
  }
}

// Re-export types that workflows use (these remain in swap.manager.cubit.dart)
enum SwapType { swapIn, swapOut }

enum SwapStatusSnapshot {
  initiated,
  paymentCreated,
  paymentInFlight,
  waitingOnchain,
  claimed,
  completed,
  failed,
}

class SwapRecord {
  final String id;
  final SwapType type;
  final Map<String, dynamic> params;
  final SwapStatusSnapshot status;
  final PaymentRecord? payment;
  final String? error;
  final DateTime createdAt;
  final DateTime updatedAt;

  SwapRecord({
    required this.id,
    required this.type,
    required this.params,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.payment,
    this.error,
  });

  SwapRecord copyWith({
    SwapStatusSnapshot? status,
    PaymentRecord? payment,
    String? error,
    DateTime? updatedAt,
  }) {
    return SwapRecord(
      id: id,
      type: type,
      params: params,
      status: status ?? this.status,
      payment: payment ?? this.payment,
      error: error ?? this.error,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'params': params,
    'status': status.name,
    'payment': payment?.toJson(),
    'error': error,
    'createdAt': createdAt.millisecondsSinceEpoch,
    'updatedAt': updatedAt.millisecondsSinceEpoch,
  };

  static SwapRecord fromJson(Map<String, dynamic> json) {
    return SwapRecord(
      id: json['id'] as String,
      type: SwapType.values.byName(json['type'] as String),
      params: (json['params'] as Map<String, dynamic>?) ?? {},
      status: SwapStatusSnapshot.values.byName(json['status'] as String),
      payment: json['payment'] == null
          ? null
          : PaymentRecord.fromJson(json['payment'] as Map<String, dynamic>),
      error: json['error'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
    );
  }
}
