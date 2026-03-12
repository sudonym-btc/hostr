import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';

import '../../../config.dart';
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

  /// Full transaction information, persisted for recovery and consumers.
  final TransactionInformation? transactionInformation;

  /// Full transaction receipt, persisted once confirmation completes.
  final TransactionReceipt? transactionReceipt;

  const OnchainOperationData({
    required this.accountIndex,
    required this.contractAddress,
    required this.chainId,
    this.gasPriceWei,
    this.gasLimit,
    this.swapId,
    this.txHash,
    this.transactionInformation,
    this.transactionReceipt,
  });

  /// Unique identifier for this operation (e.g. tradeId).
  String get operationId;

  OnchainOperationData copyWithSwapId(String? swapId);
  OnchainOperationData copyWithTxHash(String? txHash);
  OnchainOperationData copyWithTransactionInformation(
    TransactionInformation? transactionInformation,
  );
  OnchainOperationData copyWithTransactionReceipt(
    TransactionReceipt? transactionReceipt,
  );
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
    if (transactionInformation != null)
      'transactionInformation': serializeTransactionInformation(
        transactionInformation!,
      ),
    if (transactionReceipt != null)
      'transactionReceipt': serializeTransactionReceipt(transactionReceipt!),
  };

  Map<String, dynamic> toJson();
}

// ── State hierarchy ─────────────────────────────────────────────────────

/// Closed set of states for any on-chain operation.
///
/// Because this is [sealed], switch statements over it are exhaustive.
sealed class OnchainOperationState implements MachineState {
  const OnchainOperationState();

  /// The recovery data, non-null once the operation has started.
  OnchainOperationData? get data => null;

  /// Unique operation ID for persistence.
  @override
  String? get operationId => data?.operationId;

  /// Whether this is a terminal state (completed / failed).
  @override
  bool get isTerminal => false;

  /// Short string key identifying this state variant.
  @override
  String get stateName;

  /// Always `null` for on-chain operations ([OnchainError] is always
  /// terminal, so recovery via `failedAtStep` does not apply).
  @override
  String? get failedAtStep => null;

  @override
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
      'txBroadcasting' => OnchainTxBroadcasting(dataFromJson(json)),
      'txSent' => OnchainTxSent(dataFromJson(json)),
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
  String get stateName => 'initialised';
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
  String get stateName => 'swapProgress';
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
  String get stateName => 'txBroadcast';
  @override
  Map<String, dynamic> toJson() => {
    'state': 'txBroadcast',
    'id': data.operationId,
    'isTerminal': false,
    'updatedAt': DateTime.now().toIso8601String(),
    ...data.toJson(),
  };
}

/// The on-chain transaction is actively being broadcast.
///
/// This is a **busy state** — written to the store atomically via CAS
/// before `_stepBroadcastTx` begins.  A second process seeing this state
/// will back off (or reclaim it after `staleTimeout`).
class OnchainTxBroadcasting extends OnchainOperationState {
  @override
  final OnchainOperationData data;
  OnchainTxBroadcasting(this.data);

  @override
  String get stateName => 'txBroadcasting';
  @override
  Map<String, dynamic> toJson() => {
    'state': 'txBroadcasting',
    'id': data.operationId,
    'isTerminal': false,
    'updatedAt': DateTime.now().toIso8601String(),
    ...data.toJson(),
  };
}

/// The on-chain transaction has been broadcast and the txHash is persisted.
///
/// This is the post-side-effect state for `broadcastTx`.  The idempotent
/// `confirmTx` step picks up from here — any process can run it.
class OnchainTxSent extends OnchainOperationState {
  @override
  final OnchainOperationData data;
  OnchainTxSent(this.data);

