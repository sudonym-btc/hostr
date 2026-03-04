import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/injection.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:web3dart/web3dart.dart';

import '../../supported_escrow_contract/supported_escrow_contract.dart';

@injectable
class EscrowFundOperation extends Cubit<EscrowFundState> {
  final CustomLogger logger;
  final Auth auth;
  final Evm evm;
  late final EvmChain chain;
  late final SupportedEscrowContract contract;
  final EscrowFundParams? params;
  late ContractFundEscrowParams contractParams;

  /// The HD account index chosen by [_resolveAddress].
  /// Set once at the start of [execute] and used for all operations.
  /// Defaults to 0 for pre-execute calls like [estimateFees].
  int _accountIndex = 0;

  late final OperationStateStore _stateStore = getIt<OperationStateStore>();

  EscrowFundOperation(
    this.auth,
    this.evm,
    this.logger,
    @factoryParam this.params,
  ) : super(EscrowFundInitialised()) {
    if (params != null) {
      chain = evm.getChainForEscrowService(params!.escrowService);
      contract = chain.getSupportedEscrowContract(params!.escrowService);
      // Initialise with index 0; execute() will resolve the real index.
      contractParams = params!.toContractParams(auth.getActiveEvmKey());
    }
  }

  /// Create for recovery mode. [recoveryChain] and [recoveryContract] are pre-resolved.
  EscrowFundOperation.forRecovery(
    this.auth,
    this.evm,
    this.logger, {
    required EvmChain recoveryChain,
    required SupportedEscrowContract recoveryContract,
    required EscrowFundState initialState,
  }) : params = null,
       super(initialState) {
    chain = recoveryChain;
    contract = recoveryContract;
    final data = initialState.data;
    if (data != null) {
      _accountIndex = data.accountIndex;
      contractParams = data.toContractParams(
        auth.getActiveEvmKey(accountIndex: _accountIndex),
      );
    }
  }

  /// Persist every state that carries data.
  @override
  void emit(EscrowFundState state) {
    super.emit(state);
    final id = state.operationId;
    if (id != null) {
      _stateStore.write('escrow_fund', id, state.toJson());
    }
  }

  Future<EscrowFundFees> estimateFees() async {
    final gasEstimate = await contract.estimateEscrowFundFee(contractParams);
    final swapDeficit = await _computeSwapDeficit(gasEstimate);
    final swapFees = swapDeficit > BitcoinAmount.zero()
        ? await chain
              .swapIn(
                SwapInParams(
                  evmKey: contractParams.ethKey,
                  accountIndex: _accountIndex,
                  amount: swapDeficit,
                  invoiceDescription: params!.swapInvoiceDescription,
                ),
              )
              .estimateFees()
        : SwapInFees(
            estimatedGasFees: BitcoinAmount.zero(),
            estimatedSwapFees: BitcoinAmount.zero(),
            estimatedRelayFees: BitcoinAmount.zero(),
          );
    final escrowFeeSats = params!.escrowService.escrowFee(
      contractParams.amount.getInSats.toInt(),
    );
    return EscrowFundFees(
      estimatedGasFees: gasEstimate.fee,
      estimatedSwapFees: swapFees,
      estimatedEscrowFees: BitcoinAmount.fromInt(
        BitcoinUnit.sat,
        escrowFeeSats,
      ),
    );
  }

  // ── State machine ─────────────────────────────────────────────────────

  /// Reads the current state and performs exactly one state transition.
  ///
  /// | State group          | Action                                     |
  /// |----------------------|--------------------------------------------|
  /// | `Initialised`        | Resolve address, create data, swap if needed |
  /// | `SwapProgress`       | Check nested swap completion               |
  /// | `Depositing`         | Send or confirm deposit tx                 |
  /// | `Completed / Failed` | No-op (terminal)                           |
  Future<void> handle() async {
    try {
      switch (state) {
        case EscrowFundInitialised():
          await _stepInitialise();
        case EscrowFundSwapProgress():
          await _stepCheckSwap();
        case EscrowFundDepositing():
          await _stepDeposit();
        case EscrowFundCompleted() || EscrowFundFailed():
          return; // terminal — nothing to do
      }
    } on _SwapNotReadyException {
      rethrow; // Let run()/recover() handle this — not an error.
    } catch (e, st) {
      logger.e('Error during escrow fund handle (${state.runtimeType}): $e');
      emit(EscrowFundFailed(e, data: state.data, stackTrace: st));
    }
  }

