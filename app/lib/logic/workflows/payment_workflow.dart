import 'package:hostr/core/main.dart';
import 'package:injectable/injectable.dart';

/// Workflow class handling multi-step payment orchestration.
/// Cubits delegate business process steps to this workflow and manage state transitions.
@injectable
class PaymentWorkflow {
  final CustomLogger _logger = CustomLogger();

  /// Resolves payment details (fees, limits, etc.) for a given payment method.
  /// Called by PaymentCubit.resolve()
  Future<RD> resolvePayment<RD>({
    required Future<RD> Function() resolver,
    required String paymentMethod,
  }) async {
    _logger.i('Resolving payment via $paymentMethod');
    try {
      final result = await resolver();
      _logger.i('Payment resolved successfully');
      return result;
    } catch (e) {
      _logger.e('Payment resolution failed: $e');
      rethrow;
    }
  }

  /// Executes optional callback step (e.g., LNURL fetch invoice).
  /// Called by PaymentCubit.ok()
  Future<CD> executeCallback<CD>({
    required Future<CD> Function() callback,
    required String paymentMethod,
  }) async {
    _logger.i('Executing callback for $paymentMethod');
    try {
      final result = await callback();
      _logger.i('Callback executed successfully');
      return result;
    } catch (e) {
      _logger.e('Callback failed: $e');
      rethrow;
    }
  }

  /// Completes the final payment execution.
  /// Called by PaymentCubit.confirm()
  Future<CmpD> completePayment<CmpD>({
    required Future<CmpD> Function() complete,
    required String paymentMethod,
  }) async {
    _logger.i('Completing payment via $paymentMethod');
    try {
      final result = await complete();
      _logger.i('Payment completed successfully');
      return result;
    } catch (e) {
      _logger.e('Payment completion failed: $e');
      rethrow;
    }
  }

  /// Executes full automated payment flow: resolve → callback → complete.
  /// Called by PaymentCubit.execute()
  Future<CmpD> executeFullPayment<RD, CD, CmpD>({
    required Future<RD> Function() resolver,
    required Future<CD> Function() callback,
    required Future<CmpD> Function() complete,
    required String paymentMethod,
    required void Function(String phase) onPhaseChange,
  }) async {
    _logger.i('Starting full payment flow for $paymentMethod');

    try {
      // Phase 1: Resolve
      onPhaseChange('resolving');
      await resolvePayment(resolver: resolver, paymentMethod: paymentMethod);

      // Phase 2: Callback
      onPhaseChange('callback');
      await executeCallback(callback: callback, paymentMethod: paymentMethod);

      // Phase 3: Complete
      onPhaseChange('completing');
      final result = await completePayment(
        complete: complete,
        paymentMethod: paymentMethod,
      );

      _logger.i('Full payment flow completed successfully');
      return result;
    } catch (e) {
      _logger.e('Full payment flow failed: $e');
      rethrow;
    }
  }
}
