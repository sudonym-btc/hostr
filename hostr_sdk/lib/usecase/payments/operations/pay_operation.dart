import 'dart:math' as math;

import 'package:hostr_sdk/util/bitcoin_amount.dart';
import 'package:hostr_sdk/util/custom_logger.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../nwc/nwc.dart';
import 'pay_models.dart';
import 'pay_state.dart';

abstract class PayOperation<
  T extends PayParameters,
  RD extends ResolvedDetails,
  CD extends CallbackDetails,
  CmpD extends CompletedDetails
>
    extends Cubit<PayState> {
  final CustomLogger logger = CustomLogger();
  final Nwc nwc;

  T params;
  RD? resolvedDetails;
  CD? callbackDetails;
  CmpD? completedDetails;
  int? _effectiveMinAmount;
  int? _effectiveMaxAmount;
  PayOperation({@factoryParam required this.params, required this.nwc})
    : super(PayInitialised(params: params));
  Future<RD> resolver();
  Future<CD> finalizer();
  Future<CmpD> completer();

  void setParams(T params) {
    this.params = params;
    resolvedDetails = null;
    callbackDetails = null;
    completedDetails = null;
    emit(PayInitialised(params: params));
  }

  /// Called upon initialization
  /// Estimates fees etc
  Future<void> resolve() async {
    emit(PayResolveInitiated(params: params));
    try {
      resolvedDetails = await resolver();
    } catch (e) {
      emit(PayFailed(e.toString(), params: params));
      rethrow;
    }

    // Compute effective range by clamping resolved limits with pay-param limits
    final resolvedMin = resolvedDetails!.minAmount;
    final resolvedMax = resolvedDetails!.maxAmount;
    final effectiveMin = params.minSendable != null
        ? math.max(resolvedMin, params.minSendable!)
        : resolvedMin;
    final effectiveMax = params.maxSendable != null
        ? math.min(resolvedMax, params.maxSendable!)
        : resolvedMax;

    if (effectiveMin > effectiveMax) {
      final msg =
          'No valid amount range: parameter limits '
          '[${params.minSendable ?? 'none'}, ${params.maxSendable ?? 'none'}] '
          'do not overlap with resolved limits [$resolvedMin, $resolvedMax]';
      emit(PayFailed(msg, params: params));
      throw Exception(msg);
    }

    _effectiveMinAmount = effectiveMin;
    _effectiveMaxAmount = effectiveMax;

    emit(
      PayResolved(
        params: params,
        details: resolvedDetails!,
        effectiveMinAmount: effectiveMin,
        effectiveMaxAmount: effectiveMax,
      ),
    );
  }

  /// Updates the payment amount (must be within the effective range).
  void updateAmount(BitcoinAmount amount) {
    if (resolvedDetails == null ||
        _effectiveMinAmount == null ||
        _effectiveMaxAmount == null) {
      return;
    }
    final msats = amount.getInMSats.toInt();
    if (msats < _effectiveMinAmount! || msats > _effectiveMaxAmount!) {
      logger.w(
        'Amount $msats msats out of range [$_effectiveMinAmount, $_effectiveMaxAmount]',
      );
      return;
    }
    params.amount = amount;
    // Emit a resolve-initiated state first to force BlocBuilder to rebuild,
    // then immediately emit the resolved state with the updated amount.
    emit(PayResolveInitiated(params: params));
    emit(
      PayResolved(
        params: params,
        details: resolvedDetails!,
        effectiveMinAmount: _effectiveMinAmount!,
        effectiveMaxAmount: _effectiveMaxAmount!,
      ),
    );
  }

  Future<void> finalize() async {
    emit(PayCallbackInitiated(params: params));
    try {
      callbackDetails = await finalizer();
      emit(PayCallbackComplete(params: params, details: callbackDetails!));
    } catch (e) {
      emit(PayFailed(e.toString(), params: params));
      rethrow;
    }
  }

  Future<void> complete() async {
    emit(PayInFlight(params: params));
    try {
      if (nwc.getActiveConnection() == null) {
        print('No NWC connections available');
        emit(
          PayExternalRequired(
            params: params,
            callbackDetails: callbackDetails!,
          ),
        );
        return;
      }
      completedDetails = await completer();
      emit(PayCompleted(params: params, details: completedDetails!));
    } catch (e) {
      emit(PayFailed(e.toString(), params: params));
      rethrow;
    } finally {
      await close();
    }
  }

  /// Called when we want to execute this payment right away
  Future<void> execute() async {
    await resolve();
    await finalize();
    await complete();
  }
}