  /// Loops [handle] until the state is terminal.
  Future<void> run() async {
    while (!state.isTerminal) {
      await handle();
    }
  }

  /// Start a new escrow fund from [EscrowFundInitialised].
  Future<void> execute() async {
    await _resolveAddress();
    await run();
  }

  /// Resume from a persisted (non-terminal) state.
  ///
  /// Returns `true` if the operation reached a terminal state.
  ///
  /// **Note:** When in [EscrowFundSwapProgress], the nested swap is NOT
  /// recovered here — that's the [SwapRecoverer]'s job. If the swap isn't
  /// complete yet, [_stepCheckSwap] throws [_SwapNotReadyException] to break
  /// the [run] loop and `recover()` returns `false`.
  Future<bool> recover() async {
    if (state.data == null) return false;
    if (state.isTerminal) return true;
    try {
      await run();
      return state.isTerminal;
    } on _SwapNotReadyException {
      logger.d('Recovery: nested swap not ready for ${state.data?.tradeId}');
      return false;
    } catch (e) {
      logger.e('Recovery error for ${state.data?.tradeId}: $e');
      return false;
    }
  }

  // ── Step 1: Resolve address, create data, swap if needed ──────────────

  Future<void> _stepInitialise() async {
    logger.i(
      'Creating escrow for tradeId ${contractParams.tradeId} at '
      '${params!.escrowService.contractAddress} '
      '(accountIndex: $_accountIndex)',
    );

    // Create recovery data immediately.
    var fundData = EscrowFundData(
      tradeId: contractParams.tradeId,
      reservedAmountWeiHex: BitcoinAmount.fromAmount(
        params!.amount,
      ).getInWei.toRadixString(16),
      sellerEvmAddress: contractParams.sellerEvmAddress,
      arbiterEvmAddress: contractParams.arbiterEvmAddress,
      contractAddress: params!.escrowService.contractAddress,
      chainId: params!.escrowService.chainId,
      unlockAt: contractParams.unlockAt,
      accountIndex: _accountIndex,
      escrowFee: contractParams.escrowFee,
    );

    // Run the nested swap-in if the balance is insufficient.
    fundData = await _swapRequiredAmount(fundData);

    // Persist the pinned gas estimate into recovery data so that
    // _stepDeposit (and recovery) use the exact same gas parameters
    // the swap-in budget was calculated against.
    final estimate = contractParams.gasEstimate;
    if (estimate != null) {
      fundData = fundData.copyWith(
        gasPriceWei: estimate.gasPrice.getInWei.toString(),
        gasLimit: estimate.gasLimit.toString(),
      );
    }

    // Swap done (or not needed) — ready to deposit.
    emit(EscrowFundDepositing(fundData));
  }

  // ── Step 2: Check nested swap completion (recovery only) ──────────────

  /// Checks whether the nested swap-in has completed.
  ///
  /// If the swap is still in progress, this method returns **without**
  /// transitioning — the [run] loop will see a non-terminal, non-progressing
  /// state and [recover] will return `false`. The [SwapRecoverer] handles
  /// completing the swap; on the next recovery pass this step will find
  /// the swap complete and advance to [EscrowFundDepositing].
  Future<void> _stepCheckSwap() async {
    final data = state.data!;

    if (data.swapId != null) {
      final swapJson = await _stateStore.read('swap_in', data.swapId!);
      if (swapJson != null) {
        final swapState = SwapInState.fromJson(swapJson);
        if (swapState is SwapInClaimed ||
            swapState is SwapInClaimTxInMempool ||
            swapState is SwapInCompleted) {
          logger.i(
            'EscrowFund: swap ${data.swapId} completed, proceeding to deposit',
          );
          emit(EscrowFundDepositing(data));
          return;
        }
        if (swapState is SwapInFailed) {
          emit(
            EscrowFundFailed(
              'Nested swap failed: ${swapState.error}',
              data: data,
            ),
          );
          return;
        }
      }
    }

    // Swap not done yet — break out of run() loop. SwapRecoverer handles it.
    logger.d('EscrowFund: swap ${data.swapId} not yet complete, exiting');
    throw _SwapNotReadyException();
  }

