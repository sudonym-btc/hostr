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
  bool _isExecuting = false;

  /// The HD account index chosen by [getNextUnusedAddress].
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
    final requiredSwapAmount = await _doesEscrowRequireSwap();
    final swapFees = requiredSwapAmount > BitcoinAmount.zero()
        ? await chain
              .swapIn(
                SwapInParams(
                  evmKey: contractParams.ethKey,
                  accountIndex: _accountIndex,
                  amount: requiredSwapAmount,
                  invoiceDescription: params!.swapInvoiceDescription,
                ),
              )
              .estimateFees()
        : SwapInFees(
            estimatedGasFees: BitcoinAmount.zero(),
            estimatedSwapFees: BitcoinAmount.zero(),
            estimatedRelayFees: BitcoinAmount.zero(),
          );
    return EscrowFundFees(
      estimatedGasFees: (await contract.estimateEscrowFundFee(
        contractParams,
      )).fee,
      estimatedSwapFees: swapFees,
    );
  }

  Future<void> execute() async {
    if (_isExecuting) {
      logger.w('Escrow fund already in progress, ignoring duplicate execute()');
      return;
    }
    _isExecuting = true;

    EscrowFundData? fundData;

    // ── Pick the best address to fund from ─────────────────────────────
    // First, check if any already-funded HD address can cover the escrow
    // amount (plus gas).  This avoids an unnecessary swap-in when the
    // user already holds RBTC — e.g. from a prior swap-in or direct
    // transfer.  Only if no address qualifies do we fall back to a fresh
    // unused address (which will be funded via swap-in later).
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

    // ── Address invariant ──────────────────────────────────────────────
    // contractParams.ethKey is the SINGLE source of truth for the funding
    // address. Every sub-operation reuses it:
    //
    //   1. _doesEscrowRequireSwap  → checks balance of ethKey.address (EOA)
    //   2. _swapRequiredAmount     → passes ethKey to SwapInParams, which
    //      derives the RIF smart-wallet as the Boltz claim address.
    //      After the relayed EtherSwap.claim, the SmartWallet.execute()
    //      auto-forwards received RBTC back to the owner EOA (ethKey.address).
    //   3. contract.deposit        → sends from ethKey.address (EOA)
    //
    // This guarantees the swap-in funds arrive at the exact address that
    // will sign the escrow deposit transaction.
    // ───────────────────────────────────────────────────────────────────

    // Create recovery data immediately.
    fundData = EscrowFundData(
      tradeId: contractParams.tradeId,
      reservedAmountWeiHex: BitcoinAmount.fromAmount(
        params!.amount,
      ).getInWei.toRadixString(16),
      sellerEvmAddress: contractParams.sellerEvmAddress,
      arbiterEvmAddress: contractParams.arbiterEvmAddress,
      contractAddress: params!.escrowService.parsedContent.contractAddress,
      chainId: params!.escrowService.parsedContent.chainId,
      unlockAt: contractParams.unlockAt,
      accountIndex: _accountIndex,
    );

    try {
      logger.i(
        'Creating escrow for tradeId ${contractParams.tradeId} at ${params!.escrowService.parsedContent.contractAddress} (accountIndex: $_accountIndex)',
      );
      fundData = await _swapRequiredAmount(fundData);

      emit(EscrowFundDepositing(fundData));
      TransactionInformation tx = await contract.deposit(contractParams);
      final txHash = _extractTxHash(tx);
      if (txHash != null) {
        fundData = fundData.copyWith(depositTxHash: txHash);
        emit(EscrowFundDepositing(fundData));
        final receipt = await chain.awaitReceipt(txHash);
        if (!_isReceiptSuccessful(receipt)) {
          throw StateError(
            'Escrow funding transaction reverted (tx: $txHash, receipt: $receipt)',
          );
        }
        logger.d(
          'Escrow deposit transaction confirmed with hash: $txHash, $receipt',
        );
        logger.d('Receipt ${receipt.blockNumber}');
      } else {
        logger.w(
          'Could not extract tx hash from TransactionInformation, skipping receipt status check',
        );
      }
      logger.d('Escrow funded with transaction: $tx');
      emit(EscrowFundCompleted(fundData, transactionInformation: tx));
    } catch (error, stackTrace) {
      logger.e('Escrow failed', error: error, stackTrace: stackTrace);
      final e = EscrowFundFailed(error, data: fundData, stackTrace: stackTrace);
      emit(e);
      throw e;
    } finally {
      _isExecuting = false;
    }
  }

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

  Future<BitcoinAmount> _doesEscrowRequireSwap() async {
    // Use contractParams.ethKey — the single source of truth for the deposit
    // address — so the balance check targets the exact same EOA that will fund
    // the escrow.
    final balance = await chain.getBalance(contractParams.ethKey.address);
    logger.i('Escrow sender balance: $balance RBTC');

    final estimate = await contract.estimateEscrowFundFee(contractParams);
    final transactionFee = estimate.fee;

    // Pin the gas price and gas limit from estimation onto contractParams
    // so the deposit transaction uses the exact same values.
    contractParams = contractParams.withGasParams(
      gasPrice: estimate.gasPrice,
      gasLimit: estimate.gasLimit,
    );

    logger.w(
      'Estimated transaction fee for escrow deposit: ${transactionFee.getInSats} sats '
      '(gasPrice: ${estimate.gasPrice.getInWei}, gasLimit: ${estimate.gasLimit})',
    );

    final leftAfterTrade =
        balance - BitcoinAmount.fromAmount(params!.amount) - transactionFee;

    if (leftAfterTrade < BitcoinAmount.zero()) {
      logger.e(
        'Insufficient balance for escrow deposit. Have $balance RBTC, would leave us with $leftAfterTrade',
      );

      return BitcoinAmount.max(
        await chain.getMinimumSwapIn(),
        leftAfterTrade.abs(),
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
        await swap.execute();
      } finally {
        await sub.cancel();
      }
      return fundData.copyWith(swapId: swapId);
    }
    return fundData;
  }

  /// Resume from the current (deserialized) state.
  ///
  /// Does NOT recover nested swaps — that's the [SwapRecoverer]'s job.
  /// If the swap is still in progress, returns immediately.
  Future<void> recover() async {
    final currentState = state;
    final data = currentState.data;
    if (data == null || currentState.isTerminal) return;

    switch (currentState) {
      case EscrowFundSwapProgress():
        // Check if the nested swap has completed via the store.
        if (data.swapId != null) {
          final swapJson = await _stateStore.read('swap_in', data.swapId!);
          if (swapJson != null) {
            final swapState = SwapInState.fromJson(swapJson);
            if (swapState is SwapInCompleted) {
              logger.i(
                'EscrowFund recover: swap ${data.swapId} completed, '
                'proceeding to deposit',
              );
              await _executeDeposit(data);
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
        // Swap not done yet — exit. SwapRecoverer handles it.
        logger.d(
          'EscrowFund recover: swap ${data.swapId} not yet complete, exiting',
        );
        return;
      case EscrowFundDepositing():
        await _executeDeposit(data);
        return;
      default:
        return;
    }
  }

  Future<void> _executeDeposit(EscrowFundData data) async {
    try {
      final evmKey = auth.getActiveEvmKey(accountIndex: data.accountIndex);
      contractParams = data.toContractParams(evmKey);

      if (data.depositTxHash != null) {
        // Transaction already broadcast — check receipt.
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
          logger.w(
            'EscrowFund recover: tx ${data.depositTxHash} not found, re-sending',
          );
        }
      }

      emit(EscrowFundDepositing(data));
      TransactionInformation tx = await contract.deposit(contractParams);
      final txHash = _extractTxHash(tx);
      if (txHash != null) {
        final updatedData = data.copyWith(depositTxHash: txHash);
        emit(EscrowFundDepositing(updatedData));
        final receipt = await chain.awaitReceipt(txHash);
        if (_isReceiptSuccessful(receipt)) {
          emit(EscrowFundCompleted(updatedData, transactionInformation: tx));
        } else {
          emit(
            EscrowFundFailed('Deposit reverted: $txHash', data: updatedData),
          );
        }
      } else {
        emit(EscrowFundCompleted(data, transactionInformation: tx));
      }
    } catch (e, st) {
      logger.e('EscrowFund recover deposit failed: $e');
      emit(EscrowFundFailed(e, data: data, stackTrace: st));
    }
  }
}
