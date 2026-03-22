import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';

import '../../../../injection.dart';
import '../../../../util/custom_logger.dart';
import '../../../../util/token_amount_ext.dart';
import '../../../auth/auth.dart';
import '../../../evm/main.dart';
import '../../../trade_account_allocator/trade_account_allocator.dart';
import '../../supported_escrow_contract/supported_escrow_contract.dart';
import '../onchain_operation.dart';
import 'escrow_fund_models.dart';
import 'escrow_fund_state.dart';

@injectable
class EscrowFundOperation extends OnchainOperation {
  final EscrowFundParams? params;
  GasEstimate? _gasEstimate;

  @override
  String get tradeId => params!.negotiateReservation.getDtag()!;

  EscrowFundOperation(
    Auth auth,
    TradeAccountAllocator tradeAccountAllocator,
    Evm evm,
    CustomLogger logger,
    @factoryParam this.params,
  ) : super(
        auth,
        tradeAccountAllocator,
        evm,
        logger,
        const OnchainInitialised(),
      ) {
    if (params != null) {
      chain = evm.getChainForEscrowService(params!.escrowService);
      contract = chain.getSupportedEscrowContract(params!.escrowService);
    }
  }

  /// Create for recovery mode. [recoveryChain] and [recoveryContract] are pre-resolved.
  EscrowFundOperation.forRecovery(
    Auth auth,
    TradeAccountAllocator tradeAccountAllocator,
    Evm evm,
    CustomLogger logger, {
    required EvmChain recoveryChain,
    required SupportedEscrowContract recoveryContract,
    required OnchainOperationState initialState,
  }) : params = null,
       super(auth, tradeAccountAllocator, evm, logger, initialState) {
    chain = recoveryChain;
    contract = recoveryContract;
    final data = initialState.data;
    if (data is EscrowFundData) {
      accountIndex = data.accountIndex;
    }
  }

  // ── OnchainOperation overrides ────────────────────────────────────

  @override
  String get namespace => 'escrow_fund';

  @override
  OnchainOperationData dataFromJson(Map<String, dynamic> json) =>
      EscrowFundData.fromJson(json);

  @override
  Future<void> initialize() async {
    await super.initialize();
    await _ensureSwapClaimAddress();
  }

  /// Description for the swap-in LN invoice.
  String get swapInvoiceDescription => params!.swapInvoiceDescription;

  EthereumAddress? _swapClaimAddress;

  /// Address used as the Boltz reverse swap claim address.
  EthereumAddress get swapClaimAddress {
    final address = _swapClaimAddress;
    if (address == null) {
      throw StateError('swapClaimAddress accessed before initialization');
    }
    return address;
  }

  @override
  OnchainOperationData buildInitialData({
    required ContractCallIntent callIntent,
    required String transport,
  }) {
    final params = _requireParams();
    return EscrowFundData(
      tradeId: params.negotiateReservation.getDtag()!,
      contractAddress: params.escrowService.contractAddress,
      chainId: params.escrowService.chainId,
      accountIndex: accountIndex,
      callIntent: callIntent,
      transport: transport,
    );
  }

  @override
  Future<ContractCallIntent> buildDirectCallIntent() async {
    final params = _requireParams();
    return contract.fund(await _buildFundArgs(params));
  }

  @override
  void onGasEstimated(GasEstimate estimate) =>
      logger.spanSync('onGasEstimated', () {
        _gasEstimate = estimate;
      });

  @override
  void validateConfirmedTransaction(
    OnchainOperationData data,
    TransactionReceipt receipt,
  ) => logger.spanSync('validateConfirmedTransaction', () {
    // Verify the receipt contains at least one log from the escrow contract.
    // A successful transaction that emits no escrow logs means the inner
    // call was silently dropped (e.g. the relay wallet factory did not
    // forward the call data).
    final escrowAddress = contract.address;
    final hasEscrowLog = receipt.logs.any(
      (log) => log.address == escrowAddress,
    );
    if (!hasEscrowLog) {
      final txHash = data.txHash ?? 'unknown';
      throw StateError(
        'Transaction $txHash succeeded but contained no logs from the '
        'escrow contract (${escrowAddress.eip55With0x}). '
        'The funding call was likely not forwarded by the relay wallet.',
      );
    }
  });

