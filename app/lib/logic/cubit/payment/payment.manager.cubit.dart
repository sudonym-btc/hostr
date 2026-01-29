import 'dart:async';

import 'package:dio/dio.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/logic/workflows/lnurl_workflow.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:models/main.dart';

class PaymentStartResult {
  final String id;
  final PaymentCubit cubit;

  PaymentStartResult({required this.id, required this.cubit});
}

enum PaymentKind { bolt11, lnurl }

class PaymentRecord {
  final String id;
  final PaymentKind kind;
  final PaymentParameters params;
  final PaymentStatus status;
  final String? error;
  final DateTime createdAt;
  final DateTime updatedAt;

  PaymentRecord({
    required this.id,
    required this.kind,
    required this.params,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.error,
  });

  PaymentRecord copyWith({
    PaymentStatus? status,
    String? error,
    DateTime? updatedAt,
  }) {
    return PaymentRecord(
      id: id,
      kind: kind,
      params: params,
      status: status ?? this.status,
      error: error ?? this.error,
      createdAt: createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'kind': kind.name,
      'params': _paramsToJson(params),
      'status': status.name,
      'error': error,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'updatedAt': updatedAt.millisecondsSinceEpoch,
    };
  }

  static PaymentRecord fromJson(Map<String, dynamic> json) {
    final params = _paramsFromJson(json['params'] as Map<String, dynamic>);
    return PaymentRecord(
      id: json['id'] as String,
      kind: PaymentKind.values.byName(json['kind'] as String),
      params: params,
      status: PaymentStatus.values.byName(json['status'] as String),
      error: json['error'] as String?,
      createdAt: DateTime.fromMillisecondsSinceEpoch(json['createdAt'] as int),
      updatedAt: DateTime.fromMillisecondsSinceEpoch(json['updatedAt'] as int),
    );
  }

  static Map<String, dynamic> _paramsToJson(PaymentParameters params) {
    return {
      'type': params is Bolt11PaymentParameters
          ? PaymentKind.bolt11.name
          : PaymentKind.lnurl.name,
      'to': params.to,
      'comment': params.comment,
      'amount': params.amount == null
          ? null
          : {
              'value': params.amount!.value,
              'currency': params.amount!.currency.name,
            },
    };
  }

  static PaymentParameters _paramsFromJson(Map<String, dynamic> json) {
    Amount? amount;
    final amountJson = json['amount'] as Map<String, dynamic>?;
    if (amountJson != null) {
      amount = Amount(
        currency: Currency.values.byName(amountJson['currency'] as String),
        value: (amountJson['value'] as num).toDouble(),
      );
    }

    final type = PaymentKind.values.byName(json['type'] as String);
    switch (type) {
      case PaymentKind.bolt11:
        return Bolt11PaymentParameters(
          to: json['to'] as String,
          amount: amount,
          comment: json['comment'] as String?,
        );
      case PaymentKind.lnurl:
        return LnUrlPaymentParameters(
          to: json['to'] as String,
          amount: amount,
          comment: json['comment'] as String?,
        );
    }
  }
}

class PaymentsState {
  final List<PaymentRecord> payments;

  const PaymentsState({required this.payments});

  PaymentsState copyWith({List<PaymentRecord>? payments}) {
    return PaymentsState(payments: payments ?? this.payments);
  }

  Map<String, dynamic> toJson() => {
    'payments': payments.map((p) => p.toJson()).toList(),
  };

  static PaymentsState fromJson(Map<String, dynamic> json) {
    final list = (json['payments'] as List<dynamic>? ?? [])
        .map((e) => PaymentRecord.fromJson(e as Map<String, dynamic>))
        .toList();
    return PaymentsState(payments: list);
  }

  static PaymentsState initial() => const PaymentsState(payments: []);
}

class PaymentsManager extends HydratedCubit<PaymentsState> {
  final Hostr hostr;
  final Dio dio;
  final Map<String, StreamSubscription> _subscriptions = {};
  final Map<String, PaymentCubit> _cubitCache = {};

  PaymentsManager({required this.hostr, required this.dio})
    : super(PaymentsState.initial());

  PaymentStartResult startPayment(PaymentParameters params) {
    final id = _newId();
    final record = PaymentRecord(
      id: id,
      kind: params is Bolt11PaymentParameters
          ? PaymentKind.bolt11
          : PaymentKind.lnurl,
      params: params,
      status: PaymentStatus.initial,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    _addOrUpdate(record);

    final payment = _buildCubit(params);
    _cubitCache[id] = payment;
    _track(id, payment);
    payment.resolve();

    return PaymentStartResult(id: id, cubit: payment);
  }

  PaymentCubit create(PaymentParameters params) => startPayment(params).cubit;

  PaymentCubit? cubitFor(String id) => _cubitCache[id];

  @override
  Future<void> close() {
    for (final sub in _subscriptions.values) {
      sub.cancel();
    }
    return super.close();
  }

  PaymentCubit _buildCubit(PaymentParameters params) {
    if (params is Bolt11PaymentParameters) {
      return Bolt11PaymentCubit(
        params: params,
        nwc: hostr.nwc,
        workflow: getIt<LnUrlWorkflow>(),
      );
    } else if (params is LnUrlPaymentParameters) {
      return LnUrlPaymentCubit(
        params: params,
        nwc: hostr.nwc,
        workflow: getIt<LnUrlWorkflow>(),
      );
    } else {
      throw Exception('Unsupported payment type');
    }
  }

  void _track(String id, PaymentCubit cubit) {
    _subscriptions[id]?.cancel();
    _subscriptions[id] = cubit.stream.listen((state) {
      final updated = _recordFor(id)?.copyWith(
        status: state.status,
        error: state.error,
        updatedAt: DateTime.now(),
      );
      if (updated != null) {
        _addOrUpdate(updated);
      }
    });
  }

  PaymentRecord? _recordFor(String id) {
    for (final p in state.payments) {
      if (p.id == id) return p;
    }
    return null;
  }

  void _addOrUpdate(PaymentRecord record) {
    final others = state.payments.where((p) => p.id != record.id).toList();
    emit(state.copyWith(payments: [...others, record]));
  }

  String _newId() => DateTime.now().microsecondsSinceEpoch.toString();

  @override
  PaymentsState? fromJson(Map<String, dynamic> json) =>
      PaymentsState.fromJson(json);

  @override
  Map<String, dynamic>? toJson(PaymentsState state) => state.toJson();
}

bool isBolt11(String to) {
  final bolt11Regex = RegExp(
    r'^[a-zA-Z0-9]{1,}$',
  ); // Simplified regex for example
  return bolt11Regex.hasMatch(to);
}

bool isEthereumAddress(String to) {
  final ethAddressRegex = RegExp(r'^0x[a-fA-F0-9]{40}$');
  return ethAddressRegex.hasMatch(to);
}

bool isLnurl(String to) {
  final lnurlRegex = RegExp(
    r'^lnurl[a-zA-Z0-9]{1,}$',
  ); // Simplified regex for example
  return lnurlRegex.hasMatch(to);
}
