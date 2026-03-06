import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:web3dart/web3dart.dart';

import '../../../injection.dart';
import '../../../util/bitcoin_amount.dart';
import '../../../util/bloc_x.dart';
import '../../../util/custom_logger.dart';
import '../../auth/auth.dart';
import '../../evm/main.dart';
import '../supported_escrow_contract/supported_escrow_contract.dart';

// ── Data base class ─────────────────────────────────────────────────────

/// Common recovery data that every on-chain operation must carry.
///
/// Holds the fields shared across all operations (account index, gas
/// parameters, swap ID, chain/contract identifiers, tx hash).  Concrete
/// subclasses ([EscrowFundData], [EscrowClaimData]) add
/// operation-specific fields and override [operationId].
abstract class OnchainOperationData {
  final int accountIndex;
  final String contractAddress;
  final int chainId;

  /// Gas price (in wei) pinned at estimation time.
  final String? gasPriceWei;

  /// Gas limit pinned at estimation time.
  final String? gasLimit;

  /// The Boltz swap ID of the nested swap-in, if a swap was required.
  final String? swapId;

  /// The on-chain transaction hash, once broadcast.
  final String? txHash;

  const OnchainOperationData({
    required this.accountIndex,
    required this.contractAddress,
    required this.chainId,
    this.gasPriceWei,
    this.gasLimit,
    this.swapId,
    this.txHash,
  });

  /// Unique identifier for this operation (e.g. tradeId).
  String get operationId;

  OnchainOperationData copyWithSwapId(String? swapId);
  OnchainOperationData copyWithTxHash(String? txHash);
  OnchainOperationData copyWithGasEstimate({
    required String gasPriceWei,
    required String gasLimit,
  });

  /// Serialise common fields.  Subclasses should spread this into
  /// their own [toJson] via `...super.baseToJson()`.
  Map<String, dynamic> baseToJson() => {
    'accountIndex': accountIndex,
    'contractAddress': contractAddress,
    'chainId': chainId,
    if (gasPriceWei != null) 'gasPriceWei': gasPriceWei,
    if (gasLimit != null) 'gasLimit': gasLimit,
    if (swapId != null) 'swapId': swapId,
    if (txHash != null) 'txHash': txHash,
  };

  Map<String, dynamic> toJson();
}

// ── State hierarchy ─────────────────────────────────────────────────────

/// Closed set of states for any on-chain operation.
///
/// Because this is [sealed], switch statements over it are exhaustive.
sealed class OnchainOperationState {
  const OnchainOperationState();

  /// The recovery data, non-null once the operation has started.
  OnchainOperationData? get data => null;

  /// Unique operation ID for persistence.
  String? get operationId => data?.operationId;

  /// Whether this is a terminal state (completed / failed).
  bool get isTerminal => false;

  Map<String, dynamic> toJson();

  /// Deserialise from persisted JSON.
  ///
  /// [dataFromJson] is the concrete [OnchainOperationData] factory
  /// (e.g. [EscrowFundData.fromJson]).
  static OnchainOperationState fromJson(
    Map<String, dynamic> json,
    OnchainOperationData Function(Map<String, dynamic>) dataFromJson,
  ) {
    final stateName = json['state'] as String;
    return switch (stateName) {
      'initialised' => const OnchainInitialised(),
      'swapProgress' => OnchainSwapProgress(dataFromJson(json)),
      'txBroadcast' => OnchainTxBroadcast(dataFromJson(json)),
      'txConfirmed' => OnchainTxConfirmed(dataFromJson(json)),
      'error' => OnchainError(
        json['errorMessage'] ?? 'Unknown error',
        data: dataFromJson(json),
      ),
      _ => const OnchainInitialised(),
    };
  }
}

/// Nothing has happened yet.
class OnchainInitialised extends OnchainOperationState {
  const OnchainInitialised();
  @override
  Map<String, dynamic> toJson() => {'state': 'initialised'};
}

/// A swap-in is in progress to fund the on-chain address.
class OnchainSwapProgress extends OnchainOperationState {
  @override
  final OnchainOperationData data;

