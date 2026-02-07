import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/core/main.dart';
import 'package:models/main.dart';
import 'package:wallet/wallet.dart';

class PaymentParameters {
  final BitcoinAmount? amount;
  final String to;
  final String? comment;

  PaymentParameters({required this.to, this.amount, this.comment});
}

class EvmPaymentParameters extends PaymentParameters {
  late EthereumAddress parsedTo;
  EvmPaymentParameters({required super.to, super.amount}) {
    parsedTo = EthereumAddress.fromHex(to);
  }
}

class ZapPaymentParameters extends PaymentParameters {
  final Event? event;
  ZapPaymentParameters({
    super.amount,
    super.comment,
    required super.to,
    this.event,
  });
}

class PaymentCubit<
  T extends PaymentParameters,
  RD extends ResolvedDetails,
  CD extends CallbackDetails,
  CmpD extends CompletedDetails
>
    extends Cubit<PaymentState<T, RD, CD, CmpD>> {
  CustomLogger logger = CustomLogger();
  final T params;

  PaymentCubit({required this.params})
    : super(PaymentState(status: PaymentStatus.initial, params: params));

  Future<RD> resolver() {
    throw Exception('Not implemented');
  }

  Future<CD> callback() {
    throw Exception('Not implemented');
  }

  Future<CmpD> complete() {
    throw Exception('Not implemented');
  }

  /// Called upon initialization
  /// Estimates fees etc
  Future<void> resolve() async {
    emit(state.copyWith(status: PaymentStatus.resolveInitiated));
    try {
      RD resolvedDetails = await resolver();
      emit(
        state.copyWith(
          status: PaymentStatus.resolved,
          resolvedDetails: resolvedDetails,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: PaymentStatus.failed, error: e.toString()));
    }
  }

  /// Called if a step is required to fetch the final payment address
  /// E.g. for LNURL
  Future<void> ok() async {
    emit(state.copyWith(status: PaymentStatus.callbackInitiated));
    try {
      CD callbackDetails = await callback();
      emit(
        state.copyWith(
          status: PaymentStatus.callbackComplete,
          callbackDetails: callbackDetails,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: PaymentStatus.failed, error: e.toString()));
    }
  }

  Future<void> confirm() async {
    emit(state.copyWith(status: PaymentStatus.inFlight));
    try {
      CmpD completedDetails = await complete();
      emit(
        state.copyWith(
          status: PaymentStatus.completed,
          completedDetails: completedDetails,
        ),
      );
    } catch (e) {
      emit(state.copyWith(status: PaymentStatus.failed, error: e.toString()));
    }
  }

  /// Called when we want to execute this payment right away
  Future<void> execute() async {
    await resolve();
    if (state.status == PaymentStatus.resolved) {
      await ok();
      if (state.status == PaymentStatus.callbackComplete) {
        await confirm();
      }
    }
  }
}

class ResolvedDetails {
  final int minAmount;
  final int maxAmount;
  final int? commentAllowed;

  ResolvedDetails({
    required this.minAmount,
    required this.maxAmount,
    required this.commentAllowed,
  });
}

class CallbackDetails {}

class CompletedDetails {}

// States
class PaymentState<
  T extends PaymentParameters,
  RD extends ResolvedDetails,
  CD extends CallbackDetails,
  CmpD extends CompletedDetails
>
    extends Equatable {
  final PaymentStatus status;
  final T params;
  final RD? resolvedDetails;
  final CD? callbackDetails;
  final CmpD? completedDetails;
  final String? error;
  const PaymentState({
    this.resolvedDetails,
    this.completedDetails,
    this.error,
    this.callbackDetails,
    required this.params,
    required this.status,
  });

  PaymentState<T, RD, CD, CmpD> copyWith({
    PaymentStatus? status,
    RD? resolvedDetails,
    CD? callbackDetails,
    CmpD? completedDetails,
    String? error,
  }) {
    return PaymentState(
      status: status ?? this.status,
      resolvedDetails: resolvedDetails ?? this.resolvedDetails,
      callbackDetails: callbackDetails ?? this.callbackDetails,
      completedDetails: completedDetails ?? this.completedDetails,
      error: error ?? this.error,
      params: params,
    );
  }

  @override
  List<Object?> get props => [
    status,
    callbackDetails,
    resolvedDetails,
    completedDetails,
    error,
  ];
}

enum PaymentStatus {
  initial,
  resolveInitiated,
  resolved,
  callbackInitiated,
  callbackComplete,
  inFlight,
  cancelled,
  expired,
  completed,
  failed,
}
