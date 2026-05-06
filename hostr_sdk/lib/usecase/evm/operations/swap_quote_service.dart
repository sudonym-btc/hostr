import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:permissionless/permissionless.dart' as permissionless;
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart' show keccak256;

import '../../../datasources/boltz/boltz_fee_estimate.dart';
import '../../../datasources/contracts/boltz/IERC20.g.dart';
import '../../../datasources/swagger_generated/boltz.swagger.dart' hide Call;
import '../../../util/custom_logger.dart';
import '../../../util/token_amount_ext.dart';
import '../capabilities/boltz_call_builder.dart';
import '../chain/evm_chain.dart';
import '../evm_call.dart';
import '../models/dex_quote.dart';
import '../models/swap_quote.dart';
import 'swap_in/swap_in_models.dart';
import 'swap_out/swap_out_models.dart';

enum _SwapInDexQuotePhase { estimate, preInvoice }

extension on _SwapInDexQuotePhase {
  String get logName => switch (this) {
    _SwapInDexQuotePhase.estimate => 'estimate',
    _SwapInDexQuotePhase.preInvoice => 'pre-invoice',
  };
}

class _SwapInQuoteContext {
  _SwapInQuoteContext({
    required this.chain,
    required this.params,
    required this.requestedTokenAddress,
    required this.needsDex,
    required this.originalReceiveAmount,
    required this.originalPostClaimCalls,
    this.bridgeAddress,
    this.bridgeToken,
    this.dexRecipient,
  });

  final EvmChain chain;
  final SwapInParams params;
  final EthereumAddress? requestedTokenAddress;
  final bool needsDex;
  final TokenAmount originalReceiveAmount;
  final Map<String, Call>? originalPostClaimCalls;
  final EthereumAddress? bridgeAddress;
  final Token? bridgeToken;
  final EthereumAddress? dexRecipient;

  DexQuote? dexQuote;
}

/// Unified swap quoting service — replaces the former `SwapInQuoteService`
/// and `SwapOutQuoteService` with one injectable that exposes both directions.
///
/// Follows the Boltz web app pattern: one service, two methods, same return
/// type ([SwapQuote]).
///
/// ## DEX hop (non-Boltz tokens, e.g. USDT)
///
/// When the requested token is not natively supported by Boltz (i.e. it does
/// not appear in `BoltzChainInfo.tokens`), a DEX hop is injected automatically:
///
/// - **Swap-in** (Lightning → USDT): Boltz delivers the bridge token (tBTC)
///   on-chain, then a tBTC → USDT DEX swap is appended to
///   [SwapInParams.postClaimCalls] so both steps execute atomically in one
///   UserOperation.
///
/// - **Swap-out** (USDT → Lightning): a USDT → tBTC DEX swap is prepended to
///   [SwapOutParams.preLockCalls], and the bridge-token amount is then locked
///   into the Boltz submarine swap contract — again in one atomic UserOp.
///
/// DEX calldata is fetched from the Boltz Quote API
/// (`/v2/quote/{chainKey}/in`, `/out`, `/encode`) and the [DexQuote] is
/// stored on the returned [SwapQuote] for UI / debugging purposes.
/// Swap-in DEX routes keep the requested output exact while adding a small
/// bridge-token input buffer by default, so the DEX leg can tolerate tiny
/// quote movement without changing the escrow amount.
@injectable
class SwapQuoteService {
  final CustomLogger logger;

  SwapQuoteService({required CustomLogger logger})
    : logger = logger.scope('swap-quote');

  // ═══════════════════════════════════════════════════════════════════════
  //  Swap-In (Reverse Swap: Lightning → on-chain)
  // ═══════════════════════════════════════════════════════════════════════