  /// Live swap state for UI. Null when restored from persisted JSON.
  final SwapInState? swapState;
  OnchainSwapProgress(this.data, {this.swapState});

  @override
  Map<String, dynamic> toJson() => {
    'state': 'swapProgress',
    'id': data.operationId,
    'isTerminal': false,
    'updatedAt': DateTime.now().toIso8601String(),
    ...data.toJson(),
  };
}

/// The on-chain transaction has been (or is about to be) broadcast.
class OnchainTxBroadcast extends OnchainOperationState {
  @override
  final OnchainOperationData data;
  OnchainTxBroadcast(this.data);

  @override
  Map<String, dynamic> toJson() => {
    'state': 'txBroadcast',
    'id': data.operationId,
    'isTerminal': false,
    'updatedAt': DateTime.now().toIso8601String(),
    ...data.toJson(),
  };
}

/// The on-chain transaction has been confirmed.
class OnchainTxConfirmed extends OnchainOperationState {
  @override
  final OnchainOperationData data;

  /// The full transaction info — ephemeral (not serialised).
  final TransactionInformation? transactionInformation;
  OnchainTxConfirmed(this.data, {this.transactionInformation});

  @override
  bool get isTerminal => true;

  @override
  Map<String, dynamic> toJson() => {
    'state': 'txConfirmed',
    'id': data.operationId,
    'isTerminal': true,
    'updatedAt': DateTime.now().toIso8601String(),
    ...data.toJson(),
  };
}

/// The operation has failed.
class OnchainError extends OnchainOperationState {
  @override
  final OnchainOperationData? data;
  final dynamic error;
  final StackTrace? stackTrace;
  OnchainError(this.error, {this.data, this.stackTrace});

  @override
  bool get isTerminal => true;

  @override
  Map<String, dynamic> toJson() => {
    'state': 'error',
    if (data != null) 'id': data!.operationId,
    'isTerminal': true,
    'updatedAt': DateTime.now().toIso8601String(),
    if (data != null) ...data!.toJson(),
    'errorMessage': error.toString(),
  };
}

// ── Base class ──────────────────────────────────────────────────────────

/// Abstract base for any operation that needs to send an on-chain
/// transaction — optionally preceded by a swap-in to cover gas.
///
/// Provides:
/// - State persistence via [OperationStateStore]
/// - HD address resolution ([resolveAddress])
/// - Balance-vs-gas deficit computation ([computeSwapDeficit])
/// - Nested swap-in orchestration ([swapIfNeeded])
/// - Run / recover loop
/// - Receipt confirmation helpers
///
/// Subclasses implement the handful of abstract members that vary per
/// operation (gas estimation, the contract call, state wrappers, etc.).
abstract class OnchainOperation extends Cubit<OnchainOperationState> {
  // ── Dependencies ────────────────────────────────────────────────────

  final CustomLogger logger;
  final Auth auth;
  final Evm evm;
  late final EvmChain chain;
  late final SupportedEscrowContract contract;

  /// HD account index. Defaults to 0; [resolveAddress] may update it.
  int accountIndex = 0;

  late final OperationStateStore stateStore = getIt<OperationStateStore>();

  OnchainOperation(this.auth, this.evm, this.logger, super.initialState);

  /// Safely tear down when a widget disposes.
  ///
  /// If the operation is already terminal, closed, or has not yet started
  /// (still [OnchainInitialised]), closes immediately — the latter ensures
  /// uncommitted operations are removed from the registry when the user
  /// dismisses the dialog before confirming.
  ///
  /// Otherwise, registers a listener that closes once the cubit reaches a
  /// terminal state — allowing in-flight work to finish.
  void detach() =>
      detachOrClose((s) => s.isTerminal || s is OnchainInitialised);

  // ── Abstract: subclasses must implement ─────────────────────────────

  /// A short label used as the [OperationStateStore] namespace
  /// (e.g. `'escrow_fund'`, `'escrow_claim'`).
  String get storeNamespace;

