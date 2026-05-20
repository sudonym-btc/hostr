import 'package:injectable/injectable.dart' hide Order;
import 'package:models/main.dart';
import 'package:permissionless/permissionless.dart' as permissionless;
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';

import '../../../../util/custom_logger.dart';
import '../../../auth/auth.dart';
import '../../../evm/main.dart';
import '../../../trade_account_allocator/trade_account_allocator.dart';
import '../../supported_escrow_contract/supported_escrow_contract.dart';
import 'escrow_fund_models.dart';

/// Stateless preparer that builds [SwapInParams] with `postClaimCalls`
/// containing the escrow fund calls (`[approve?, fund]`).
///
/// The swap operation itself handles all persistence and recovery.
/// This class does **not** own any state — it resolves the signer, estimates
/// gas, computes the required swap amount, and returns ready-to-go params.
@injectable
class EscrowFundPreparer {
  final Auth auth;
  final TradeAccountAllocator tradeAccountAllocator;
  final Evm evm;
  final SwapQuoteService quoteService;
  final CustomLogger logger;
  final EscrowFundParams? params;

  late EvmChain configuredChain;
  late SupportedEscrowContract contract;

  int accountIndex = 0;

  /// Resolved EVM signing key, set during [prepare] or [estimateFees].
  late EthPrivateKey _signer;

  EscrowFundPreparer(
    this.auth,
    this.tradeAccountAllocator,
    this.evm,
    this.quoteService,
    CustomLogger logger,
    @factoryParam this.params,
  ) : logger = logger.scope('escrow-fund') {
    if (params != null) {
      configuredChain = evm.getChainForEscrowService(params!.escrowService);
      contract = configuredChain.escrow.getSupportedEscrowContract(
        params!.escrowService,
      );
    }
  }

  // ── Public API ──────────────────────────────────────────────────────

  String get tradeId => params?.negotiateOrder.getDtag() ?? '';

  /// Description for the swap-in LN invoice.
  String get swapInvoiceDescription => params!.swapInvoiceDescription;

  // ── Prepare ─────────────────────────────────────────────────────────

  /// Resolve signer, build fund calls, estimate gas, compute swap amount,
  /// and return ready-to-go [SwapInParams].
  Future<SwapInParams> prepare() => logger.span('prepare', () async {
    final resolved = await _resolveSignerAndBuildCalls();
    final (quote, quotedParams) = await _buildQuote(resolved);

    return SwapInParams(
      evmKey: _signer,
      accountIndex: accountIndex,
      amountSpec: AmountSpec.output(quote.sendAmount),
      invoiceDescription: swapInvoiceDescription,
      claimAddress: resolved.claimAddress,
      parentOperationId: tradeId,
      // Use the params mutated by buildSwapInQuote — it prepends DEX hop calls
      // (approve tBTC + UniversalRouter.execute) when the escrow token is not
      // the Boltz bridge token (e.g. USDT listings).
      postClaimCalls: quotedParams.postClaimCalls,
      dexInputBuffer: params!.dexInputBuffer,
      postClaimStateOverrides: resolved.stateOverrides,
    );
  });

  // ── Fee estimation ────────────────────────────────────────────────

  Future<FeeBreakdown> estimateFees() => logger.span('estimateFees', () async {
    final resolved = await _resolveSignerAndBuildCalls();
    final (quote, _) = await _buildQuote(resolved);
    final escrowFundQuote = EscrowFundQuote(
      swapQuote: quote,
      escrowFee: resolved.escrowFee,
    );
    return escrowFundQuote.feeBreakdown;
  });

  // ── Internal: shared signer + call resolution ─────────────────────

