import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:permissionless/permissionless.dart' as permissionless;
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';

import '../../../../injection.dart';
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

  String get tradeId => params?.negotiateReservation.getDtag() ?? '';

  /// Description for the swap-in LN invoice.
  String get swapInvoiceDescription => params!.swapInvoiceDescription;

  // ── Prepare ─────────────────────────────────────────────────────────

  /// Resolve signer, build fund calls, estimate gas, compute swap amount,
  /// and return ready-to-go [SwapInParams].
  Future<SwapInParams> prepare() => logger.span('prepare', () async {
    final resolved = await _resolveSignerAndBuildCalls();
    final quote = await _buildQuote(resolved);

    final claimAddress = await configuredChain.getAccountAddress(_signer);

    return SwapInParams(
      evmKey: _signer,
      accountIndex: accountIndex,
      amount: quote.resolvedSwapAmount,
      invoiceDescription: swapInvoiceDescription,
      claimAddress: claimAddress,
      parentOperationId: tradeId,
      postClaimCalls: resolved.fundCalls,
      postClaimStateOverrides: resolved.stateOverrides,
    );
  });

  // ── Fee estimation ────────────────────────────────────────────────

  Future<FeeBreakdown> estimateFees() => logger.span('estimateFees', () async {
    final resolved = await _resolveSignerAndBuildCalls();
    final quote = await _buildQuote(resolved);
    return quote.feeBreakdown;
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

    // Resolve the funding token once — avoids redundant on-chain calls.
    final fundingToken = await configuredChain.resolveBoltzFundingToken();
    final fundingAmount = await configuredChain.resolveAmountInFundingToken(
      params.amount,
    );

    final fundCalls = _buildFundCalls(params, fundingToken, fundingAmount);
    final stateOverrides = await _buildGasEstimationStateOverrides(
      fundCalls,
      signer,
      fundingToken,
    );

    // ── Escrow fee ──
    final tokenAddress = fundingToken.isERC20 ? fundingToken.address : 'native';
    final escrowFeeValue = params.escrowService.escrowFee(
      fundingAmount.value,
      tokenAddress: tokenAddress,
    );
    final escrowFee = TokenAmount(value: escrowFeeValue, token: fundingToken);

    return _ResolvedCalls(
      fundCalls: fundCalls,
      fundingAmount: fundingAmount,
      escrowFee: escrowFee,
      tokenAddress: fundingToken.isERC20
          ? EthereumAddress.fromHex(fundingToken.address)
          : null,
      stateOverrides: stateOverrides,
    );
  }

  Future<SwapInQuote> _buildQuote(_ResolvedCalls resolved) {
    final swapInParams = SwapInParams(
      evmKey: _signer,
      accountIndex: accountIndex,
      amount: resolved.fundingAmount,
      postClaimCalls: resolved.fundCalls,
      postClaimStateOverrides: resolved.stateOverrides,
    );
    return getIt<SwapInQuoteService>().buildQuote(
      chain: configuredChain,
      params: swapInParams,
      escrowFee: resolved.escrowFee,
    );
  }

  // ── Internal: call building ───────────────────────────────────────

  Map<String, Call> _buildFundCalls(
    EscrowFundParams params,
    Token fundingToken,
    TokenAmount fundingAmount,
  ) {
    final fundCall = contract.fund(
      _buildFundArgs(params, fundingToken, fundingAmount),
    );
    final approveCall = _buildApproveCallIfNeeded(
      params,
      fundingToken,
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
    return FundArgs(
      tradeId: params.negotiateReservation.getDtag()!,
      amount: amount,
      sellerEvmAddress: params.sellerProfile.evmAddress!,
      arbiterEvmAddress: params.escrowService.evmAddress,
      unlockAt: params.negotiateReservation.end.millisecondsSinceEpoch ~/ 1000,
      escrowFee: escrowFee,
      ethKey: _signer,
      token: isERC20 ? token : null,
    );
  }

  // ── Internal: gas estimation state overrides ──────────────────────

  Future<List<permissionless.StateOverride>?> _buildGasEstimationStateOverrides(
    Map<String, Call> calls,
    EthPrivateKey signer,
    Token token,
  ) async {
    final params = this.params;
    if (params == null) return null;

    if (!token.isERC20) return null;

    final tokenAddress = EthereumAddress.fromHex(token.address);
    final smartAccount = await configuredChain.getAccountAddress(signer);
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

  const _ResolvedCalls({
    required this.fundCalls,
    required this.fundingAmount,
    required this.escrowFee,
    required this.tokenAddress,
    this.stateOverrides,
  });
}