  /// Estimate gas for the concrete contract call.
  Future<GasEstimate> estimateGas();

  /// The total on-chain value the address needs **beyond** gas.
  ///
  /// For a fund operation this is the escrow amount; for a claim it is zero.
  BitcoinAmount get requiredOnchainValue;

  /// Optional pre-flight checks (e.g. `canClaim()`).
  /// Override to add validation before executing. Default is a no-op.
  Future<void> preflight() async {}

  /// Execute the actual contract call. Returns [TransactionInformation].
  Future<TransactionInformation> executeTransaction();

  /// Build the initial recovery data for this operation.
  OnchainOperationData buildInitialData();

  /// Description for the swap-in LN invoice.
  String get swapInvoiceDescription;

  // ── Hooks ─────────────────────────────────────────────────────────

  /// Called before sending the transaction so subclasses can rebuild
  /// contract params from persisted data. Default is a no-op.
  void onBeforeTransaction(OnchainOperationData data) {}

  /// Called after a transaction is confirmed on-chain.
  /// Subclasses can override to log gas usage, etc. Default is a no-op.
  void onTransactionConfirmed(
    OnchainOperationData data,
    TransactionReceipt receipt,
  ) {}

  // ── Persistence ─────────────────────────────────────────────────────

  @override
  void emit(OnchainOperationState state) {
    super.emit(state);
    final id = state.operationId;
    if (id != null) {
      stateStore.write(storeNamespace, id, state.toJson());
    }
  }

  // ── State machine ─────────────────────────────────────────────────

  /// One step of the state machine. Matches on the current state type
  /// and performs exactly one transition.
  Future<void> handle() async {
    try {
      switch (state) {
        case OnchainInitialised():
          await _stepInitialise();
        case OnchainSwapProgress():
          await _stepCheckSwap();
        case OnchainTxBroadcast():
          await _stepBroadcastTx();
        case OnchainTxConfirmed() || OnchainError():
          return;
      }
    } on SwapNotReadyException {
      rethrow;
    } catch (e, st) {
      logger.e(
        'Error during $storeNamespace handle (${state.runtimeType}): $e',
      );
      emit(OnchainError(e, data: state.data, stackTrace: st));
    }
  }

  /// Loops [handle] until the state is terminal.
  Future<void> run() async {
    while (!state.isTerminal) {
      await handle();
    }
  }

  /// Start a new operation.
  Future<void> execute() async {
    await resolveAddress();
    await run();
  }

  /// Resume from a persisted (non-terminal) state.
  ///
  /// Returns `true` if the operation reached a terminal state.
  Future<bool> recover() async {
    if (state.data == null) return false;
    if (state.isTerminal) return true;
    try {
      await run();
      return state.isTerminal;
    } on SwapNotReadyException {
      logger.d(
        'Recovery: nested swap not ready for ${state.data?.operationId}',
      );
      return false;
    } catch (e) {
      logger.e('Recovery error for ${state.data?.operationId}: $e');
      return false;
    }
  }

  // ── Step: initialise ──────────────────────────────────────────────

  /// Build initial data, estimate gas (pinned before any swap),
  /// swap in if needed, then transition to [OnchainTxBroadcast].
  Future<void> _stepInitialise() async {
    await preflight();
    var data = buildInitialData();
    logger.i(
      '$storeNamespace: initialising ${data.operationId} '
      '(accountIndex: $accountIndex)',
    );
    final gasEstimate = await estimateGas();
    onGasEstimated(gasEstimate);
    data = data.copyWithGasEstimate(
      gasPriceWei: gasEstimate.gasPrice.getInWei.toString(),
      gasLimit: gasEstimate.gasLimit.toString(),
    );
    data = await swapIfNeeded(data, gasEstimate);
    emit(OnchainTxBroadcast(data));
  }

  // ── Step: check swap (recovery) ───────────────────────────────────

