import 'package:hostr/logic/cubit/payment/payment.manager.cubit.dart';
import 'package:hostr/logic/main.dart';

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
