import 'package:bloc/bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../injection.dart';
import '../../../../util/main.dart';
import '../../../auth/auth.dart';
import '../operation_state_store.dart';
import 'swap_in_models.dart';
import 'swap_in_state.dart';

abstract class SwapInOperation extends Cubit<SwapInState> {
  final CustomLogger logger;
  final Auth auth;
  final SwapInParams params;

  late final OperationStateStore _stateStore = getIt<OperationStateStore>();

  SwapInOperation({
    required this.auth,
    required this.logger,
    @factoryParam required this.params,
    SwapInState? initialState,
  }) : super(initialState ?? const SwapInInitialised());

  /// Persist every state that carries data.
  @override
  void emit(SwapInState state) {
    super.emit(state);
    final id = state.operationId;
    if (id != null) {
      _stateStore.write('swap_in', id, state.toJson());
    }
  }

  Future<SwapInFees> estimateFees();

  /// Fetches the chain's minimum and maximum swap-in amounts.
  Future<({BitcoinAmount min, BitcoinAmount max})> getSwapLimits();

  /// Reads the current state and performs exactly one state transition.
  ///
  /// Implementors switch on [state] and run the appropriate step:
  ///
  /// | State group                                     | Action           |
  /// |-------------------------------------------------|------------------|
  /// | `Initialised`                                   | Create Boltz swap |
  /// | `RequestCreated / AwaitingOnChain / PaymentProgress` | Ensure lockup funded |
  /// | `Funded`                                        | Claim on-chain   |
  /// | `Claimed`                                       | Confirm claim receipt |
  /// | `Completed / Failed`                            | No-op (terminal) |
  Future<void> handle();

  /// Loops [handle] until the state is terminal.
  Future<void> run() async {
    while (!state.isTerminal) {
      await handle();
    }
  }

  /// Start a new swap-in from [SwapInInitialised].
  Future<void> execute() => run();

  /// Resume from a persisted (non-terminal) state.
  ///
  /// Returns `true` if the swap reached a terminal state.
  Future<bool> recover() async {
    if (state.data == null) return false;
    if (state.isTerminal) return true;
    try {
      await run();
      return state.isTerminal;
    } catch (e) {
      logger.e('Recovery error for ${state.data?.boltzId}: $e');
      return false;
    }
  }

  /// Fetches chain limits and clamps [params.minAmount] / [params.maxAmount]
  /// to the chain's supported range. Re-emits [SwapInInitialised] so the
  /// UI picks up the resolved range.
  Future<void> init() async {
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

      // Use super.emit to avoid persisting an Initialised state.
      super.emit(const SwapInInitialised());
    } catch (e) {
      logger.w('Failed to fetch swap limits: $e');
    }
  }

  /// Updates the swap amount (must be within min/max range if set).
  void updateAmount(BitcoinAmount amount) {
    if (params.minAmount != null && amount < params.minAmount!) {
      logger.w('Amount $amount below minimum ${params.minAmount}');
      return;
    }
    if (params.maxAmount != null && amount > params.maxAmount!) {
      logger.w('Amount $amount exceeds maximum ${params.maxAmount}');
      return;
    }
    params.amount = amount;
    super.emit(const SwapInInitialised());
  }
}