  /// Checks whether a nested swap-in has completed.
  ///
  /// If complete, emits [OnchainTxBroadcast].
  /// If failed, emits [OnchainError].
  /// If still in progress, throws [SwapNotReadyException].
  Future<void> _stepCheckSwap() async {
    final data = state.data!;

    if (data.swapId != null) {
      final swapJson = await stateStore.read('swap_in', data.swapId!);
      if (swapJson != null) {
        final swapState = SwapInState.fromJson(swapJson);
        if (swapState is SwapInClaimed ||
            swapState is SwapInClaimTxInMempool ||
            swapState is SwapInCompleted) {
          logger.i(
            '$storeNamespace: swap ${data.swapId} completed, proceeding',
          );
          emit(OnchainTxBroadcast(data));
          return;
        }
        if (swapState is SwapInFailed) {
          emit(
            OnchainError('Nested swap failed: ${swapState.error}', data: data),
          );
          return;
        }
      }
    }

    logger.d('$storeNamespace: swap ${data.swapId} not yet complete, exiting');
    throw SwapNotReadyException();
  }

  // ── Step: broadcast tx ────────────────────────────────────────────

  /// Send (or re-check) the on-chain transaction.
  Future<void> _stepBroadcastTx() async {
    var data = state.data!;
    onBeforeTransaction(data);

    // Already broadcast — check receipt.
    if (data.txHash != null) {
      try {
        final receipt = await chain.awaitReceipt(data.txHash!);
        if (isReceiptSuccessful(receipt)) {
          onTransactionConfirmed(data, receipt);
          emit(OnchainTxConfirmed(data));
        } else {
          emit(
            OnchainError('Transaction reverted: ${data.txHash}', data: data),
          );
        }
        return;
      } catch (e) {
        logger.w('$storeNamespace: tx ${data.txHash} not found, re-sending');
      }
    }

    // Send the transaction.
    emit(OnchainTxBroadcast(data));
    final tx = await executeTransaction();
    final txHash = extractTxHash(tx);
    if (txHash != null) {
      data = data.copyWithTxHash(txHash);
      emit(OnchainTxBroadcast(data));
      final receipt = await chain.awaitReceipt(txHash);
      if (!isReceiptSuccessful(receipt)) {
        throw StateError('$storeNamespace transaction reverted (tx: $txHash)');
      }
      onTransactionConfirmed(data, receipt);
      logger.d('$storeNamespace transaction confirmed: $txHash');
      emit(OnchainTxConfirmed(data, transactionInformation: tx));
    } else {
      logger.w(
        'Could not extract tx hash from TransactionInformation, '
        'skipping receipt status check',
      );
      emit(OnchainTxConfirmed(data, transactionInformation: tx));
    }
  }

  // ── Address resolution ────────────────────────────────────────────

  /// Pick the best HD address for this operation.
  ///
  /// Looks for an already-funded address that can cover
  /// [requiredOnchainValue]; otherwise picks the next unused address
  /// (implying a swap-in will be needed).
  Future<void> resolveAddress() async {
    final requiredAmount = requiredOnchainValue;
    final fundedAddresses = await chain.getAddressesWithBalance();

    int resolvedAccountIndex = 0;
    bool foundFunded = false;

    for (final entry in fundedAddresses) {
      if (entry.balance >= requiredAmount) {
        resolvedAccountIndex = entry.accountIndex;
        foundFunded = true;
        logger.i(
          'Using funded address at index $resolvedAccountIndex '
          '(balance: ${entry.balance})',
        );
        break;
      }
    }

    if (!foundFunded) {
      final (:address, :accountIndex) = await chain.getNextUnusedAddress();
      resolvedAccountIndex = accountIndex;
      logger.i(
        'No funded address found, using fresh address at index '
        '$resolvedAccountIndex ($address) — will swap in',
      );
    }

    accountIndex = resolvedAccountIndex;
    onAddressResolved(resolvedAccountIndex);
  }

  /// Called after [resolveAddress] picks an account index so subclasses
  /// can update their contract params with the resolved key.
  void onAddressResolved(int resolvedAccountIndex);

  // ── Swap deficit ──────────────────────────────────────────────────

