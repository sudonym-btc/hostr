import 'package:models/main.dart';
import 'package:permissionless/permissionless.dart' as permissionless;
import 'package:web3dart/web3dart.dart';

import '../../../config.dart';
import '../../../injection.dart';
import '../../../util/bloc_x.dart';
import '../../../util/custom_logger.dart';
import '../../../util/token_amount_ext.dart';
import '../../auth/auth.dart';
import '../../evm/main.dart';
import '../../trade_account_allocator/trade_account_allocator.dart';
import '../supported_escrow_contract/supported_escrow_contract.dart';

// ── Data base class ─────────────────────────────────────────────────────

/// Common recovery data that every on-chain operation must carry.
///
/// Holds the fields shared across all operations (account index, encoded call
/// intent, swap ID, chain/contract identifiers, tx hash).
/// Most operations now use [OnchainCallData] directly; only specialized flows
/// like escrow funding need extra persisted fields.
abstract class OnchainOperationData {
  final int accountIndex;
  final String contractAddress;
  final int chainId;

  /// Ordered list of calls this operation intends to execute as a single
  /// batched UserOperation. For example, an ERC-20 escrow fund would be
  /// `[approve, createTrade]`.
  final List<CallIntent> callIntents;

  /// Chosen execution transport for [callIntents].
  ///
  /// `relay` is only used for zero-value calls when the contract has a
  /// configured RIF relay. `direct` means the sender EOA will broadcast the
  /// transaction after any required swap-in.
  final String? transport;

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
    this.callIntents = const [],
    this.transport,
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
  OnchainOperationData copyWithCallIntents(List<CallIntent> callIntents);
  OnchainOperationData copyWithTransport(String? transport);

