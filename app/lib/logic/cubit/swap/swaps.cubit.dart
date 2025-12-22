import 'dart:async';

import 'package:hostr/data/sources/escrow/MultiEscrow.g.dart';
import 'package:hostr/logic/cubit/payment/payment.manager.cubit.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/logic/services/swap.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:models/main.dart';

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

class SwapsState {
  final List<SwapRecord> swaps;

  const SwapsState({required this.swaps});

  SwapsState copyWith({List<SwapRecord>? swaps}) {
    return SwapsState(swaps: swaps ?? this.swaps);
  }

  Map<String, dynamic> toJson() => {
    'swaps': swaps.map((s) => s.toJson()).toList(),
  };

  static SwapsState fromJson(Map<String, dynamic> json) {
    final list = (json['swaps'] as List<dynamic>? ?? [])
        .map((e) => SwapRecord.fromJson(e as Map<String, dynamic>))
        .toList();
    return SwapsState(swaps: list);
  }

  static SwapsState initial() => const SwapsState(swaps: []);
}

@Deprecated('Use SwapManager in swap.manager.cubit.dart')
class SwapsManagerLegacy extends HydratedCubit<SwapsState> {
  final PaymentsManager paymentsManager;
  final SwapService swapService;
  StreamSubscription? _paymentSub;

  SwapsManagerLegacy({required this.paymentsManager, required this.swapService})
    : super(SwapsState.initial()) {
    _paymentSub = paymentsManager.stream.listen(_syncPaymentsIntoSwaps);
  }

  Future<void> swapIn(int amountSats) async {
    final id = _newId();
    final record = SwapRecord(
      id: id,
      type: SwapType.swapIn,
      params: {'amountSats': amountSats},
      status: SwapStatusSnapshot.initiated,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _addOrUpdate(record);

    try {
      await swapService.swapIn(amountSats);
      _updateSwap(id, status: SwapStatusSnapshot.completed);
    } catch (e) {
      _updateSwap(id, status: SwapStatusSnapshot.failed, error: e.toString());
    }
  }

  void _syncPaymentsIntoSwaps(PaymentsState paymentsState) {
    final updated = state.swaps.map((swap) {
      if (swap.payment == null) return swap;
      final payment = paymentsState.payments.firstWhere(
        (p) => p.id == swap.payment!.id,
        orElse: () => swap.payment!,
      );
      return swap.copyWith(payment: payment, updatedAt: DateTime.now());
    }).toList();
    emit(state.copyWith(swaps: updated));
  }

  void _updateSwap(
    String id, {
    SwapStatusSnapshot? status,
    String? error,
    String? paymentId,
  }) {
    final swap = _swapFor(id);
    if (swap == null) return;
    PaymentRecord? payment = swap.payment;
    if (paymentId != null) {
      try {
        payment = paymentsManager.state.payments.firstWhere(
          (p) => p.id == paymentId,
        );
      } catch (_) {
        // keep previous payment if not found
      }
    }

    final updated = swap.copyWith(
      status: status ?? swap.status,
      error: error ?? swap.error,
      payment: payment,
      updatedAt: DateTime.now(),
    );
    _addOrUpdate(updated);
  }

  SwapRecord? _swapFor(String id) {
    for (final s in state.swaps) {
      if (s.id == id) return s;
    }
    return null;
  }

  void _addOrUpdate(SwapRecord record) {
    final others = state.swaps.where((s) => s.id != record.id).toList();
    emit(state.copyWith(swaps: [...others, record]));
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  @override
  SwapsState? fromJson(Map<String, dynamic> json) => SwapsState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(SwapsState state) => state.toJson();

  @override
  Future<void> close() {
    _paymentSub?.cancel();
    return super.close();
  }

  Stream<TradeCreated> checkEscrowStatus(String reservationRequestId) {
    return swapService.checkEscrowStatus(reservationRequestId);
  }

  Future<void> escrow({
    required String eventId,
    required Amount amount,
    required String sellerPubkey,
    required String escrowPubkey,
    required String escrowContractAddress,
    required int timelock,
  }) {
    return swapService.escrow(
      eventId: eventId,
      amount: amount,
      sellerPubkey: sellerPubkey,
      escrowPubkey: escrowPubkey,
      escrowContractAddress: escrowContractAddress,
      timelock: timelock,
    );
  }

  Future<void> swapOutAll() => swapService.swapOutAll();

  Future<void> listEvents() => swapService.listEvents();
}
