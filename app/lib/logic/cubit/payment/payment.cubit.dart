import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:wallet/wallet.dart';

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
