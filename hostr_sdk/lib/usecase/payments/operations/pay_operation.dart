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
  final Nwc nwc;

  T params;
  RD? resolvedDetails;
  CD? callbackDetails;
  CmpD? completedDetails;
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
      emit(PayResolved(params: params, details: resolvedDetails!));
    } catch (e) {
      emit(PayFailed(e.toString(), params: params));
      rethrow;
    }
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