  Future<_ResolvedCalls> _resolveSignerAndBuildCalls() async {
    final params = _requireParams();

    accountIndex =
        await tradeAccountAllocator.tryFindTradeAccountIndexByTradeId(
          tradeId,
        ) ??
        0;
    final signer = await auth.hd.getActiveEvmKey(accountIndex: accountIndex);
    _signer = signer;
    await contract.ensureDeployed();

    // Resolve the escrow token — the on-chain token the seller accepts for
    // the listing's denomination (e.g. USDT for a USD listing).
    // Source of truth is the seller's EscrowMethod event when available;
    // falls back to the Boltz bridge token (tBTC) otherwise.
    final Token escrowToken;
    final TokenAmount fundingAmount;
    if (params.sellerEscrowMethod != null) {
      escrowToken = await configuredChain.resolveEscrowToken(
        params.amount,
        params.sellerEscrowMethod!,
      );
      fundingAmount = configuredChain.scaleToToken(params.amount, escrowToken);
    } else {
      escrowToken = await configuredChain.resolveBridgeToken();
      fundingAmount = await configuredChain.resolveAmountInFundingToken(
        params.amount,
      );
    }

    // Resolve the optional security deposit in the same escrow token.
    final TokenAmount? bondAmount = params.securityDeposit != null
        ? configuredChain.scaleToToken(params.securityDeposit!, escrowToken)
        : null;

    // Resolve the smart-account address once here — it is reused by
    // _buildGasEstimationStateOverrides, _buildQuote, and prepare() so that
    // getAccountAddress (which may involve an RPC round-trip on first call)
    // is only invoked once per prepare/estimateFees call.
    final claimAddress = await configuredChain.getAccountAddress(signer);

    final fundCalls = _buildFundCalls(
      params,
      escrowToken,
      fundingAmount,
      bondAmount,
    );
    final stateOverrides = await _buildGasEstimationStateOverrides(
      fundCalls,
      claimAddress,
      escrowToken,
    );

    // ── Escrow fee (in the escrow token, e.g. USDT for USD listings) ──
    final tokenAddress = escrowToken.isERC20 ? escrowToken.address : 'native';
    final escrowFeeValue = params.escrowService.escrowFee(
      fundingAmount.value,
      tokenAddress: tokenAddress,
    );
    final escrowFee = TokenAmount(value: escrowFeeValue, token: escrowToken);

    return _ResolvedCalls(
      fundCalls: fundCalls,
      fundingAmount: fundingAmount,
      escrowFee: escrowFee,
      claimAddress: claimAddress,
      tokenAddress: escrowToken.isERC20
          ? EthereumAddress.fromHex(escrowToken.address)
          : null,
      stateOverrides: stateOverrides,
    );
  }

  /// Builds the [SwapQuote] for the resolved calls and returns it together
  /// with the [SwapInParams] object that [SwapQuoteService.buildSwapInQuote]
  /// may have mutated (e.g. by prepending DEX hop calls to
  /// [SwapInParams.postClaimCalls] when the escrow token is not the Boltz
  /// bridge token).
  Future<(SwapQuote, SwapInParams)> _buildQuote(_ResolvedCalls resolved) async {
    final swapInParams = SwapInParams(
      evmKey: _signer,
      accountIndex: accountIndex,
      amountSpec: AmountSpec.output(resolved.fundingAmount),
      // Pre-resolved address — prevents downstream helpers
      // (buildSwapInQuote, _buildClaimEstimationStateOverrides) from
      // issuing additional getAccountAddress RPC calls.
      claimAddress: resolved.claimAddress,
      postClaimCalls: resolved.fundCalls,
      dexInputBuffer: _requireParams().dexInputBuffer,
      postClaimStateOverrides: resolved.stateOverrides,
    );
    final quote = await quoteService.buildSwapInQuote(
      chain: configuredChain,
      params: swapInParams,
    );
    // Return both — swapInParams.postClaimCalls may now contain prepended DEX
    // calls injected by buildSwapInQuote (approve bridgeToken + router.execute)
    // that must be included in the final SwapInParams for actual execution.
    return (quote, swapInParams);
  }

  // ── Internal: call building ───────────────────────────────────────

  Map<String, Call> _buildFundCalls(
    EscrowFundParams params,
    Token escrowToken,
    TokenAmount fundingAmount,
    TokenAmount? bondAmount,
  ) {
    final fundCall = contract.fund(
      _buildFundArgs(params, escrowToken, fundingAmount, bondAmount),
    );
    final approveCall = _buildApproveCallIfNeeded(
      params,
      escrowToken,
      fundingAmount,
    );
    return {'ERC20.approve': ?approveCall, 'createTrade': fundCall};
  }