  @override
  String get stateName => 'txSent';
  @override
  Map<String, dynamic> toJson() => {
    'state': 'txSent',
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
  OnchainTxConfirmed(this.data);

  @override
  String get stateName => 'txConfirmed';
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
  String get stateName => 'error';
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

// ── Step enum ───────────────────────────────────────────────────────────

/// All steps in the on-chain operation lifecycle.
enum OnchainStep { initialise, checkSwap, broadcastTx, confirmTx }

// ── Base class ──────────────────────────────────────────────────────────

/// Abstract base for any operation that needs to send an on-chain
/// transaction — optionally preceded by a swap-in to cover gas.
///
/// Provides:
/// - State persistence via [OperationMachine] (CAS, run loop)
/// - HD address resolution ([resolveAddress])
/// - Balance-vs-gas deficit computation ([computeSwapDeficit])
/// - Nested swap-in orchestration ([swapIfNeeded])
/// - Receipt confirmation helpers
///
/// Subclasses implement the handful of abstract members that vary per
/// operation (gas estimation, the contract call, state wrappers, etc.).
abstract class OnchainOperation
    extends OperationMachine<OnchainOperationState, OnchainStep> {
  // ── Dependencies ────────────────────────────────────────────────────

  final Auth auth;
  final Evm evm;
  late final EvmChain chain;
  late final SupportedEscrowContract contract;

  /// HD account index. Defaults to 0; [resolveAddress] may update it.
  int accountIndex = 0;

  /// Optional callback for emitting background progress notifications.
  ///
  /// Called with `(notificationId, message)` at key state transitions.
  /// Set this before calling [execute] or [recover] to receive
  /// notifications (e.g. for OS notification updates in background tasks).
  void Function(String notificationId, String message)? onProgress;

  OnchainOperation(
    this.auth,
    this.evm,
    CustomLogger logger,
    OnchainOperationState initialState,
  ) : super(
        store: getIt<OperationStateStore>(),
        logger: logger,
        initialState: initialState,
      ) {
    _autoWireNotifications();
  }

  /// Auto-wires [onProgress] from [HostrConfig.showNotification] so that
  /// every operation — foreground or background — gets OS notifications
  /// without the caller having to set it manually.
  void _autoWireNotifications() {
    final show = getIt<HostrConfig>().showNotification;
    if (show == null) return;
    onProgress = (id, message) =>
        show(id: id.hashCode, title: 'Hostr', body: message);
  }

  /// Maps an [OnchainOperationState] to a notification message.
  /// Returns `null` for states that should not trigger a notification.
  String? _notificationMessage(OnchainOperationState s) => switch (s) {
    // OnchainTxBroadcast() => 'Broadcasting deposit transaction\u2026',
    // OnchainTxSent() => 'Deposit transaction sent, awaiting confirmation\u2026',
    // OnchainTxConfirmed() => 'Deposit completed',
    // OnchainError() => 'Deposit failed',
    _ => null,
  };

  @override
  void emit(OnchainOperationState state) {
    super.emit(state);
    _fireNotification(state);
  }

  void _fireNotification(OnchainOperationState s) {
    final cb = onProgress;
    if (cb == null) {
      logger.d(
        '_fireNotification: onProgress is null — skipping (${s.runtimeType})',
      );
      return;
    }
    final id = s.data?.operationId;
    if (id == null) {
      logger.d(
        '_fireNotification: operationId is null — skipping (${s.runtimeType})',
      );
      return;
    }
    final message = _notificationMessage(s);
    if (message == null) return; // expected for non-notifiable states
    logger.i('_fireNotification: id=$id message="$message"');
    cb(id, message);
  }

  /// Safely tear down when a widget disposes.
  void detach() =>
      detachOrClose((s) => s.isTerminal || s is OnchainInitialised);

  // ── OperationMachine contract ──────────────────────────────────────

  /// A short label used as the [OperationStateStore] namespace
  /// (e.g. `'escrow_fund'`, `'escrow_claim'`).
  @override
  String get namespace;

  @override
  List<StepGuard<OnchainStep>> get steps => const [
    StepGuard(
      step: OnchainStep.initialise,
      allowedFrom: {'initialised'},
      backgroundAllowed: false,
    ),
    StepGuard(
      step: OnchainStep.checkSwap,
      allowedFrom: {'swapProgress'},
      backgroundAllowed: true,
    ),
    StepGuard(
      step: OnchainStep.broadcastTx,
      allowedFrom: {'txBroadcast', 'txBroadcasting'},
      staleTimeout: Duration(minutes: 10),
      backgroundAllowed: true,
    ),
    StepGuard(
      step: OnchainStep.confirmTx,
      allowedFrom: {'txSent'},
      backgroundAllowed: true,
    ),
  ];

  @override
  OnchainOperationState stateFromJson(Map<String, dynamic> json) {
    return OnchainOperationState.fromJson(json, dataFromJson);
  }

  @override
  OnchainOperationState? busyStateFor(
    OnchainStep step,
    OnchainOperationState current,
  ) {
    final data = current.data;
    if (data == null) return null;
    return switch (step) {
      OnchainStep.broadcastTx => OnchainTxBroadcasting(data),
      _ => null,
    };
  }

  @override
  Future<OnchainOperationState> executeStep(OnchainStep step) =>
      logger.span('executeStep', () async {
        return switch (step) {
          OnchainStep.initialise => await _stepInitialise(),
          OnchainStep.checkSwap => await _stepCheckSwap(),
          OnchainStep.broadcastTx => await _stepBroadcastTx(),
          OnchainStep.confirmTx => await _stepConfirmTx(),
        };
      });

  @override
  void emitError(
    Object error,
    OnchainOperationState fromState,
    StackTrace? st, {
    String? stepName,
  }) => logger.spanSync('emitError', () {
    logger.e('Error in step "$stepName": $error', error: error, stackTrace: st);
    if (error is SwapNotReadyException) {
      // Not a real error — the nested swap isn't done yet.
      // Don't emit an error state; the run loop will stop naturally.
      logger.d('Nested swap not ready for ${fromState.data?.operationId}');
      return;
    }
    emit(OnchainError(error, data: fromState.data, stackTrace: st));
  });

  // ── Abstract: subclasses must implement ─────────────────────────────

  /// Estimate gas for the concrete contract call.
  Future<GasEstimate> estimateGas();

  /// The total on-chain value the address needs **beyond** gas.
  BitcoinAmount get requiredOnchainValue;

  /// Optional pre-flight checks (e.g. `canClaim()`).
  Future<void> preflight() async {}

  /// Execute the actual contract call. Returns [TransactionInformation].
  Future<TransactionInformation> executeTransaction();

  Future<String> broadcastContractCallIntent(
    ContractCallIntent intent,
    EthPrivateKey credentials,
  ) => logger.span('broadcastContractCallIntent', () async {
    try {
      await contract.ensureDeployed();
      final chainId = (await chain.getChainId()).toInt();
      return await chain.client.sendTransaction(
        credentials,
        intent.toTransaction(),
        chainId: chainId,
      );
    } catch (error) {
      throw contract.decodeWriteError(error);
    }
  });

  Future<TransactionInformation> submitContractCallIntent(
    ContractCallIntent intent,
    EthPrivateKey credentials,
  ) => logger.span('submitContractCallIntent', () async {
    final txHash = await broadcastContractCallIntent(intent, credentials);
    return await chain.awaitTransaction(txHash);
  });

  /// Build the initial recovery data for this operation.
  OnchainOperationData buildInitialData();

  /// Description for the swap-in LN invoice.
  String get swapInvoiceDescription;

  /// Optional override for the Boltz reverse swap claim address.
  ///
  /// When set, the nested swap lockup will use this address as the
  /// EtherSwap `claimAddress`.
  ///
  /// For the normal relay flow this is usually the RIF smart wallet. For
  /// atomic `claimSwapAndFund(...)` flows this must be the signer address
  /// whose signature will authorize the claim.
  EthereumAddress? get swapClaimAddress => null;

  /// Optional override for the EtherSwap claim signature destination.
  ///
  /// When set, the nested swap will prepare EIP-712 claim signature parts so
  /// the funds are paid to this destination (`msg.sender`) when the custom
  /// claim callback executes.
  EthereumAddress? get swapClaimDestination => null;

  /// Deserialise the concrete [OnchainOperationData] subclass from JSON.
  ///
  /// Subclasses must override to provide their specific factory
  /// (e.g. `EscrowFundData.fromJson`). Used by [stateFromJson].
  OnchainOperationData dataFromJson(Map<String, dynamic> json);

  // ── Hooks ─────────────────────────────────────────────────────────

  /// Called before sending the transaction so subclasses can rebuild
  /// contract params from persisted data. Default is a no-op.
  void onBeforeTransaction(OnchainOperationData data) {}

  /// Called after a transaction is confirmed on-chain.
  void onTransactionConfirmed(
    OnchainOperationData data,
    TransactionReceipt receipt,
  ) {}

  // ── Entry points ──────────────────────────────────────────────────

  /// Start a new operation (resolves address, then runs the loop).
  @override
  Future<void> execute() async {
    await resolveAddress();
    await run();
  }

  // ── Step: initialise ──────────────────────────────────────────────

  /// Build initial data, estimate gas (pinned before any swap),
  /// swap in if needed, then transition to [OnchainTxBroadcast].
  Future<OnchainOperationState> _stepInitialise() =>
      logger.span('stepInitialise', () async {
        await preflight();
        var data = buildInitialData();
        logger.i(
          '$namespace: initialising ${data.operationId} '
          '(accountIndex: $accountIndex)',
        );
        final gasEstimate = await estimateGas();
        onGasEstimated(gasEstimate);
        data = data.copyWithGasEstimate(
          gasPriceWei: gasEstimate.gasPrice.getInWei.toString(),
          gasLimit: gasEstimate.gasLimit.toString(),
        );
        data = await swapIfNeeded(data, gasEstimate);
        return OnchainTxBroadcast(data);
      });

  // ── Step: check swap (recovery) ───────────────────────────────────

  /// Checks whether a nested swap-in has completed.
  ///
  /// If complete, returns [OnchainTxBroadcast].
  /// If failed, returns [OnchainError].
  /// If still in progress, throws [SwapNotReadyException].
  Future<OnchainOperationState> _stepCheckSwap() =>
      logger.span('stepCheckSwap', () async {
        final data = state.data!;

        if (data.swapId != null) {
          final swapJson = await store.read('swap_in', data.swapId!);
          if (swapJson != null) {
            final swapState = SwapInState.fromJson(swapJson);
            if (swapState is SwapInClaimed ||
                swapState is SwapInClaimTxInMempool ||
                swapState is SwapInCompleted) {
              logger.i('$namespace: swap ${data.swapId} completed, proceeding');
              return OnchainTxBroadcast(onNestedSwapFinished(data, swapState));
            }
            if (swapState is SwapInFailed) {
              return OnchainError(
                'Nested swap failed: ${swapState.error}',
                data: data,
              );
            }
          }
        }

        logger.d('$namespace: swap ${data.swapId} not yet complete, exiting');
        throw SwapNotReadyException();
      });

  // ── Step: broadcast tx (side-effect — busy-guarded) ────────────────

  /// Send the on-chain transaction and persist the txHash.
  ///
  /// This step is protected by the `txBroadcasting` busy guard so only
  /// one process ever submits the transaction.  It does NOT wait for
  /// the receipt — that's the job of [_stepConfirmTx], which any
  /// process can pick up immediately.
  Future<OnchainOperationState>
  _stepBroadcastTx() => logger.span('stepBroadcastTx', () async {
    var data = state.data!;
    onBeforeTransaction(data);

    // Already broadcast — skip straight to confirm.
    if (data.txHash != null) {
      logger.i(
        '$namespace: txHash already set (${data.txHash}), skipping to confirm',
      );
      return OnchainTxSent(data);
    }

    // Send the transaction.
    final tx = await executeTransaction();
    data = data.copyWithTransactionInformation(tx);
    final txHash = extractTxHash(tx);
    if (txHash != null) {
      data = data.copyWithTxHash(txHash);
      logger.i('$namespace: transaction broadcast: $txHash');
      return OnchainTxSent(data);
    } else {
      logger.w(
        'Could not extract tx hash from TransactionInformation, '
        'skipping receipt status check',
      );
      return OnchainTxConfirmed(data);
    }
  });

  // ── Step: confirm tx (idempotent — no busy guard) ─────────────────

  /// Wait for the on-chain transaction receipt.
  ///
  /// This step has no busy guard — any process (foreground or
  /// background) can pick it up.  It's purely a read: wait for the
  /// receipt and check success.
  Future<OnchainOperationState> _stepConfirmTx() => logger.span(
    'stepConfirmTx',
    () async {
      var data = state.data!;
      final txHash = data.txHash!;
      final transactionInformation =
          data.transactionInformation ?? await chain.awaitTransaction(txHash);
      data = data.copyWithTransactionInformation(transactionInformation);

      final receipt = await chain.awaitReceipt(txHash);
      logger.i(
        'Receipt received for $namespace tx $txHash: status=${receipt.status}',
      );
      if (!isReceiptSuccessful(receipt)) {
        return OnchainError('Transaction reverted: $txHash', data: data);
      }
      data = data.copyWithTransactionReceipt(receipt);
      onTransactionConfirmed(data, receipt);
      logger.d('$namespace transaction confirmed: $txHash');
      return OnchainTxConfirmed(data);
    },
  );

  // ── Address resolution ────────────────────────────────────────────

  /// Pick the best HD address for this operation.
  ///
  /// Looks for an already-funded address that can cover
  /// [requiredOnchainValue]; otherwise picks the next unused address
  /// (implying a swap-in will be needed).
  Future<void> resolveAddress() => logger.span('resolveAddress', () async {
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
  });

  /// Called after [resolveAddress] picks an account index so subclasses
  /// can update their contract params with the resolved key.
  void onAddressResolved(int resolvedAccountIndex);

  // ── Swap deficit ──────────────────────────────────────────────────

  /// Check whether the current balance can cover
  /// [requiredOnchainValue] + gas.
  ///
  /// Returns the amount that must be swapped in (zero if sufficient).
  Future<BitcoinAmount> computeSwapDeficit(GasEstimate gasEstimate) =>
      logger.span('computeSwapDeficit', () async {
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
      });

  // ── Nested swap-in ────────────────────────────────────────────────

  /// Runs a nested swap-in if the balance is insufficient. Returns updated
  /// [data] with the swap ID populated.
  ///
  /// The [gasEstimate] must already be pinned before calling this method.
  /// Emits [OnchainSwapProgress] states as the swap progresses.
  Future<OnchainOperationData> swapIfNeeded(
    OnchainOperationData data,
    GasEstimate gasEstimate,
  ) => logger.span('swapIfNeeded', () async {
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
        claimAddress: swapClaimAddress,
        claimDestination: swapClaimDestination,
        onClaim: swapClaimCallback,
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
        claimAddress: swapClaimAddress,
        claimDestination: swapClaimDestination,
        parentOperationId: data.operationId,
        onClaim: swapClaimCallback,
      ),
    );
    swap.onProgress = onProgress;

    String? swapId;
    bool swapIdPersisted = false;
    final sub = swap.stream.listen((swapState) {
      swapId ??= swapState.operationId;

      if (!swapIdPersisted && swapId != null) {
        // First swap state with an ID — persist the link so crash
        // recovery can find the nested swap via _stepCheckSwap.
        swapIdPersisted = true;
        emit(
          OnchainSwapProgress(
            data.copyWithSwapId(swapId),
            swapState: swapState,
          ),
        );
      } else {
        // Subsequent updates are UI-only (the swap-in operation
        // persists its own state independently).
        emit(
          OnchainSwapProgress(
            data.copyWithSwapId(swapId),
            swapState: swapState,
          ),
        );
      }
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

    final updatedData = data.copyWithSwapId(swapId);
    return onNestedSwapFinished(updatedData, swap.state);
  });

  /// Called after gas estimation so subclasses can pin the estimate onto
  /// their contract params. Default is a no-op.
  void onGasEstimated(GasEstimate estimate) {}

  /// Optional override for the nested swap claim execution.
  ///
  /// When provided, [swapIfNeeded] passes this callback to the nested
  /// [SwapInOperation] so subclasses can replace the default relay claim
  /// with a custom action such as atomic `claimSwapAndFund(...)`.
  SwapInClaimCallback? get swapClaimCallback => null;

  /// Allows subclasses to project information from a completed nested swap
  /// back onto the parent on-chain operation state.
  ///
  /// The default implementation returns [data] unchanged.
  OnchainOperationData onNestedSwapFinished(
    OnchainOperationData data,
    SwapInState swapState,
  ) => data;

  // ── Tx helpers ────────────────────────────────────────────────────

  String? extractTxHash(TransactionInformation tx) =>
      logger.spanSync('extractTxHash', () {
        final dynamic d = tx;
        final hash = d.hash?.toString() ?? d.id?.toString();
        if (hash == null || hash.isEmpty) return null;
        return hash;
      });

  bool isReceiptSuccessful(TransactionReceipt receipt) =>
      logger.spanSync('isReceiptSuccessful', () {
        final dynamic status = (receipt as dynamic).status;
        if (status == null) return true;
        if (status is bool) return status;
        if (status is int) return status == 1;
        if (status is BigInt) return status == BigInt.one;
        final normalized = status.toString().toLowerCase();
        return normalized == '1' || normalized == '0x1' || normalized == 'true';
      });
}

Map<String, dynamic> serializeTransactionInformation(
  TransactionInformation tx,
) => {
  if (tx.blockHash != null) 'blockHash': tx.blockHash,
  if (!tx.blockNumber.isPending)
    'blockNumber': tx.blockNumber.blockNum.toString(),
  'from': tx.from.toString(),
  'gas': tx.gas.toString(),
  'gasPrice': tx.gasPrice.getInWei.toString(),
  'hash': tx.hash,
  'input': bytesToHex(tx.input, include0x: true),
  'nonce': tx.nonce.toString(),
  if (tx.to != null) 'to': tx.to.toString(),
  if (tx.transactionIndex != null)
    'transactionIndex': tx.transactionIndex.toString(),
  'value': tx.value.getInWei.toString(),
  'v': tx.v.toString(),
  'r': toHexQuantity(tx.r),
  's': toHexQuantity(tx.s),
};

Map<String, dynamic> serializeTransactionReceipt(TransactionReceipt receipt) =>
    {
      'transactionHash': bytesToHex(receipt.transactionHash, include0x: true),
      'transactionIndex': toHexQuantity(receipt.transactionIndex),
      'blockHash': bytesToHex(receipt.blockHash, include0x: true),
      if (!receipt.blockNumber.isPending)
        'blockNumber': receipt.blockNumber.blockNum.toString(),
      if (receipt.from != null) 'from': receipt.from.toString(),
      if (receipt.to != null) 'to': receipt.to.toString(),
      'cumulativeGasUsed': toHexQuantity(receipt.cumulativeGasUsed),
      if (receipt.gasUsed != null) 'gasUsed': toHexQuantity(receipt.gasUsed!),
      if (receipt.effectiveGasPrice != null)
        'effectiveGasPrice': receipt.effectiveGasPrice!.getInWei.toString(),
      if (receipt.contractAddress != null)
        'contractAddress': receipt.contractAddress.toString(),
      if (receipt.status != null) 'status': receipt.status! ? '0x1' : '0x0',
      'logs': receipt.logs.map(serializeFilterEvent).toList(),
    };

Map<String, dynamic> serializeFilterEvent(FilterEvent event) => {
  if (event.removed != null) 'removed': event.removed,
  if (event.logIndex != null) 'logIndex': toHexQuantity(event.logIndex!),
  if (event.transactionIndex != null)
    'transactionIndex': toHexQuantity(event.transactionIndex!),
  if (event.transactionHash != null) 'transactionHash': event.transactionHash,
  if (event.blockHash != null) 'blockHash': event.blockHash,
  if (event.blockNum != null) 'blockNumber': toHexQuantity(event.blockNum!),
  if (event.address != null) 'address': event.address.toString(),
  if (event.data != null) 'data': event.data,
  if (event.topics != null) 'topics': event.topics,
};

TransactionInformation? deserializeTransactionInformation(
  Map<String, dynamic>? json,
) => json == null ? null : TransactionInformation.fromMap(json);

TransactionReceipt? deserializeTransactionReceipt(Map<String, dynamic>? json) =>
    json == null ? null : TransactionReceipt.fromMap(json);

String toHexQuantity(Object value) {
  final bigint = switch (value) {
    int v => BigInt.from(v),
    BigInt v => v,
    _ => throw ArgumentError('Unsupported quantity type: ${value.runtimeType}'),
  };
  return '0x${bigint.toRadixString(16)}';
}

/// Signal that [stepCheckSwap] cannot make progress because the nested
/// swap-in has not completed yet. Caught by [recover] to return `false`.
class SwapNotReadyException implements Exception {
  @override
  String toString() => 'Nested swap not yet complete';
}