  @override
  void onRunComplete(OnchainOperationState state) =>
      logger.spanSync('onRunComplete', () {
        if (state is! OnchainTxConfirmed) return;
        final data = state.data;
        final receipt = data.transactionReceipt;
        if (receipt == null) return;

        final gasUsed = receipt.gasUsed?.toInt();
        final estimatedLimit = data.callIntent?.maxGas;
        final gasPrice = data.callIntent?.gasPrice?.getInWei;
        if (gasUsed != null && estimatedLimit != null && gasPrice != null) {
          final refundGas = estimatedLimit - gasUsed;
          final refundWei = BigInt.from(refundGas) * gasPrice;
          logger.d(
            'Gas usage: estimated=$estimatedLimit, actual=$gasUsed, '
            'refunded=$refundGas units '
            '(~${rbtcFromWei(refundWei).getInSats} sats)',
          );
        }
      });

  /// Projects the nested swap's claim tx hash onto the parent operation data.
  OnchainOperationData _onNestedSwapFinished(
    OnchainOperationData data,
    SwapInState swapState,
  ) {
    final claimTxHash = swapState.data?.claimTxHash;
    if (claimTxHash == null || claimTxHash.isEmpty) {
      return data;
    }
    return data.copyWithTxHash(claimTxHash);
  }

  Future<void> _ensureSwapClaimAddress() =>
      logger.span('ensureSwapClaimAddress', () async {
        final ethKey = await _activeEthKey();
        _swapClaimAddress = await getIt<UserOpService>().getSmartAccountAddress(
          ethKey,
        );
      });

  // ── Swap-in support (fund-only) ───────────────────────────────────

  /// Fund operations include the [checkSwap] step for swap recovery.
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
  Future<OnchainOperationState> executeStep(OnchainStep step) {
    if (step == OnchainStep.checkSwap) return _stepCheckSwap();
    return super.executeStep(step);
  }

  /// Checks whether a nested swap-in has completed (recovery path).
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
              return OnchainTxBroadcast(_onNestedSwapFinished(data, swapState));
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

  /// Swap-in the full required amount before broadcast.
  @override
  Future<OnchainOperationData> beforeBroadcast(
    OnchainOperationData data,
    GasEstimate gasEstimate,
  ) => _swapEntireRequiredAmount(data, gasEstimate);

  /// Compute the full swap-in amount needed for funding + gas.
  ///
  /// Local balance is intentionally ignored: fund operations always source the
  /// complete required amount via swap-in.
  Future<TokenAmount> _computeRequiredSwapAmount(
    OnchainOperationData data,
    GasEstimate gasEstimate,
  ) => logger.span('computeRequiredSwapAmount', () async {
    final intent = data.callIntent;
    if (intent == null) {
      throw StateError('Cannot compute swap amount without a callIntent');
    }

    final requiredOnchainValue = rbtcFromWei(intent.value.getInWei);
    final totalRequired = requiredOnchainValue + gasEstimate.fee;
    final limits = await chain.getSwapInLimits();
    final swapAmount = TokenAmount.max(
      limits.min,
      totalRequired,
    ).roundUpToSats();

    logger.i(
      'Swap funding: '
      'required=${requiredOnchainValue.getInSats}, '
      'gas=${gasEstimate.fee.getInSats}, '
      'swapAmount=${swapAmount.getInSats}',
    );

    return swapAmount;
  });

  /// Runs a nested swap-in for the full required on-chain amount.
  Future<OnchainOperationData> _swapEntireRequiredAmount(
    OnchainOperationData data,
    GasEstimate gasEstimate,
  ) => logger.span('swapEntireRequiredAmount', () async {
    final swapAmount = await _computeRequiredSwapAmount(data, gasEstimate);

    final evmKey = await auth.hd.getActiveEvmKey(accountIndex: accountIndex);

    // First pass: estimate swap fees.
    SwapInOperation swapEstimation = chain.swapIn(
      SwapInParams(
        evmKey: evmKey,
        accountIndex: accountIndex,
        amount: swapAmount,
        invoiceDescription: swapInvoiceDescription,
        claimAddress: swapClaimAddress,
      ),
    );
    final swapFees = await swapEstimation.estimateFees();

    // Second pass: create the real swap with amount + overhead.
    SwapInOperation swap = chain.swapIn(
      SwapInParams(
        evmKey: evmKey,
        accountIndex: accountIndex,
        amount: (swapAmount + swapFees.totalFees).roundUpToSats(),
        invoiceDescription: swapInvoiceDescription,
        claimAddress: swapClaimAddress,
        parentOperationId: data.operationId,
      ),
    );
    swap.onProgress = onProgress;

    String? swapId;
    bool swapIdPersisted = false;
    final sub = swap.stream.listen((swapState) {
      swapId ??= swapState.operationId;

      if (!swapIdPersisted && swapId != null) {
        swapIdPersisted = true;
      }

      emit(
        OnchainSwapProgress(data.copyWithSwapId(swapId), swapState: swapState),
      );
    });

    try {
      await swap.execute();
    } finally {
      await sub.cancel();
    }

    if (swap.state is SwapInFailed) {
      final failed = swap.state as SwapInFailed;
      throw StateError('Nested swap-in failed: ${failed.error}');
    }

    final updatedData = data.copyWithSwapId(swapId);
    return _onNestedSwapFinished(updatedData, swap.state);
  });