  /// Build a [SwapQuote] for a swap-in (reverse swap).
  ///
  /// [chain]  — EVM chain to estimate gas on.
  /// [params] — swap-in parameters (amount, keys, optional post-claim calls).
  ///
  /// When [params.amount] refers to a non-Boltz token (e.g. USDT) this method
  /// injects a bridge→requested-token DEX step into [params.postClaimCalls]
  /// and mutates [params.amount] to the bridge token before continuing with
  /// the normal Boltz reverse-swap quote.  The returned [SwapQuote.receiveAmount]
  /// always reflects the original requested token/amount.
  Future<SwapQuote> buildSwapInQuote({
    required EvmChain chain,
    required SwapInParams params,
  }) async {
    final context = await _resolveSwapInQuoteContext(
      chain: chain,
      params: params,
    );

    if (context.needsDex) {
      await _applySwapInDexQuote(context, phase: _SwapInDexQuotePhase.estimate);
    }

    final gasEstimate = await _estimateSwapInClaimGas(context);

    if (context.needsDex) {
      // Refresh the executable DEX quote after gas estimation so the Boltz
      // invoice is created from the freshest possible bridge-token amount and
      // calldata. The earlier quote is only used to make gas estimation work.
      await _applySwapInDexQuote(
        context,
        phase: _SwapInDexQuotePhase.preInvoice,
      );
    }

    return _buildSwapInQuoteResult(context, gasEstimate);
  }

  Future<_SwapInQuoteContext> _resolveSwapInQuoteContext({
    required EvmChain chain,
    required SwapInParams params,
  }) async {
    final requestedTokenAddress = params.amount.token.isERC20
        ? EthereumAddress.fromHex(params.amount.token.address)
        : null;

    // ── DEX hop detection ──────────────────────────────────────────────────
    // When the requested token (e.g. USDT) is not the Boltz bridge token
    // (tBTC), inject a bridge → requested-token DEX step into postClaimCalls:
    //   Lightning → (Boltz reverse swap) → bridgeToken → (DEX) → requestedToken
    // all execute atomically in one UserOperation.
    //
    // NOTE: We compare against the bridge token directly rather than using
    // supportsTokenAddress(), because Boltz may list extra ERC-20s (e.g. USDT)
    // in /chain/contracts without having a BTC↔USDT swap pair.
    final needsDex =
        requestedTokenAddress != null &&
        !_isBridgeToken(chain, requestedTokenAddress);

    // Preserve the original receive amount (USDT) for the returned SwapQuote.
    final originalReceiveAmount = params.amount;
    final originalPostClaimCalls = params.postClaimCalls;
    EthereumAddress? bridgeAddress;
    Token? bridgeToken;
    EthereumAddress? dexRecipient;

    if (needsDex) {
      bridgeAddress = _findBridgeTokenAddress(chain);

      // Resolve the bridge token early — needed to round amountIn to sat
      // granularity before encoding the DEX calls (see below).
      bridgeToken = await chain.resolveToken(bridgeAddress.eip55With0x);

      // Resolve the claim address early — it is the DEX swap recipient.
      dexRecipient =
          params.claimAddress ?? await chain.getAccountAddress(params.evmKey);
    }

    return _SwapInQuoteContext(
      chain: chain,
      params: params,
      requestedTokenAddress: requestedTokenAddress,
      needsDex: needsDex,
      originalReceiveAmount: originalReceiveAmount,
      originalPostClaimCalls: originalPostClaimCalls,
      bridgeAddress: bridgeAddress,
      bridgeToken: bridgeToken,
      dexRecipient: dexRecipient,
    );
  }

  Future<void> _applySwapInDexQuote(
    _SwapInQuoteContext context, {
    required _SwapInDexQuotePhase phase,
  }) async {
    final requestedTokenAddress = context.requestedTokenAddress;
    final bridgeAddress = context.bridgeAddress;
    final bridgeToken = context.bridgeToken;
    final dexRecipient = context.dexRecipient;

    if (requestedTokenAddress == null ||
        bridgeAddress == null ||
        bridgeToken == null ||
        dexRecipient == null) {
      throw StateError('Cannot build swap-in DEX quote without DEX context.');
    }

    final dexQuote = await _fetchBufferedSwapInDexQuote(
      chain: context.chain,
      tokenIn: bridgeAddress,
      tokenOut: requestedTokenAddress,
      amountOut: context.originalReceiveAmount.value,
      bridgeToken: bridgeToken,
      requestedToken: context.originalReceiveAmount.token,
      buffer: context.params.dexInputBuffer,
      phase: phase,
    );

    // Encode the DEX calldata and prepend to postClaimCalls so the DEX swap
    // runs immediately after the Boltz claim in the same UserOp.
    final dexCalls = await _encodeDexCalls(
      chain: context.chain,
      dexQuote: dexQuote,
      recipient: dexRecipient,
    );
    context.params.postClaimCalls = {
      ...dexCalls,
      ...?context.originalPostClaimCalls,
    };

    // Switch params.amount to the bridge token for all Boltz-side
    // calculations (pair fetch, gas estimation, resolved amount).
    context.params.amount = TokenAmount(
      value: dexQuote.amountIn,
      token: bridgeToken,
    );
    context.dexQuote = dexQuote;
  }