  /// Check whether the current balance can cover
  /// [requiredOnchainValue] + gas.
  ///
  /// Returns the amount that must be swapped in (zero if sufficient).
  Future<BitcoinAmount> computeSwapDeficit(GasEstimate gasEstimate) async {
    final address = auth.getEvmAddress(accountIndex: accountIndex);
    final balance = await chain.getBalance(address);
    final shortfall = balance - requiredOnchainValue - gasEstimate.fee;

    logger.i(
      'Balance check: have=${balance.getInSats}, '
      'required=${requiredOnchainValue.getInSats}, '
      'gas=${gasEstimate.fee.getInSats}, '
      'shortfall=${shortfall.getInSats}',
    );

    if (shortfall < BitcoinAmount.zero()) {
      final limits = await chain.getSwapInLimits();
      return BitcoinAmount.max(
        limits.min,
        shortfall.abs(),
      ).roundUp(BitcoinUnit.sat);
    }
    return BitcoinAmount.zero();
  }

  // ── Nested swap-in ────────────────────────────────────────────────

  /// Runs a nested swap-in if the balance is insufficient. Returns updated
  /// [data] with the swap ID populated.
  ///
  /// The [gasEstimate] must already be pinned before calling this method.
  /// Emits [OnchainSwapProgress] states as the swap progresses.
  Future<OnchainOperationData> swapIfNeeded(
    OnchainOperationData data,
    GasEstimate gasEstimate,
  ) async {
    final deficit = await computeSwapDeficit(gasEstimate);
    if (deficit <= BitcoinAmount.zero()) return data;

    final evmKey = auth.getActiveEvmKey(accountIndex: accountIndex);

    // First pass: estimate swap fees.
    SwapInOperation swapEstimation = chain.swapIn(
      SwapInParams(
        evmKey: evmKey,
        accountIndex: accountIndex,
        amount: deficit,
        invoiceDescription: swapInvoiceDescription,
      ),
    );
    final swapFees = await swapEstimation.estimateFees();

    // Second pass: create the real swap with amount + overhead.
    SwapInOperation swap = chain.swapIn(
      SwapInParams(
        evmKey: evmKey,
        accountIndex: accountIndex,
        amount: (deficit + swapFees.totalFees).roundUp(BitcoinUnit.sat),
        invoiceDescription: swapInvoiceDescription,
      ),
    );

    String? swapId;
    final sub = swap.stream.listen((swapState) {
      swapId ??= swapState.operationId;
      emit(
        OnchainSwapProgress(data.copyWithSwapId(swapId), swapState: swapState),
      );
    });

    try {
      await swap.execute();
    } finally {
      await sub.cancel();
    }

    // If the swap ended in a failed state, do not proceed to the on-chain tx.
    if (swap.state is SwapInFailed) {
      final failed = swap.state as SwapInFailed;
      throw StateError('Nested swap-in failed: ${failed.error}');
    }

    return data.copyWithSwapId(swapId);
  }

  /// Called after gas estimation so subclasses can pin the estimate onto
  /// their contract params. Default is a no-op.
  void onGasEstimated(GasEstimate estimate) {}

  // ── Tx helpers ────────────────────────────────────────────────────

  String? extractTxHash(TransactionInformation tx) {
    final dynamic d = tx;
    final hash = d.hash?.toString() ?? d.id?.toString();
    if (hash == null || hash.isEmpty) return null;
    return hash;
  }

  bool isReceiptSuccessful(TransactionReceipt receipt) {
    final dynamic status = (receipt as dynamic).status;
    if (status == null) return true;
    if (status is bool) return status;
    if (status is int) return status == 1;
    if (status is BigInt) return status == BigInt.one;
    final normalized = status.toString().toLowerCase();
    return normalized == '1' || normalized == '0x1' || normalized == 'true';
  }
}

/// Signal that [stepCheckSwap] cannot make progress because the nested
/// swap-in has not completed yet. Caught by [recover] to return `false`.
class SwapNotReadyException implements Exception {
  @override
  String toString() => 'Nested swap not yet complete';
}