  // ── Step 3: Send or confirm the deposit transaction ───────────────────

  Future<void> _stepDeposit() async {
    final data = state.data!;
    final evmKey = auth.getActiveEvmKey(accountIndex: data.accountIndex);
    contractParams = data.toContractParams(evmKey);

    // ── 3a. Transaction already broadcast — check receipt ──
    if (data.depositTxHash != null) {
      try {
        final receipt = await chain.awaitReceipt(data.depositTxHash!);
        if (_isReceiptSuccessful(receipt)) {
          emit(EscrowFundCompleted(data));
        } else {
          emit(
            EscrowFundFailed(
              'Deposit reverted: ${data.depositTxHash}',
              data: data,
            ),
          );
        }
        return;
      } catch (e) {
        logger.w('EscrowFund: tx ${data.depositTxHash} not found, re-sending');
      }
    }

    // ── 3b. Send the deposit transaction ──
    //
    // The gas estimate is pinned: toContractParams() rebuilds it from the
    // gasPriceWei / gasLimit fields persisted in EscrowFundData so the
    // deposit uses the exact parameters the swap budget was calculated
    // against — no drift, no re-estimation.
    emit(EscrowFundDepositing(data));
    final tx = await contract.deposit(contractParams);
    final txHash = _extractTxHash(tx);
    if (txHash != null) {
      final updatedData = data.copyWith(depositTxHash: txHash);
      emit(EscrowFundDepositing(updatedData));
      final receipt = await chain.awaitReceipt(txHash);
      if (!_isReceiptSuccessful(receipt)) {
        throw StateError(
          'Escrow funding transaction reverted (tx: $txHash, receipt: $receipt)',
        );
      }

      // Log gas estimate vs actual usage for debugging leftover balance.
      final gasUsed = receipt.gasUsed?.toInt();
      final estimatedLimit = contractParams.gasEstimate?.gasLimit.toInt();
      final gasPrice = contractParams.gasEstimate?.gasPrice.getInWei;
      if (gasUsed != null && estimatedLimit != null && gasPrice != null) {
        final refundGas = estimatedLimit - gasUsed;
        final refundWei = BigInt.from(refundGas) * gasPrice;
        logger.w(
          'Gas usage: estimated=$estimatedLimit, actual=$gasUsed, '
          'refunded=$refundGas units '
          '(~${BitcoinAmount.inWei(refundWei).getInSats} sats)',
        );
      }

      logger.d('Escrow deposit confirmed: $txHash');
      emit(EscrowFundCompleted(updatedData, transactionInformation: tx));
    } else {
      logger.w(
        'Could not extract tx hash from TransactionInformation, '
        'skipping receipt status check',
      );
      emit(EscrowFundCompleted(data, transactionInformation: tx));
    }
  }

  // ── Address resolution ────────────────────────────────────────────────