  /// Override fee estimation to include the always-on swap-in.
  @override
  Future<OnchainFeeQuote> estimateOperationFees() => logger.span(
    'estimateOperationFees',
    () async {
      await initialize();
      final intent = await buildDirectCallIntent();
      final gasEstimate = await estimateCallIntentFee(intent);
      final pinnedIntent = intent.copyWith(
        gasPrice: gasEstimate.gasPrice,
        maxGas: gasEstimate.gasLimit.toInt(),
      );
      final data = buildInitialData(
        callIntent: pinnedIntent,
        transport: 'direct',
      );
      final swapAmount = await _computeRequiredSwapAmount(data, gasEstimate);
      final swapFees = await chain
          .swapIn(
            SwapInParams(
              evmKey: await auth.hd.getActiveEvmKey(accountIndex: accountIndex),
              accountIndex: accountIndex,
              amount: swapAmount,
              invoiceDescription: swapInvoiceDescription,
              claimAddress: swapClaimAddress,
            ),
          )
          .estimateFees();

      return OnchainFeeQuote(
        gasEstimate: gasEstimate,
        swapFees: swapFees,
        callIntent: pinnedIntent,
        transport: 'direct',
      );
    },
  );

  // ── Fee estimation (public) ───────────────────────────────────────

  Future<EscrowFundFees> estimateFees() =>
      logger.span('estimateFees', () async {
        final params = _requireParams();
        final fundArgs = await _buildFundArgs(params);
        await _ensureSwapClaimAddress();
        final quote = await estimateOperationFees();
        return EscrowFundFees(
          estimatedGasFees: quote.gasEstimate.fee,
          estimatedSwapFees: quote.swapFees,
          estimatedEscrowFees: fundArgs.escrowFee ?? TokenAmount.zero(rbtc),
        );
      });

  EscrowFundParams _requireParams() {
    final params = this.params;
    if (params == null) {
      throw StateError(
        'EscrowFundOperation params are unavailable in recovery',
      );
    }
    return params;
  }

  Future<EthPrivateKey> _activeEthKey() =>
      auth.hd.getActiveEvmKey(accountIndex: accountIndex);

  Future<FundArgs> _buildFundArgs(EscrowFundParams params) async {
    final token = params.amount.token;
    final isERC20 = token.isERC20;

    final TokenAmount amount;
    final TokenAmount? escrowFee;

    if (isERC20) {
      // ERC-20: use the raw token amount (already in the token's smallest unit).
      amount = params.amount;
      // Compute escrow fee in the same token units using BigInt to avoid
      // overflow for large token values.
      final fp = params.escrowService.feePercent;
      final fb = BigInt.from(params.escrowService.feeBase);
      final fee =
          (params.amount.value * BigInt.from((fp * 100).round())) ~/
              BigInt.from(10000) +
          fb;
      escrowFee = TokenAmount(value: fee, token: token);
    } else {
      amount = rbtcFromSats(params.amount.inSats);
      escrowFee = rbtcFromSatsInt(
        params.escrowService.escrowFee(amount.getInSats.toInt()),
      );
    }

    return FundArgs(
      tradeId: params.negotiateReservation.getDtag()!,
      amount: amount,
      sellerEvmAddress: params.sellerProfile.evmAddress!,
      arbiterEvmAddress: params.escrowService.evmAddress,
      unlockAt: params.negotiateReservation.end.millisecondsSinceEpoch ~/ 1000,
      escrowFee: escrowFee,
      ethKey: await _activeEthKey(),
      gasEstimate: _gasEstimate,
      token: isERC20 ? token : null,
    );
  }
}
