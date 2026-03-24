import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:wallet/wallet.dart' show EtherAmount, EthereumAddress;
import 'package:web3dart/web3dart.dart';

import '../../../../datasources/contracts/boltz/IERC20.g.dart';
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
      configuredChain = evm.getChainForEscrowService(params!.escrowService);
      contract = configuredChain.escrow.getSupportedEscrowContract(
        params!.escrowService,
      );
    }
  }

  /// Create for recovery mode. [recoveryChain] and [recoveryContract] are pre-resolved.
  EscrowFundOperation.forRecovery(
    Auth auth,
    TradeAccountAllocator tradeAccountAllocator,
    Evm evm,
    CustomLogger logger, {
    required ConfiguredEvmChain recoveryChain,
    required SupportedEscrowContract recoveryContract,
    required OnchainOperationState initialState,
  }) : params = null,
       super(auth, tradeAccountAllocator, evm, logger, initialState) {
    configuredChain = recoveryChain;
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

  @override
  Future<void> execute() => logger.span('executeEscrowFund', () async {
    final persistedJson = await store.read(namespace, tradeId);
    if (persistedJson != null) {
      final persistedState = stateFromJson(persistedJson);
      if (!persistedState.isTerminal) {
        if (await _shouldDiscardPersistedState(persistedState)) {
          logger.w(
            'Discarding stale persisted $namespace state '
            '"${persistedState.stateName}" for trade $tradeId before retry',
          );
          await store.remove(namespace, tradeId);
        } else {
          logger.i(
            'Resuming persisted $namespace state '
            '"${persistedState.stateName}" for trade $tradeId',
          );
          emit(persistedState);
          await run();
          return;
        }
      }
    }

    await super.execute();
  });

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
    required List<CallIntent> callIntents,
    required String transport,
  }) {
    final params = _requireParams();
    return EscrowFundData(
      tradeId: params.negotiateReservation.getDtag()!,
      contractAddress: params.escrowService.contractAddress,
      chainId: params.escrowService.chainId,
      accountIndex: accountIndex,
      callIntents: callIntents,
      transport: transport,
    );
  }

  @override
  Future<List<CallIntent>> buildCallIntents() async {
    final params = _requireParams();
    final fundIntent = contract.fund(await _buildFundArgs(params));
    final approveIntent = _buildApproveIntentIfNeeded(params);
    return [
      if (approveIntent != null) approveIntent,
      fundIntent,
    ];
  }

  @override
  void onGasEstimated(GasEstimate estimate) =>
      logger.spanSync('onGasEstimated', () {});

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
        'The funding call was likely not executed correctly by the gas sponsor '
        'or the inner ERC20 createTrade reverted.',
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
        if (gasUsed != null) {
          logger.d(
            'Gas usage: actual=$gasUsed units for trade $tradeId',
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
    logger.i(
      'Nested swap claim confirmed in tx $claimTxHash for trade $tradeId; '
      'continuing to escrow funding broadcast',
    );
    return data;
  }

  Future<void> _ensureSwapClaimAddress() =>
      logger.span('ensureSwapClaimAddress', () async {
        final ethKey = await _activeEthKey();
        _swapClaimAddress = await configuredChain.aa!.getSmartAccountAddress(
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
    final params = _requireParams();
    final fundingAmount = _resolveFundingAmount(params);
    final gasComponent = fundingAmount.token.isERC20
        ? TokenAmount.zero(fundingAmount.token)
        : TokenAmount(value: gasEstimate.fee.value, token: fundingAmount.token);
    final totalRequired = fundingAmount + gasComponent;
    final limits = await configuredChain.getSwapInLimits();
    final swapAmount = TokenAmount.max(
      limits.min,
      TokenAmount(
        value: totalRequired.inSats * BigInt.from(10).pow(10),
        token: limits.min.token,
      ),
    ).roundUpToSats();

    logger.i(
      'Swap funding: '
      'funding=${fundingAmount.getInSats}, '
      'gas=${fundingAmount.token.isERC20 ? 0 : gasEstimate.fee.getInSats}, '
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
    SwapInOperation swapEstimation = configuredChain.swapIn(
      auth: auth,
      logger: logger,
      params: SwapInParams(
        evmKey: evmKey,
        accountIndex: accountIndex,
        amount: swapAmount,
        invoiceDescription: swapInvoiceDescription,
        claimAddress: swapClaimAddress,
      ),
    );
    final swapFees = await swapEstimation.estimateFees();

    // Second pass: create the real swap with amount + overhead.
    SwapInOperation swap = configuredChain.swapIn(
      auth: auth,
      logger: logger,
      params: SwapInParams(
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
      final intents = await buildCallIntents();
      final gasEstimate = await estimateCallIntentsFee(intents);
      final data = buildInitialData(
        callIntents: intents,
        transport: 'direct',
      );
      final swapAmount = await _computeRequiredSwapAmount(data, gasEstimate);
      final swapFees = await configuredChain
          .swapIn(
            auth: auth,
            logger: logger,
            params: SwapInParams(
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
        callIntents: intents,
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

  Future<bool> _shouldDiscardPersistedState(
    OnchainOperationState persistedState,
  ) async {
    if (persistedState is! OnchainTxSent) return false;

    final txHash = persistedState.data.txHash;
    if (txHash == null || txHash.isEmpty) return false;

    final receipt = await configuredChain.chain.client.getTransactionReceipt(
      txHash,
    );
    if (receipt == null) return false;

    final hasEscrowLog = receipt.logs.any(
      (log) => log.address == contract.address,
    );
    if (hasEscrowLog) return false;

    logger.w(
      'Persisted escrow_fund tx $txHash for trade $tradeId '
      'has status=${receipt.status} and no logs from escrow contract '
      '${contract.address.eip55With0x}; treating it as stale',
    );
    return true;
  }

  CallIntent? _buildApproveIntentIfNeeded(EscrowFundParams params) {
    final token = _resolveFundingToken(params);
    if (!token.isERC20) return null;

    // The ERC-20 approval must match the exact token-denominated amount that
    // `createTrade` will pull via `transferFrom`. Using `params.amount.value`
    // is wrong when the original reservation amount is expressed in sats and
    // later remapped into an ERC-20 token with different decimals.
    final fundingAmount = _resolveFundingAmount(params);

    final tokenAddress = EthereumAddress.fromHex(token.address);
    final erc20 = IERC20(
      address: tokenAddress,
      client: configuredChain.chain.client,
    );
    final approveFn = erc20.self.abi.functions.firstWhere(
      (f) => f.name == 'approve',
    );

    return CallIntent(
      to: tokenAddress,
      data: approveFn.encodeCall([contract.address, fundingAmount.value]),
      value: EtherAmount.zero(),
      methodName: 'ERC20.approve',
    );
  }

  Future<FundArgs> _buildFundArgs(EscrowFundParams params) async {
    final token = _resolveFundingToken(params);
    final isERC20 = token.isERC20;

    final TokenAmount amount;
    final TokenAmount? escrowFee;

    if (isERC20) {
      amount = _resolveFundingAmount(params);
      // Compute escrow fee in the same token units using BigInt to avoid
      // overflow for large token values.
      final fp = params.escrowService.feePercent;
      final fb = BigInt.from(params.escrowService.feeBase);
      final fee =
          (amount.value * BigInt.from((fp * 100).round())) ~/
              BigInt.from(10000) +
          fb;
      escrowFee = TokenAmount(value: fee, token: token);
    } else {
      amount = _resolveFundingAmount(params);
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
      token: isERC20 ? token : null,
    );
  }

  Token _resolveFundingToken(EscrowFundParams params) {
    // Resolve the concrete on-chain token from chain configuration.
    // The EscrowFundParams.amount is a DenominatedAmount (e.g. "BTC" sats),
    // so we look at the chain's swap provider to determine the funding token.
    final swapProvider = configuredChain.swaps;
    if (swapProvider?.isErc20 == true && swapProvider?.tokenAddress != null) {
      final tokenAddress = swapProvider!.tokenAddress!;
      var decimals = 18;
      for (final tokenConfig in configuredChain.config.tokens.values) {
        if (tokenConfig.address.toLowerCase() ==
            tokenAddress.eip55With0x.toLowerCase()) {
          decimals = tokenConfig.decimals;
          break;
        }
      }
      return Token(
        chainId: configuredChain.config.chainId,
        address: tokenAddress.eip55With0x,
        decimals: decimals,
      );
    }

    return Token.rbtc(configuredChain.config.chainId);
  }

  TokenAmount _resolveFundingAmount(EscrowFundParams params) {
    final denominated = params.amount;
    final resolvedToken = _resolveFundingToken(params);

    // Scale from denomination decimals to token decimals.
    final scale = resolvedToken.decimals - denominated.decimals;
    final value = scale <= 0
        ? denominated.value
        : denominated.value * BigInt.from(10).pow(scale);

    logger.i(
      'Resolved escrow funding amount: '
      '${denominated.denomination} ${denominated.value} '
      '→ ${resolvedToken.tagId} $value for trade $tradeId',
    );

    return TokenAmount(value: value, token: resolvedToken);
  }
}