  Future<({BigInt gasCostWei, bool gasSponsored})> _estimateSwapInClaimGas(
    _SwapInQuoteContext context,
  ) async {
    final stopwatch = Stopwatch()..start();
    final params = context.params;
    final chain = context.chain;
    final tokenAddress = params.amount.token.isERC20
        ? EthereumAddress.fromHex(params.amount.token.address)
        : null;

    // ── 1. Estimate gas for claim + post-claim calls ──
    final builder = BoltzCallBuilder(chain.swaps!);
    final dummyPreimage = Uint8List(32);
    final stateOverrides = await _buildClaimEstimationStateOverrides(
      chain: chain,
      params: params,
      preimage: dummyPreimage,
    );
    final dummyClaim = builder.claim(
      preimage: dummyPreimage,
      amount: params.amount.value,
      refundAddress: params.evmKey.address,
      timelock: BigInt.zero,
      tokenAddress: tokenAddress,
    );
    final estimationCalls = {'claim': dummyClaim, ...?params.postClaimCalls};
    final gasEstimate = await chain.estimateGas(
      params.evmKey,
      calls: estimationCalls,
      stateOverride: stateOverrides,
    );
    stopwatch.stop();
    logger.d(
      'Swap-in claim gas estimate completed in '
      '${stopwatch.elapsedMilliseconds} ms',
    );

    return gasEstimate;
  }

  Future<SwapQuote> _buildSwapInQuoteResult(
    _SwapInQuoteContext context,
    ({BigInt gasCostWei, bool gasSponsored}) gasEstimate,
  ) async {
    final params = context.params;
    final chain = context.chain;
    final chainId = params.amount.token.chainId;
    final nativeToken = Token.native(chainId);
    final gasFee = TokenAmount(
      value: gasEstimate.gasCostWei,
      token: nativeToken,
    );
    final tokenAddress = params.amount.token.isERC20
        ? EthereumAddress.fromHex(params.amount.token.address)
        : null;

    // ── 2. Single Boltz pair fetch → limits + fee rates ──
    final pair = await chain.swaps!.getReversePair(tokenAddress: tokenAddress);

    // ── 3. Compute resolved swap amount ──
    final isErc20 = tokenAddress != null;
    final gasComponent = isErc20
        ? TokenAmount.zero(params.amount.token)
        : TokenAmount(value: gasFee.value, token: params.amount.token);
    final totalNeeded = params.amount + gasComponent;

    final minSats = BigInt.from(pair.limits.minimal.ceil());
    final neededSats = totalNeeded.inSats;
    final resolvedSats = neededSats < minSats ? minSats : neededSats;

    final resolvedSwapAmount = TokenAmount.fromDenominated(
      DenominatedAmount(denomination: 'BTC', value: resolvedSats, decimals: 8),
      params.amount.token,
    ).roundUpToSats();

    // ── 4. Compute Boltz fees for the resolved amount ──
    final boltzEstimate = BoltzFeeEstimate.reverseFromReceive(
      pair,
      resolvedSwapAmount.getInSats.toInt(),
    );

    return SwapQuote(
      boltzEstimate: boltzEstimate,
      gasFee: gasFee,
      gasSponsored: gasEstimate.gasSponsored,
      sendAmount: resolvedSwapAmount,
      receiveAmount: context.originalReceiveAmount,
      dexQuote: context.dexQuote,
    );
  }