  /// Serialise common fields.  Subclasses should spread this into
  /// their own [toJson] via `...super.baseToJson()`.
  Map<String, dynamic> baseToJson() => {
    'accountIndex': accountIndex,
    'contractAddress': contractAddress,
    'chainId': chainId,
    if (callIntents.isNotEmpty)
      'callIntents': callIntents.map((i) => i.toJson()).toList(),
    if (transport != null) 'transport': transport,
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

class OnchainCallData extends OnchainOperationData {
  final String operationIdValue;
  final String? errorMessage;

  const OnchainCallData({
    required this.operationIdValue,
    required super.contractAddress,
    required super.chainId,
    required super.accountIndex,
    super.callIntents,
    super.transport,
    super.swapId,
    super.txHash,
    super.transactionInformation,
    super.transactionReceipt,
    this.errorMessage,
  });

  @override
  String get operationId => operationIdValue;

  @override
  OnchainCallData copyWithSwapId(String? swapId) => copyWith(swapId: swapId);

  @override
  OnchainCallData copyWithTxHash(String? txHash) => copyWith(txHash: txHash);

  @override
  OnchainCallData copyWithTransactionInformation(
    TransactionInformation? transactionInformation,
  ) => copyWith(transactionInformation: transactionInformation);

  @override
  OnchainCallData copyWithTransactionReceipt(
    TransactionReceipt? transactionReceipt,
  ) => copyWith(transactionReceipt: transactionReceipt);

  @override
  OnchainCallData copyWithCallIntents(List<CallIntent> callIntents) =>
      copyWith(callIntents: callIntents);

  @override
  OnchainCallData copyWithTransport(String? transport) =>
      copyWith(transport: transport);

  OnchainCallData copyWith({
    List<CallIntent>? callIntents,
    String? transport,
    String? swapId,
    String? txHash,
    TransactionInformation? transactionInformation,
    TransactionReceipt? transactionReceipt,
    String? errorMessage,
  }) => OnchainCallData(
    operationIdValue: operationIdValue,
    contractAddress: contractAddress,
    chainId: chainId,
    accountIndex: accountIndex,
    callIntents: callIntents ?? this.callIntents,
    transport: transport ?? this.transport,
    swapId: swapId ?? this.swapId,
    txHash: txHash ?? this.txHash,
    transactionInformation:
        transactionInformation ?? this.transactionInformation,
    transactionReceipt: transactionReceipt ?? this.transactionReceipt,
    errorMessage: errorMessage ?? this.errorMessage,
  );

  @override
  Map<String, dynamic> toJson() => {
    'operationId': operationIdValue,
    ...baseToJson(),
    if (errorMessage != null) 'errorMessage': errorMessage,
  };

  factory OnchainCallData.fromJson(Map<String, dynamic> json) {
    final callIntents = parseCallIntents(json);
    return OnchainCallData(
      operationIdValue:
          (json['operationId'] ?? json['tradeId'] ?? json['id']) as String,
      contractAddress: json['contractAddress'] as String,
      chainId: json['chainId'] as int,
      accountIndex: json['accountIndex'] as int? ?? 0,
      callIntents: callIntents,
      transport: json['transport'] as String?,
      swapId: json['swapId'] as String?,
      txHash: json['txHash'] as String?,
      transactionInformation: deserializeTransactionInformation(
        json['transactionInformation'] as Map<String, dynamic>?,
      ),
      transactionReceipt: deserializeTransactionReceipt(
        json['transactionReceipt'] as Map<String, dynamic>?,
      ),
      errorMessage: json['errorMessage'] as String?,
    );
  }
}

/// Parse callIntents from JSON.
List<CallIntent> parseCallIntents(Map<String, dynamic> json) {
  if (json['callIntents'] is List) {
    return (json['callIntents'] as List)
        .map((e) => CallIntent.fromJson(e as Map<String, dynamic>))
        .toList();
  }
  return const [];
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

class OnchainFeeQuote {
  final TokenAmount gasFee;
  final bool gasSponsored;
  final List<CallIntent> callIntents;
  final String transport;

  const OnchainFeeQuote({
    required this.gasFee,
    required this.gasSponsored,
    required this.callIntents,
    required this.transport,
  });
}

// ── Base class ──────────────────────────────────────────────────────────

/// Abstract base for any operation that needs to send an on-chain
/// transaction via ERC-4337 Account Abstraction.
///
/// Provides:
/// - State persistence via [OperationMachine] (CAS, run loop)
/// - HD address resolution ([resolveAddress])
/// - Receipt confirmation helpers
///
/// Subclasses implement the handful of abstract members that vary per
/// operation (gas estimation, the contract call, state wrappers, etc.).
///
/// **Swap-in is not handled here.** Only [EscrowFundOperation] performs
/// a nested swap-in (via its [beforeBroadcast] override) when the
/// on-chain balance is insufficient to cover the funding transaction.
/// All other operations (claim, release) go directly to broadcast.
abstract class OnchainOperation
    extends OperationMachine<OnchainOperationState, OnchainStep> {
  // ── Dependencies ────────────────────────────────────────────────────

  final Auth auth;
  final TradeAccountAllocator tradeAccountAllocator;
  final Evm evm;
  late final ConfiguredEvmChain configuredChain;
  EvmChain get chain => configuredChain.chain;
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
    this.tradeAccountAllocator,
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
          OnchainStep.checkSwap => throw StateError(
            'checkSwap is only supported by EscrowFundOperation',
          ),
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

  /// Optional pre-flight checks (e.g. `canClaim()`).
  Future<void> preflight() async {}

  /// Perform any up-front initialization required before the run loop starts.
  ///
  /// Subclasses should prefer overriding this instead of `resolveAddress()` so
  /// the setup phase is explicit from the outside.
  Future<void> initialize() => resolveAddress();

  /// Build the list of call intents for this operation.
  ///
  /// For single-call operations (claim, release), returns a one-element list.
  /// For multi-call operations (ERC-20 fund = approve + createTrade), returns
  /// multiple intents that will be batched into a single UserOperation.
  Future<List<CallIntent>> buildCallIntents();

  /// Build state overrides for gas estimation.
  ///
  /// Override in subclasses that need to simulate token balances during
  /// `eth_estimateUserOperationGas` — e.g. escrow funding where the ERC-20
  /// tokens arrive via swap *after* the gas estimate.
  ///
  /// Returns `null` by default (no overrides).
  Future<List<permissionless.StateOverride>?> buildGasEstimationStateOverrides(
    List<CallIntent> intents,
  ) async => null;

  /// Estimate gas for a list of call intents via ERC-4337.
  ///
  /// Returns the gas fee as a [TokenAmount] in the chain's native token,
  /// plus whether the gas is currently sponsored by a paymaster.
  ///
  /// If [stateOverride] is not provided, [buildGasEstimationStateOverrides]
  /// is called to allow subclasses to inject simulated token balances.
  Future<({TokenAmount gasFee, bool gasSponsored})> estimateCallIntentsFee(
    List<CallIntent> intents, {
    List<permissionless.StateOverride>? stateOverride,
  }) {
    return logger.span('estimateCallIntentsFee', () async {
      final effectiveOverrides =
          stateOverride ?? await buildGasEstimationStateOverrides(intents);
      final signer = await auth.hd.getActiveEvmKey(accountIndex: accountIndex);
      final estimate = await configuredChain.aa!.estimateGasFee(
        signer,
        intents: intents,
        stateOverride: effectiveOverrides,
      );
      return (
        gasFee: rbtcFromWei(estimate.gasCostWei),
        gasSponsored: estimate.gasSponsored,
      );
    });
  }

  /// Send the persisted call intents as a batched UserOperation.
  Future<String> broadcastCallIntents(
    List<CallIntent> intents,
    EthPrivateKey credentials,
  ) => logger.span('broadcastCallIntents', () async {
    try {
      await contract.ensureDeployed();
      return await configuredChain.sendCalls(credentials, intents);
    } catch (error) {
      throw contract.decodeWriteError(error);
    }
  });

  Future<TransactionInformation> submitCallIntents(
    List<CallIntent> intents,
    EthPrivateKey credentials,
  ) => logger.span('submitCallIntents', () async {
    final txHash = await broadcastCallIntents(intents, credentials);
    return await chain.awaitTransaction(txHash);
  });

  /// Build the initial recovery data for this operation.
  OnchainOperationData buildInitialData({
    required List<CallIntent> callIntents,
    required String transport,
  });

  /// Deserialise the concrete [OnchainOperationData] subclass from JSON.
  ///
  /// Subclasses must override to provide their specific factory
  /// (e.g. `EscrowFundData.fromJson`). Used by [stateFromJson].
  OnchainOperationData dataFromJson(Map<String, dynamic> json);

  // ── Hooks ─────────────────────────────────────────────────────────

  /// Called before sending the transaction so subclasses can rebuild
  /// contract params from persisted data. Default is a no-op.
  void onBeforeTransaction(OnchainOperationData data) {}

  /// Called inside [_stepConfirmTx] **before** persisting [OnchainTxConfirmed].
  ///
  /// Runs exactly once (the CAS-winning process). If this throws, the
  /// run-loop catch block converts it into [OnchainError].
  ///
  /// Use this for validations that must gate success (e.g. verifying
  /// that the receipt contains the expected contract logs).
  void validateConfirmedTransaction(
    OnchainOperationData data,
    TransactionReceipt receipt,
  ) {}

  /// Called when the run loop reaches a terminal state, in **every**
  /// process (foreground, background, recovery).
  ///
  /// Implementations **must** be idempotent and should not throw.
  /// The state and its persisted data (including the receipt) are
  /// available for logging / metrics.
  @override
  void onRunComplete(OnchainOperationState state) {}

  Future<OnchainFeeQuote> estimateOperationFees() =>
      logger.span('estimateOperationFees', () async {
        await initialize();
        final intents = await buildCallIntents();
        final gasEstimate = await estimateCallIntentsFee(intents);

        return OnchainFeeQuote(
          gasFee: gasEstimate.gasFee,
          gasSponsored: gasEstimate.gasSponsored,
          callIntents: intents,
          transport: 'direct',
        );
      });

  // ── Entry points ──────────────────────────────────────────────────

  /// Start a new operation (resolves address, then runs the loop).
  @override
  Future<void> execute() async {
    await initialize();
    await run();
  }

  // ── Step: initialise ──────────────────────────────────────────────

  /// Build initial data, estimate gas, then transition to [OnchainTxBroadcast].
  ///
  /// Subclasses that need pre-broadcast work (e.g. swap-in) should override
  /// [beforeBroadcast] rather than this method.
  Future<OnchainOperationState> _stepInitialise() =>
      logger.span('stepInitialise', () async {
        await preflight();
        final intents = await buildCallIntents();
        final gasEstimate = await estimateCallIntentsFee(intents);
        onGasEstimated(gasEstimate.gasFee);
        var data = buildInitialData(callIntents: intents, transport: 'direct');
        logger.i(
          '$namespace: initialising ${data.operationId} '
          '(accountIndex: $accountIndex)',
        );
        data = await beforeBroadcast(data, gasEstimate.gasFee);
        return OnchainTxBroadcast(data);
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
    final intents = data.callIntents;
    if (intents.isEmpty) {
      throw StateError(
        '$namespace cannot broadcast without persisted callIntents',
      );
    }
    final tx = await submitCallIntents(
      intents,
      await auth.hd.getActiveEvmKey(accountIndex: data.accountIndex),
    );
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

      final receipt =
          data.transactionReceipt ?? await chain.awaitReceipt(txHash);
      logger.i(
        'Receipt received for $namespace tx $txHash: status=${receipt.status}',
      );
      if (!isReceiptSuccessful(receipt)) {
        return OnchainError('Transaction reverted: $txHash', data: data);
      }
      data = data.copyWithTransactionReceipt(receipt);
      validateConfirmedTransaction(data, receipt);
      chain.notifyNewBlock();
      logger.d('$namespace transaction confirmed: $txHash');
      return OnchainTxConfirmed(data);
    },
  );

  // ── Address resolution ────────────────────────────────────────────

  /// Pick the best HD address for this operation.
  ///
  /// Picks the trade-bound deterministic account if available, else falls
  /// back to account index 0.
  Future<void> resolveAddress() => logger.span('resolveAddress', () async {
    final accountIndex =
        (await tradeAccountAllocator.tryFindTradeAccountIndexByTradeId(
          tradeId,
        )) ??
        0;
    logger.i(
      'Using trade signer account index $accountIndex for trade $tradeId',
    );
    this.accountIndex = accountIndex;
    onAddressResolved(accountIndex);
  });

  String get tradeId;

  /// Called after [resolveAddress] picks an account index so subclasses
  /// can update their contract params with the resolved key.
  void onAddressResolved(int resolvedAccountIndex) {}

  // ── Pre-broadcast hook ─────────────────────────────────────────────

  /// Called after gas estimation and initial data construction, before
  /// transitioning to broadcast.
  ///
  /// Override in subclasses to add pre-broadcast logic (e.g. swap-in
  /// for funding). The default is a pass-through.
  Future<OnchainOperationData> beforeBroadcast(
    OnchainOperationData data,
    TokenAmount gasFee,
  ) async => data;

  /// Called after gas estimation so subclasses can pin the estimate onto
  /// their contract params. Default is a no-op.
  void onGasEstimated(TokenAmount gasFee) {}

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