  Call? _buildApproveCallIfNeeded(
    EscrowFundParams params,
    Token token,
    TokenAmount fundingAmount,
  ) {
    if (!token.isERC20) return null;

    final builder = BoltzCallBuilder(configuredChain.swaps!);
    return builder.erc20Approve(
      tokenAddress: EthereumAddress.fromHex(token.address),
      spender: contract.address,
      amount: fundingAmount.value,
    );
  }

  FundArgs _buildFundArgs(
    EscrowFundParams params,
    Token token,
    TokenAmount amount,
    TokenAmount? bondAmount,
  ) {
    final isERC20 = token.isERC20;

    final tokenAddress = isERC20 ? token.address : 'native';
    final feeValue = params.escrowService.escrowFee(
      amount.value,
      tokenAddress: tokenAddress,
    );
    final escrowFee = TokenAmount(value: feeValue, token: token);
    logger.d(
      'escrowFee: $escrowFee for amount: $amount (token: $tokenAddress)',
    );
    if (bondAmount != null) {
      logger.d('bondAmount: $bondAmount');
    }
    return FundArgs(
      tradeId: params.negotiateOrder.getDtag()!,
      amount: amount,
      bondAmount: bondAmount,
      sellerEvmAddress: params.sellerEvmAddress,
      arbiterEvmAddress: params.escrowService.evmAddress,
      unlockAt: params.negotiateOrder.end != null
          ? params.negotiateOrder.end!.millisecondsSinceEpoch ~/ 1000 +
                (params.maxDisputePeriod ??
                    ListingTagRead.defaultMaxDisputePeriod)
          : DateTime.now()
                    .add(const Duration(days: 30))
                    .millisecondsSinceEpoch ~/
                1000,
      escrowFee: escrowFee,
      ethKey: _signer,
      token: isERC20 ? token : null,
    );
  }

  // ── Internal: gas estimation state overrides ──────────────────────

  Future<List<permissionless.StateOverride>?> _buildGasEstimationStateOverrides(
    Map<String, Call> calls,
    EthereumAddress smartAccount,
    Token token,
  ) async {
    final params = this.params;
    if (params == null) return null;

    if (!token.isERC20) return null;

    final tokenAddress = EthereumAddress.fromHex(token.address);
    final escrowAddress = contract.address;

    final tokenConfig = configuredChain.config.tokenByAddress(token.address);
    final balanceSlot = BigInt.from(tokenConfig?.balanceStorageSlot ?? 0);
    final allowanceSlot = BigInt.from(tokenConfig?.allowanceStorageSlot ?? 1);

    final balanceOverride = permissionless.erc20BalanceOverride(
      token: tokenAddress,
      owner: smartAccount,
      slot: balanceSlot,
    );
    final allowanceOverride = permissionless.erc20AllowanceOverride(
      token: tokenAddress,
      owner: smartAccount,
      spender: escrowAddress,
      slot: allowanceSlot,
    );

    return permissionless.mergeStateOverrides([
      ...balanceOverride,
      ...allowanceOverride,
    ]);
  }

  // ── Helpers ───────────────────────────────────────────────────────

  EscrowFundParams _requireParams() {
    final params = this.params;
    if (params == null) {
      throw StateError('EscrowFundPreparer requires params');
    }
    return params;
  }
}

/// Internal value object holding the resolved signer, fund calls, gas estimate,
/// and escrow fee — shared between [EscrowFundPreparer.prepare] and
/// [EscrowFundPreparer.estimateFees] to avoid duplicate work.
class _ResolvedCalls {
  final Map<String, Call> fundCalls;
  final TokenAmount fundingAmount;
  final TokenAmount escrowFee;
  final EthereumAddress? tokenAddress;
  final List<permissionless.StateOverride>? stateOverrides;

  /// Pre-resolved smart-account (or EOA) address for this signer.
  /// Passed into [SwapInParams.claimAddress] so downstream helpers
  /// never need to call [EvmChain.getAccountAddress] again.
  final EthereumAddress claimAddress;

  const _ResolvedCalls({
    required this.fundCalls,
    required this.fundingAmount,
    required this.escrowFee,
    required this.tokenAddress,
    required this.claimAddress,
    this.stateOverrides,
  });
}