  Future<DexQuote> _fetchBufferedSwapInDexQuote({
    required EvmChain chain,
    required EthereumAddress tokenIn,
    required EthereumAddress tokenOut,
    required BigInt amountOut,
    required Token bridgeToken,
    required Token requestedToken,
    required SwapInDexBuffer buffer,
    required _SwapInDexQuotePhase phase,
  }) async {
    // Quote: how much bridge token (tBTC) is needed to receive exactly
    // [amountOut] of the requested token (USDT)?
    final quote = await _fetchDexQuoteOut(
      chain: chain,
      tokenIn: tokenIn,
      tokenOut: tokenOut,
      amountOut: amountOut,
    );

    // Round the bridge-token amountIn UP to sat granularity, then apply the
    // optional input buffer. The DEX output minimum stays exact; the buffer
    // only gives the route a little more bridge-token input to work with.
    //
    // Boltz delivers an integer number of sats on-chain.  inSats() truncates
    // sub-sat wei (e.g. 860,006,500,000,000 -> 86,000 sats =
    // 860,000,000,000,000 wei). Without this rounding, the DEX transfer would
    // request more than the claim provides.
    final roundedAmountIn = TokenAmount(
      value: quote.amountIn,
      token: bridgeToken,
    ).roundUpToSats();
    final bufferedAmountIn = tokenAmountFromSats(
      bridgeToken,
      buffer.applyToSats(roundedAmountIn.getInSats),
    ).value;
    final baseSats = roundedAmountIn.getInSats;
    final bufferedSats = TokenAmount(
      value: bufferedAmountIn,
      token: bridgeToken,
    ).getInSats;
    final bufferSats = bufferedSats - baseSats;
    final bufferPct = (buffer.basisPoints / 100).toStringAsFixed(2);
    logger.i(
      'Swap-in DEX input buffer (${phase.logName}): '
      'base=$baseSats sats, '
      'buffered=$bufferedSats sats, '
      'buffer=$bufferSats sats, '
      'bufferBps=${buffer.basisPoints}, '
      'bufferPct=$bufferPct%, '
      'minBuffer=${buffer.minSats} sats, '
      'amountIn=$bufferedAmountIn ${bridgeToken.tagId}, '
      'amountOutMin=${quote.amountOut} ${requestedToken.tagId}',
    );

    return DexQuote(
      amountIn: bufferedAmountIn,
      amountOut: quote.amountOut,
      data: quote.data,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  Swap-Out (Submarine Swap: on-chain → Lightning)
  // ═══════════════════════════════════════════════════════════════════════

  /// Build a [SwapQuote] for a swap-out (submarine swap).
  ///
  /// [chain]  — EVM chain to fetch balance and estimate gas on.
  /// [params] — swap-out parameters (keys, optional requested amount).
  ///
  /// When [params.amount] refers to a non-Boltz token (e.g. USDT) this method
  /// injects a requested-token → bridge DEX step into [params.preLockCalls]
  /// and uses the bridge-token output for all Boltz-side calculations.
  /// The returned [SwapQuote.sendAmount] always reflects the original user
  /// token/amount (USDT).
  ///
  /// Throws [StateError] when balance is insufficient or the requested amount
  /// falls outside Boltz limits.
  Future<SwapQuote> buildSwapOutQuote({
    required EvmChain chain,
    required SwapOutParams params,
  }) async {
    final requestedTokenAddress =
        params.amountSpec?.amount.token.isERC20 == true
        ? EthereumAddress.fromHex(params.amountSpec!.amount.token.address)
        : null;

    // ── DEX hop detection ──────────────────────────────────────────────────
    // When the user holds a non-bridge token (e.g. USDT), inject a
    // requested-token → bridge DEX step into preLockCalls so that:
    //   requestedToken → (DEX) → bridgeToken → (Boltz submarine swap) → LN
    // all execute atomically in one UserOperation.
    //
    // NOTE: We compare against the bridge token directly rather than using
    // supportsTokenAddress(), because Boltz may list extra ERC-20s (e.g. USDT)
    // in /chain/contracts without having a USDT↔BTC submarine pair.
    final needsDex =
        requestedTokenAddress != null &&
        !_isBridgeToken(chain, requestedTokenAddress);

    DexQuote? dexQuote;
    EthereumAddress? boltzTokenAddress = requestedTokenAddress;

    // Fetch the user's balance (USDT for DEX case, or bridge token otherwise).
    final TokenAmount userBalance;
    if (needsDex) {
      userBalance =
          params.amountSpec?.amount ??
          await _getSwapBalance(chain, params, requestedTokenAddress);

      final bridgeAddress = _findBridgeTokenAddress(chain);
      boltzTokenAddress = bridgeAddress;

      // Quote: how much bridge token (tBTC) comes out from the USDT input?
      dexQuote = await _fetchDexQuoteIn(
        chain: chain,
        tokenIn: requestedTokenAddress,
        tokenOut: bridgeAddress,
        amountIn: userBalance.value,
      );

      // Encode DEX calls and append after any existing preLockCalls (e.g.
      // an escrow withdraw) so execution order is:
      //   [withdraw?] → [DEX: requestedToken→bridge] → [lock bridge]
      final recipient = await chain.getAccountAddress(params.evmKey);
      final dexCalls = await _encodeDexCalls(
        chain: chain,
        dexQuote: dexQuote,
        recipient: recipient,
      );
      params.preLockCalls = {...?params.preLockCalls, ...dexCalls};
      // Record the bridge token address on params so that the swap-out
      // operation uses tBTC (not USDT) for all Boltz API calls.
      params.boltzTokenAddress = bridgeAddress;
    } else {
      userBalance =
          params.amountSpec?.amount ??
          await _getSwapBalance(chain, params, boltzTokenAddress);
    }

    final gasEstimate = await _estimateLockGasFee(
      chain,
      params,
      boltzTokenAddress,
    );
    final gasFee = gasEstimate.gasSponsored
        ? rbtcFromWei(BigInt.zero, chainId: chain.config.chainId)
        : rbtcFromWei(gasEstimate.gasCostWei, chainId: chain.config.chainId);

    // For Boltz pair + limit calculations use the bridge token amount.
    // DEX case: use dexQuote.amountOut (tBTC from the DEX swap).
    // Direct case: use the user's token balance as-is.
    final Token boltzToken;
    final BigInt boltzAmountValue;
    if (needsDex) {
      boltzToken = await chain.resolveToken(boltzTokenAddress!.eip55With0x);
      boltzAmountValue = dexQuote!.amountOut;
    } else {
      boltzToken = userBalance.token;
      boltzAmountValue = userBalance.value;
    }
    final boltzBalance = TokenAmount(
      value: boltzAmountValue,
      token: boltzToken,
    );
    final balanceRounded = TokenAmountEvmExt(boltzBalance).roundDownToSats();
    final gasFeeRounded = TokenAmountEvmExt(gasFee).roundUpToSats();

    final pair = await chain.swaps!.getSubmarinePair(
      tokenAddress: boltzTokenAddress,
    );

    final minInvoice = tokenAmountFromSats(
      boltzToken,
      BigInt.from(pair.limits.minimal.ceil()),
    );
    final maxInvoiceByPair = tokenAmountFromSats(
      boltzToken,
      BigInt.from(pair.limits.maximal.floor()),
    );

    final percentage = pair.fees.percentage;
    final minerFeesSatsRoundedUp = pair.fees.minerFees.ceil();
    final spendableAfterGasSats =
        balanceRounded.getInSats.toDouble() -
        gasFeeRounded.getInSats.toDouble();

    if (spendableAfterGasSats <= 0) {
      throw StateError(
        'Balance ${TokenAmountEvmExt(boltzBalance).getInSats} sats is not enough '
        'to cover estimated gas ${TokenAmountEvmExt(gasFee).getInSats} sats.',
      );
    }

    final denom = 1 + (percentage / 100.0);
    final maxInvoiceByBalanceSats =
        ((spendableAfterGasSats - minerFeesSatsRoundedUp) / denom).floor();

    if (maxInvoiceByBalanceSats <= 0) {
      throw StateError(
        'Balance after gas cannot cover submarine swap fees. '
        'Spendable: ${spendableAfterGasSats.floor()} sats, '
        'fixed miner fee: $minerFeesSatsRoundedUp sats.',
      );
    }

    final maxInvoiceByBalance = tokenAmountFromSats(
      boltzToken,
      BigInt.from(maxInvoiceByBalanceSats),
    );
    final maxInvoice = TokenAmount.max(
      TokenAmount.zero(boltzToken),
      maxInvoiceByBalance < maxInvoiceByPair
          ? maxInvoiceByBalance
          : maxInvoiceByPair,
    );

    final invoiceAmount = TokenAmountEvmExt(maxInvoice).roundDownToSats();

    if (invoiceAmount < minInvoice) {
      throw StateError(
        'Invoice amount ${TokenAmountEvmExt(invoiceAmount).getInSats} sats is '
        'below Boltz minimum ${TokenAmountEvmExt(minInvoice).getInSats} sats.',
      );
    }

    final estimatedGasFee = gasFeeRounded.toDenominated().rescale(8);

    final boltzEstimate = BoltzFeeEstimate.submarineFromReceive(
      pair,
      TokenAmountEvmExt(invoiceAmount).getInSats.toInt(),
    );

    // sendAmount = what the user actually puts in:
    //   - DEX case:    the original user token (USDT) balance
    //   - Direct case: the bridge/native token balance rounded to sats
    final sendAmount = needsDex ? userBalance : balanceRounded;

    return SwapQuote(
      boltzEstimate: boltzEstimate,
      gasFee: TokenAmount.fromDenominated(
        estimatedGasFee,
        Token.native(boltzToken.chainId),
      ),
      gasSponsored: gasEstimate.gasSponsored,
      sendAmount: sendAmount,
      receiveAmount: invoiceAmount,
      dexQuote: dexQuote,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  Swap-In helpers (state overrides for gas estimation)
  // ═══════════════════════════════════════════════════════════════════════

  Future<List<permissionless.StateOverride>?>
  _buildClaimEstimationStateOverrides({
    required EvmChain chain,
    required SwapInParams params,
    required Uint8List preimage,
  }) async {
    final claimAddress =
        params.claimAddress ?? await chain.getAccountAddress(params.evmKey);
    final tokenAddress = params.amount.token.isERC20
        ? EthereumAddress.fromHex(params.amount.token.address)
        : null;
    final swapContractAddress = tokenAddress != null
        ? chain.swaps!.getERC20SwapContract().self.address
        : chain.swaps!.getEtherSwapContract().self.address;

    final swapHash = _computeClaimSwapHash(
      preimage: preimage,
      amount: params.amount.value,
      claimAddress: claimAddress,
      refundAddress: params.evmKey.address,
      timelock: BigInt.zero,
      tokenAddress: tokenAddress,
    );
    final lockupSlot = _computeMappingSlot(
      permissionless.Hex.fromBytes(swapHash),
      BigInt.zero,
    );

    final lockupOverride = permissionless.StateOverride(
      address: swapContractAddress,
      stateDiff: [
        permissionless.StateDiff(
          slot: lockupSlot,
          value: permissionless.Hex.fromBigInt(BigInt.one, byteLength: 32),
        ),
      ],
    );

    final lockedFundsOverride = tokenAddress != null
        ? _buildErc20SwapBalanceOverride(
            chain,
            tokenAddress,
            swapContractAddress,
            params,
          )
        : [
            permissionless.StateOverride(
              address: swapContractAddress,
              balance: params.amount.value,
            ),
          ];

    return permissionless.mergeStateOverrides([
      ...?params.postClaimStateOverrides,
      lockupOverride,
      ...lockedFundsOverride,
    ]);
  }

  List<permissionless.StateOverride> _buildErc20SwapBalanceOverride(
    EvmChain chain,
    EthereumAddress tokenAddress,
    EthereumAddress swapContractAddress,
    SwapInParams params,
  ) {
    final tokenConfig = chain.config.tokenByAddress(
      params.amount.token.address,
    );
    final balanceSlot = BigInt.from(tokenConfig?.balanceStorageSlot ?? 0);
    return permissionless.erc20BalanceOverride(
      token: tokenAddress,
      owner: swapContractAddress,
      slot: balanceSlot,
      balance: params.amount.value,
    );
  }

  Uint8List _computeClaimSwapHash({
    required Uint8List preimage,
    required BigInt amount,
    required EthereumAddress claimAddress,
    required EthereumAddress refundAddress,
    required BigInt timelock,
    EthereumAddress? tokenAddress,
  }) {
    final preimageHash = sha256.convert(preimage).bytes;
    final encoded = permissionless.Hex.concat([
      permissionless.Hex.fromBytes(Uint8List.fromList(preimageHash)),
      permissionless.AbiEncoder.encodeUint256(amount),
      if (tokenAddress != null)
        permissionless.AbiEncoder.encodeAddress(tokenAddress),
      permissionless.AbiEncoder.encodeAddress(claimAddress),
      permissionless.AbiEncoder.encodeAddress(refundAddress),
      permissionless.AbiEncoder.encodeUint256(timelock),
    ]);
    return keccak256(permissionless.Hex.decode(encoded));
  }

  String _computeMappingSlot(String key, BigInt slot) {
    final encoded = permissionless.Hex.concat([
      key,
      permissionless.AbiEncoder.encodeUint256(slot),
    ]);
    return permissionless.Hex.fromBytes(
      keccak256(permissionless.Hex.decode(encoded)),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  Swap-Out helpers (balance + gas estimation)
  // ═══════════════════════════════════════════════════════════════════════

  Future<TokenAmount> _getSwapBalance(
    EvmChain chain,
    SwapOutParams params,
    EthereumAddress? tokenAddress,
  ) async {
    if (tokenAddress == null) {
      return chain.getBalance(params.evmKey.address);
    }
    final token = IERC20(address: tokenAddress, client: chain.client);
    final raw = await token.balanceOf((account: params.evmKey.address));
    final decimals = await chain.resolveTokenDecimals(tokenAddress.eip55With0x);
    return tokenAmountFromEvm(
      tokenAddress.eip55With0x,
      raw,
      chainId: chain.config.chainId,
      tokenDecimals: decimals,
    );
  }

  Future<({BigInt gasCostWei, bool gasSponsored})> _estimateLockGasFee(
    EvmChain chain,
    SwapOutParams params,
    EthereumAddress? tokenAddress,
  ) {
    return chain.estimateGas(
      params.evmKey,
      calls: _buildEstimationLockCalls(chain, params, tokenAddress),
    );
  }

  Map<String, Call> _buildEstimationLockCalls(
    EvmChain chain,
    SwapOutParams params,
    EthereumAddress? tokenAddress,
  ) {
    final builder = BoltzCallBuilder(chain.swaps!);
    final dummyHash = Uint8List(32);
    final dummyAddress = params.evmKey.address;
    final Map<String, Call> lockCalls;
    if (tokenAddress != null) {
      lockCalls = builder.erc20Lock(
        preimageHash: dummyHash,
        amountWei: BigInt.one,
        tokenAddress: tokenAddress,
        claimAddress: dummyAddress,
        timeoutBlockHeight: 1,
      );
    } else {
      lockCalls = {
        'EtherSwap.lock': builder.nativeLock(
          preimageHash: dummyHash,
          amountWei: BigInt.one,
          claimAddress: dummyAddress,
          timeoutBlockHeight: 1,
        ),
      };
    }
    return {...?params.preLockCalls, ...lockCalls};
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  DEX helpers (bridge-token lookup + Boltz Quote API)
  // ═══════════════════════════════════════════════════════════════════════

  /// Whether [tokenAddress] is the Boltz bridge token on [chain] (e.g. tBTC
  /// on Arbitrum — the first entry in [BoltzChainInfo.tokens]).
  ///
  /// This is the correct check for DEX-hop detection: Boltz may list other
  /// ERC-20s (e.g. USDT) in `/chain/contracts` without having BTC swap pairs
  /// for them. Only the bridge token has native BTC reverse/submarine pairs.
  bool _isBridgeToken(EvmChain chain, EthereumAddress tokenAddress) {
    final tokens = chain.swaps?.chainInfo.tokens;
    if (tokens == null || tokens.isEmpty) return false;
    return tokens.values.first.eip55With0x.toLowerCase() ==
        tokenAddress.eip55With0x.toLowerCase();
  }

  /// Returns the bridge token address — the first Boltz-discovered ERC-20 on
  /// [chain] (e.g. tBTC on Arbitrum). Throws if the chain has no ERC-20
  /// tokens configured in Boltz.
  EthereumAddress _findBridgeTokenAddress(EvmChain chain) {
    final tokens = chain.swaps!.chainInfo.tokens;
    if (tokens.isEmpty) {
      throw StateError(
        'No Boltz ERC-20 tokens on chain ${chain.config.id}. '
        'Cannot determine bridge token for DEX hop.',
      );
    }
    return tokens.values.first;
  }

  /// GET /quote/{nativeCurrency}/in — fixed [amountIn] of [tokenIn] → [tokenOut].
  ///
  /// The `{currency}` path segment is the chain's native-token symbol as known
  /// to the Boltz sidecar (e.g. `ARB` for the arbitrum regtest chain).
  /// This is sourced from [BoltzSwapProvider.nativeCurrency] which maps to
  /// [EvmChainConfig.boltzCurrency] — NOT the chain name from /chain/contracts.
  ///
  /// Returns a [DexQuote] whose [DexQuote.data] is the opaque payload that
  /// must be forwarded verbatim to [_encodeDexCalls].
  Future<DexQuote> _fetchDexQuoteIn({
    required EvmChain chain,
    required EthereumAddress tokenIn,
    required EthereumAddress tokenOut,
    required BigInt amountIn,
  }) async {
    final currency =
        chain.swaps!.nativeCurrency ?? chain.swaps!.chainInfo.chainKey;
    final res = await chain.swaps!.boltzClient.gBoltzCli.quoteCurrencyInGet(
      currency: currency,
      tokenIn: tokenIn.eip55With0x,
      tokenOut: tokenOut.eip55With0x,
      amountIn: amountIn.toString(),
    );
    if (!res.isSuccessful || res.body == null || res.body!.isEmpty) {
      throw StateError(
        'Boltz quote /in failed (HTTP ${res.statusCode}) '
        'for ${tokenIn.eip55With0x} → ${tokenOut.eip55With0x}.',
      );
    }
    final q = res.body!.first;
    return DexQuote(
      amountIn: amountIn,
      amountOut: BigInt.parse(q.quote),
      data: q.data,
    );
  }

  /// GET /quote/{nativeCurrency}/out — fixed [amountOut] of [tokenOut] from [tokenIn].
  ///
  /// Returns a [DexQuote] whose [DexQuote.data] is the opaque payload that
  /// must be forwarded verbatim to [_encodeDexCalls].
  Future<DexQuote> _fetchDexQuoteOut({
    required EvmChain chain,
    required EthereumAddress tokenIn,
    required EthereumAddress tokenOut,
    required BigInt amountOut,
  }) async {
    final currency =
        chain.swaps!.nativeCurrency ?? chain.swaps!.chainInfo.chainKey;
    final res = await chain.swaps!.boltzClient.gBoltzCli.quoteCurrencyOutGet(
      currency: currency,
      tokenIn: tokenIn.eip55With0x,
      tokenOut: tokenOut.eip55With0x,
      amountOut: amountOut.toString(),
    );
    if (!res.isSuccessful || res.body == null || res.body!.isEmpty) {
      throw StateError(
        'Boltz quote /out failed (HTTP ${res.statusCode}) '
        'for ${tokenIn.eip55With0x} → ${tokenOut.eip55With0x}.',
      );
    }
    final q = res.body!.first;
    return DexQuote(
      amountIn: BigInt.parse(q.quote),
      amountOut: amountOut,
      data: q.data,
    );
  }

  /// POST /quote/{nativeCurrency}/encode — converts a [DexQuote] into a set of EVM
  /// [Call]s suitable for injection into [SwapInParams.postClaimCalls] or
  /// [SwapOutParams.preLockCalls].
  ///
  /// Uses [DexQuote.amountOut] as `amountOutMin`: the DEX must deliver at
  /// least the requested output. Swap-in callers can buffer [DexQuote.amountIn]
  /// separately before this method encodes the route.
  Future<Map<String, Call>> _encodeDexCalls({
    required EvmChain chain,
    required DexQuote dexQuote,
    required EthereumAddress recipient,
  }) async {
    final amountOutMin = dexQuote.amountOut;
    final currency =
        chain.swaps!.nativeCurrency ?? chain.swaps!.chainInfo.chainKey;
    final res = await chain.swaps!.boltzClient.gBoltzCli
        .quoteCurrencyEncodePost(
          currency: currency,
          body: QuoteCurrencyEncodePost$RequestBody(
            recipient: recipient.eip55With0x,
            amountIn: dexQuote.amountIn.toString(),
            amountOutMin: amountOutMin.toString(),
            data: dexQuote.data,
          ),
        );
    if (!res.isSuccessful || res.body == null) {
      throw StateError('Boltz quote /encode failed (HTTP ${res.statusCode}).');
    }
    final swaggerCalls = res.body!.calls;
    return {
      for (final (i, c) in swaggerCalls.indexed)
        'dex[$i]': Call(
          to: EthereumAddress.fromHex(c.to),
          value: BigInt.tryParse(c.value) ?? BigInt.zero,
          data: c.data.startsWith('0x') ? c.data : '0x${c.data}',
        ),
    };
  }
}