  /// Pick the best HD address to fund from.
  ///
  /// First, check if any already-funded HD address can cover the escrow
  /// amount (plus gas). This avoids an unnecessary swap-in when the user
  /// already holds RBTC. Only if no address qualifies do we fall back to a
  /// fresh unused address (which will be funded via swap-in later).
  ///
  /// Called once at the start of [execute] before entering the state machine.
  Future<void> _resolveAddress() async {
    final requiredAmount = BitcoinAmount.fromAmount(params!.amount);
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

    _accountIndex = resolvedAccountIndex;
    final evmKey = auth.getActiveEvmKey(accountIndex: _accountIndex);
    contractParams = params!.toContractParams(evmKey);
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  String? _extractTxHash(TransactionInformation tx) {
    final dynamic d = tx;
    final hash = d.hash?.toString() ?? d.id?.toString();
    if (hash == null || hash.isEmpty) {
      return null;
    }
    return hash;
  }

  bool _isReceiptSuccessful(TransactionReceipt receipt) {
    final dynamic status = (receipt as dynamic).status;
    if (status == null) {
      // Some chains / providers may omit status on very old-style receipts.
      return true;
    }
    if (status is bool) return status;
    if (status is int) return status == 1;
    if (status is BigInt) return status == BigInt.one;

    final normalized = status.toString().toLowerCase();
    return normalized == '1' || normalized == '0x1' || normalized == 'true';
  }

  /// Check whether the current balance can cover the escrow deposit + gas.
  ///
  /// Returns the amount of RBTC that must be swapped in (zero if sufficient).
  /// As a side-effect, pins the [GasEstimate] onto [contractParams] so the
  /// deposit transaction uses the exact gas price/limit the budget was
  /// calculated with.
  Future<BitcoinAmount> _doesEscrowRequireSwap() async {
    final gasEstimate = await contract.estimateEscrowFundFee(contractParams);

    // Pin gas params so deposit uses the same price the budget assumes.
    contractParams = contractParams.withGasEstimate(gasEstimate);

    return _computeSwapDeficit(gasEstimate);
  }

  /// Pure computation: given a [gasEstimate], check the on-chain balance and
  /// return how much additional RBTC is needed (zero if the balance suffices).
  Future<BitcoinAmount> _computeSwapDeficit(GasEstimate gasEstimate) async {
    final balance = await chain.getBalance(contractParams.ethKey.address);
    final escrowAmount = BitcoinAmount.fromAmount(params!.amount);
    final shortfall = balance - escrowAmount - gasEstimate.fee;

    logger.i(
      'Balance check: have=${balance.getInSats}, '
      'escrow=${escrowAmount.getInSats}, gas=${gasEstimate.fee.getInSats}, '
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

  Future<EscrowFundData> _swapRequiredAmount(EscrowFundData fundData) async {
    final requiredAmountInBtc = await _doesEscrowRequireSwap();
    if (requiredAmountInBtc > BitcoinAmount.zero()) {
      // Reuse contractParams.ethKey so the swap-in derives the same smart
      // wallet that auto-forwards RBTC back to this EOA — the exact address
      // that will sign the escrow deposit.
      final evmKey = contractParams.ethKey;
      SwapInOperation swapEstimation = chain.swapIn(
        SwapInParams(
          evmKey: evmKey,
          accountIndex: _accountIndex,
          amount: requiredAmountInBtc,
          invoiceDescription: params!.swapInvoiceDescription,
        ),
      );
      final swapFees = await swapEstimation.estimateFees();
      SwapInOperation swap = chain.swapIn(
        SwapInParams(
          evmKey: evmKey,
          accountIndex: _accountIndex,
          amount: (requiredAmountInBtc + swapFees.totalFees).roundUp(
            BitcoinUnit.sat,
          ),
          invoiceDescription: params!.swapInvoiceDescription,
        ),
      );

      String? swapId;
      final sub = swap.stream.listen((swapState) {
        swapId ??= swapState.operationId;
        emit(
          EscrowFundSwapProgress(
            fundData.copyWith(swapId: swapId),
            swapState: swapState,
          ),
        );
      });

      try {
        // @todo: Stop once the claim tx is broadcast — we don't need to wait for
        // on-chain confirmation before issuing the escrow deposit, as our RPC should have our updated balance

        //         Since it's atomic, the RPC node's view depends on the block tag:

        // "latest" (default): Balance updates only after the block is mined (~30s on Rootstock)
        // "pending": Balance should reflect mempool tx effects, but this is unreliable — not all nodes implement it, and internal transfers from contract calls may not be traced in the pending state

        await swap.execute();
      } finally {
        await sub.cancel();
      }
      return fundData.copyWith(swapId: swapId);
    }
    return fundData;
  }
}

/// Internal signal that [_stepCheckSwap] cannot make progress because the
/// nested swap-in has not completed yet. Caught by [recover] to return
/// `false` (i.e. "not resolved — try again later").
class _SwapNotReadyException implements Exception {
  @override
  String toString() => 'Nested swap not yet complete';
}
