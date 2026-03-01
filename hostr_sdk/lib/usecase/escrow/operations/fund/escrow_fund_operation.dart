import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:web3dart/web3dart.dart';

import '../../supported_escrow_contract/supported_escrow_contract.dart';

@injectable
class EscrowFundOperation extends Cubit<EscrowFundState> {
  final CustomLogger logger;
  final Auth auth;
  final Evm evm;
  final EscrowLockRegistry _lockRegistry;
  late final EvmChain chain;
  late final SupportedEscrowContract contract;
  final EscrowFundParams params;
  late ContractFundEscrowParams contractParams;
  bool _isExecuting = false;

  /// The HD account index chosen by [getNextUnusedAddress].
  /// Set once at the start of [execute] and used for all operations.
  /// Defaults to 0 for pre-execute calls like [estimateFees].
  int _accountIndex = 0;

  EscrowFundOperation(
    this.auth,
    this.evm,
    this.logger,
    this._lockRegistry,
    @factoryParam this.params,
  ) : super(EscrowFundInitialised()) {
    chain = evm.getChainForEscrowService(params.escrowService);
    contract = chain.getSupportedEscrowContract(params.escrowService);
    // Initialise with index 0; execute() will resolve the real index.
    contractParams = params.toContractParams(auth.getActiveEvmKey());
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
                  invoiceDescription: params.swapInvoiceDescription,
                ),
              )
              .estimateFees()
        : SwapInFees(
            estimatedGasFees: BitcoinAmount.zero(),
            estimatedSwapFees: BitcoinAmount.zero(),
            estimatedRelayFees: BitcoinAmount.zero(),
          );
    return EscrowFundFees(
      estimatedGasFees: await contract.estimateDespositFee(contractParams),
      estimatedSwapFees: swapFees,
    );
  }

  Future<void> execute() async {
    if (_isExecuting) {
      logger.w('Escrow fund already in progress, ignoring duplicate execute()');
      return;
    }
    _isExecuting = true;

    // Resolve the next unused HD address for this operation.
    final (:address, :accountIndex) = await chain.getNextUnusedAddress();
    _accountIndex = accountIndex;
    final evmKey = auth.getActiveEvmKey(accountIndex: _accountIndex);
    contractParams = params.toContractParams(evmKey);

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

    // Acquire a lock so the auto-withdraw service knows not to drain balance.
    // All contract params are persisted so a background worker can resume the
    // deposit if the app is killed after the swap-in completes.
    await _lockRegistry.acquire(
      tradeId: contractParams.tradeId,
      reservedAmount: BitcoinAmount.fromAmount(params.amount),
      sellerEvmAddress: contractParams.sellerEvmAddress,
      arbiterEvmAddress: contractParams.arbiterEvmAddress,
      contractAddress: params.escrowService.parsedContent.contractAddress,
      chainId: params.escrowService.parsedContent.chainId,
      unlockAt: contractParams.unlockAt,
      accountIndex: _accountIndex,
    );

    try {
      logger.i(
        'Creating escrow for tradeId ${contractParams.tradeId} at ${params.escrowService.parsedContent.contractAddress} (accountIndex: $_accountIndex)',
      );
      await _swapRequiredAmount();

      // Mark ready — swap is done, balance is available for the deposit.
      await _lockRegistry.updateStatus(
        contractParams.tradeId,
        status: EscrowLockStatus.readyToDeposit,
      );

      emit(EscrowFundDepositing());
      TransactionInformation tx = await contract.deposit(contractParams);
      final txHash = _extractTxHash(tx);
      if (txHash != null) {
        // Persist the tx hash so a background worker can monitor it.
        await _lockRegistry.updateStatus(
          contractParams.tradeId,
          status: EscrowLockStatus.depositing,
          depositTxHash: txHash,
        );
        emit(EscrowFundDepositing(txHash: txHash));
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
      emit(EscrowFundCompleted(transactionInformation: tx));
    } catch (error, stackTrace) {
      logger.e('Escrow failed', error: error, stackTrace: stackTrace);
      final e = EscrowFundFailed(error, stackTrace);
      emit(e);
      throw e;
    } finally {
      await _lockRegistry.release(contractParams.tradeId);
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

    final transactionFee = await contract.estimateDespositFee(contractParams);

    final leftAfterTrade =
        balance - BitcoinAmount.fromAmount(params.amount) - transactionFee;

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

  Future<void> _swapRequiredAmount() async {
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
          invoiceDescription: params.swapInvoiceDescription,
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
          invoiceDescription: params.swapInvoiceDescription,
        ),
      );
      final sub = swap.stream.listen((state) {
        emit(EscrowFundSwapProgress(state));
      });

      try {
        await swap.execute();
      } finally {
        await sub.cancel();
      }
    }
  }
}
