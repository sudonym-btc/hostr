import 'package:injectable/injectable.dart';

import '../../../../config.dart';
import '../../../../injection.dart';
import '../../../../util/main.dart';
import '../../../auth/auth.dart';
import '../operation_machine.dart';
import '../operation_state_store.dart';
import 'swap_in_models.dart';
import 'swap_in_state.dart';

/// All steps in the swap-in lifecycle.
///
/// Used as the type-safe step identifier for [OperationMachine].
/// The [StepGuard] declarations in [SwapInOperation.steps] and the
/// exhaustive `switch` in [executeStep] both key off this enum,
/// so the compiler catches any mismatch.
enum SwapInStep {
  createSwap,
  dispatchPayment,
  ensureFunded,
  claimRelay,
  checkMempool,
  confirmClaim,
}

abstract class SwapInOperation
    extends OperationMachine<SwapInState, SwapInStep> {
  final Auth auth;
  final SwapInParams params;

  /// Optional callback for emitting background progress notifications.
  ///
  /// Called with `(notificationId, message)` at key state transitions.
  /// Set this before calling [execute] or [recover] to receive
  /// notifications (e.g. for OS notification updates in background tasks).
  void Function(String notificationId, String message)? onProgress;

  SwapInOperation({
    required this.auth,
    required CustomLogger logger,
    @factoryParam required this.params,
    SwapInState? initialState,
  }) : super(
         store: getIt<OperationStateStore>(),
         logger: logger.scope('swap-in'),
         initialState: initialState ?? const SwapInInitialised(),
       ) {
    _autoWireNotifications();
  }

  /// Auto-wires [onProgress] from [HostrConfig.showNotification] so that
  /// every swap — foreground or background — gets OS notifications
  /// without the caller having to set it manually.
  void _autoWireNotifications() {
    final show = getIt<HostrConfig>().showNotification;
    if (show == null) return;
    onProgress = (id, message) =>
        show(id: id.hashCode, title: 'Hostr', body: message);
  }

  /// The notification ID for progress callbacks.
  ///
  /// Uses [SwapInParams.parentOperationId] when the swap is nested inside
  /// a parent operation (e.g. escrow-fund), otherwise falls back to the
  /// persisted [SwapInData.parentOperationId], then to the Boltz swap ID.
  String? get _notificationId =>
      params.parentOperationId ??
      state.data?.parentOperationId ??
      state.data?.boltzId;

  /// Maps a [SwapInState] to a human-readable notification message.
  /// Returns `null` for states that should not trigger a notification.
  String? _notificationMessage(SwapInState s) => switch (s) {
    SwapInInvoicePaid() => 'Invoice paid!',
    // SwapInFunded() => 'Swap funds received, claiming\u2026',
    // SwapInCompleted() => 'Swap completed',
    // SwapInFailed() => 'Swap failed',
    _ => null,
  };

  @override
  void emit(SwapInState state) {
    super.emit(state);
    _fireNotification(state);
  }

  void _fireNotification(SwapInState s) {
    final cb = onProgress;
    if (cb == null) {
      logger.d(
        '_fireNotification: onProgress is null — skipping (${s.runtimeType})',
      );
      return;
    }
    final id = _notificationId;
    if (id == null) {
      logger.d(
        '_fireNotification: notificationId is null — skipping (${s.runtimeType})',
      );
      return;
    }
    final message = _notificationMessage(s);
    if (message == null) return; // expected for non-notifiable states
    logger.i('_fireNotification: id=$id message="$message"');
    cb(id, message);
  }

  @override
  Map<String, Object?> get telemetryAttributes => {
    ...super.telemetryAttributes,
    'hostr.swap.account_index': state.data?.accountIndex ?? params.accountIndex,
    'hostr.swap.amount_sats':
        state.data?.onchainAmountSat ?? params.amount.getInSats,
    if (state.data?.boltzId != null) 'hostr.swap.id': state.data!.boltzId,
    if (state.data?.lockupTxHash != null)
      'hostr.swap.lockup_tx_hash': state.data!.lockupTxHash,
    if (state.data?.claimTxHash != null)
      'hostr.swap.claim_tx_hash': state.data!.claimTxHash,
    if (state.data?.lastBoltzStatus != null)
      'hostr.swap.last_boltz_status': state.data!.lastBoltzStatus,
  };

  // ── OperationMachine contract ──────────────────────────────────────

  @override
  String get namespace => 'swap_in';

  @override
  List<StepGuard<SwapInStep>> get steps => const [
    StepGuard(
      step: SwapInStep.createSwap,
      allowedFrom: {'initialised'},
      backgroundAllowed: false,
    ),
    StepGuard(
      step: SwapInStep.dispatchPayment,
      allowedFrom: {'requestCreated'},
      staleTimeout: Duration(minutes: 45),
      backgroundAllowed: false,
    ),
    StepGuard(
      step: SwapInStep.ensureFunded,
      allowedFrom: {
        'awaitingOnChain',
        'paymentProgress',
        'paymentDispatching', // recovery: fg may have crashed after dispatch
      },
      backgroundAllowed: true,
    ),
    StepGuard(
      step: SwapInStep.claimRelay,
      allowedFrom: {'funded', 'claimRelaying'},
      staleTimeout: Duration(minutes: 30),
      backgroundAllowed: true,
    ),
    StepGuard(
      step: SwapInStep.checkMempool,
      allowedFrom: {'claimed'},
      backgroundAllowed: true,
    ),
    StepGuard(
      step: SwapInStep.confirmClaim,
      allowedFrom: {'claimTxInMempool'},
      backgroundAllowed: true,
    ),
  ];

  @override
  SwapInState stateFromJson(Map<String, dynamic> json) =>
      SwapInState.fromJson(json);

  @override
  SwapInState? busyStateFor(SwapInStep step, SwapInState current) {
    final data = current.data;
    if (data == null) return null;
    return switch (step) {
      SwapInStep.dispatchPayment => SwapInPaymentDispatching(data),
      SwapInStep.claimRelay => SwapInClaimRelaying(data),
      _ => null,
    };
  }

  @override
  void emitError(
    Object error,
    SwapInState from,
    StackTrace? st, {
    String? stepName,
  }) {
    logger.e('Swap error from "${from.stateName}": $error');
    emit(
      SwapInFailed(
        error,
        data: from.data,
        stackTrace: st,
        failedAtStep: stepName,
      ),
    );
  }

  // ── Abstract: chain-specific ──────────────────────────────────────

  Future<SwapInFees> estimateFees();

  /// Fetches the chain's minimum and maximum swap-in amounts.
  Future<({BitcoinAmount min, BitcoinAmount max})> getSwapLimits();

  // ── Init & amount adjustment (UI-facing) ──────────────────────────

  /// Fetches chain limits and clamps [params.minAmount] / [params.maxAmount]
  /// to the chain's supported range. Re-emits [SwapInInitialised] so the
  /// UI picks up the resolved range.
  Future<void> init() => logger.span('init', () async {
    applyTelemetry();
    try {
      final limits = await getSwapLimits();

      params.minAmount = params.minAmount != null
          ? BitcoinAmount.max(params.minAmount!, limits.min)
          : limits.min;

      params.maxAmount = params.maxAmount != null
          ? BitcoinAmount.min(params.maxAmount!, limits.max)
          : limits.max;

      if (params.amount < params.minAmount!) {
        params.amount = params.minAmount!;
      } else if (params.amount > params.maxAmount!) {
        params.amount = params.maxAmount!;
      }

      logger.i(
        'Swap range resolved: '
        'min=${params.minAmount?.getInSats}, '
        'max=${params.maxAmount?.getInSats}, '
        'selected=${params.amount.getInSats}',
      );

      // Use super.emit to avoid persisting an Initialised state.
      super.emit(const SwapInInitialised());
    } catch (e) {
      logger.w('Failed to fetch swap limits: $e');
    }
  });

  /// Updates the swap amount (must be within min/max range if set).
  void updateAmount(BitcoinAmount amount) =>
      logger.spanSync('updateAmount', () {
        if (params.minAmount != null && amount < params.minAmount!) {
          logger.w('Amount $amount below minimum ${params.minAmount}');
          return;
        }
        if (params.maxAmount != null && amount > params.maxAmount!) {
          logger.w('Amount $amount exceeds maximum ${params.maxAmount}');
          return;
        }
        params.amount = amount;
        logger.d('Swap amount updated to ${params.amount.getInSats} sats');
        super.emit(const SwapInInitialised());
      });
}
