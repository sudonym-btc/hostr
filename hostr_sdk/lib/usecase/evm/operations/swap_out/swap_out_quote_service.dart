import 'dart:typed_data';

import 'package:hostr_sdk/usecase/evm/evm_call.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;

import '../../../../datasources/contracts/boltz/IERC20.g.dart';
import '../../../../util/token_amount_ext.dart';
import '../../capabilities/boltz_call_builder.dart';
import '../../chain/evm_chain.dart';
import '../../models/fee_breakdown.dart';
import 'swap_out_models.dart';

/// Immutable quote describing a swap-out (RBTC → BTC).
class SwapOutQuote {
  final TokenAmount balance;
  final TokenAmount invoiceAmount;
  final DenominatedAmount estimatedGasFee;
  final DenominatedAmount estimatedSwapFee;

  /// Whether the gas fee is covered by a paymaster.
  final bool gasSponsored;

  const SwapOutQuote({
    required this.balance,
    required this.invoiceAmount,
    required this.estimatedGasFee,
    required this.estimatedSwapFee,
    required this.gasSponsored,
  });

  /// Unified fee breakdown for UI display.
  FeeBreakdown get feeBreakdown => FeeBreakdown(
    escrowFee: TokenAmount.zero(balance.token),
    swapFee: TokenAmount.fromDenominated(estimatedSwapFee, Token.btcLightning),
    gasFee: TokenAmount.fromDenominated(
      estimatedGasFee,
      Token.native(balance.token.chainId),
    ),
    gasSponsored: gasSponsored,
  );
}

/// Encapsulates the Boltz pair-fee maths for submarine (swap-out) quoting.
///
/// Owns gas estimation and balance fetch. Accepts the same [EvmChain] +
/// [SwapOutParams] that the swap operation uses, so callers get fee quotes
/// without executing the swap.
@injectable
class SwapOutQuoteService {
  TokenAmount _amountFromSats(Token token, int sats) {
    return TokenAmount.fromDenominated(
      DenominatedAmount(
        denomination: 'BTC',
        value: BigInt.from(sats),
        decimals: 8,
      ),
      token,
    );
  }

  /// Build a [SwapOutQuote] for the given chain and swap params.
  ///
  /// [chain]  — EVM chain to fetch balance and estimate gas on.
  /// [params] — swap-out parameters (keys, optional requested amount).
  ///
  /// Throws [StateError] when balance is insufficient or the requested amount
  /// falls outside Boltz limits.
  Future<SwapOutQuote> buildQuote({
    required EvmChain chain,
    required SwapOutParams params,
  }) async {
    final tokenAddress = params.amount?.token.isERC20 == true
        ? EthereumAddress.fromHex(params.amount!.token.address)
        : null;

    final balance = await _getSwapBalance(chain, params, tokenAddress);
    final gasEstimate = await _estimateLockGasFee(chain, params, tokenAddress);
    final gasFee = rbtcFromWei(gasEstimate.gasCostWei);

    final balanceRounded = TokenAmountEvmExt(balance).roundDownToSats();
    final gasFeeRounded = TokenAmountEvmExt(gasFee).roundUpToSats();

    final pair = await chain.swaps!.getSubmarinePair(
      tokenAddress: tokenAddress,
    );

    final minInvoice = _amountFromSats(
      balance.token,
      pair.limits.minimal.ceil(),
    );
    final maxInvoiceByPair = _amountFromSats(
      balance.token,
      pair.limits.maximal.floor(),
    );

    final percentage = pair.fees.percentage;
    final minerFeesSatsRoundedUp = pair.fees.minerFees.ceil();
    final spendableAfterGasSats =
        balanceRounded.getInSats.toDouble() -
        gasFeeRounded.getInSats.toDouble();

    if (spendableAfterGasSats <= 0) {
      throw StateError(
        'Balance ${TokenAmountEvmExt(balance).getInSats} sats is not enough to cover estimated gas '
        '${TokenAmountEvmExt(gasFee).getInSats} sats.',
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

    final maxInvoiceByBalance = _amountFromSats(
      balance.token,
      maxInvoiceByBalanceSats,
    );
    final maxInvoice = TokenAmount.max(
      TokenAmount.zero(balance.token),
      maxInvoiceByBalance < maxInvoiceByPair
          ? maxInvoiceByBalance
          : maxInvoiceByPair,
    );

    final invoiceAmount = TokenAmountEvmExt(
      params.amount ?? maxInvoice,
    ).roundDownToSats();

    if (invoiceAmount < minInvoice) {
      throw StateError(
        'Invoice amount ${TokenAmountEvmExt(invoiceAmount).getInSats} sats is below Boltz minimum '
        '${TokenAmountEvmExt(minInvoice).getInSats} sats.',
      );
    }
    if (invoiceAmount > maxInvoiceByPair) {
      throw StateError(
        'Invoice amount ${TokenAmountEvmExt(invoiceAmount).getInSats} sats exceeds Boltz maximum '
        '${TokenAmountEvmExt(maxInvoiceByPair).getInSats} sats.',
      );
    }
    if (invoiceAmount > maxInvoiceByBalance) {
      throw StateError(
        'Invoice amount ${TokenAmountEvmExt(invoiceAmount).getInSats} sats exceeds affordable maximum '
        '${TokenAmountEvmExt(maxInvoiceByBalance).getInSats} sats after gas+swap fees.',
      );
    }

    final estimatedSwapFeeSats =
        TokenAmountEvmExt(invoiceAmount).getInSats.toDouble() *
            (percentage / 100.0) +
        minerFeesSatsRoundedUp;

    // Express all fees in BTC sats (8 decimals) so totalFees can add them
    // regardless of whether the swapped asset is native (RBTC) or an ERC-20
    // token. Gas fees originate as RBTC wei (18 decimals) → rescale to sats.
    return SwapOutQuote(
      balance: balanceRounded,
      invoiceAmount: invoiceAmount,
      estimatedGasFee: gasFeeRounded.toDenominated().rescale(8),
      estimatedSwapFee: DenominatedAmount(
        denomination: 'BTC',
        value: BigInt.from(estimatedSwapFeeSats.ceil()),
        decimals: 8,
      ),
      gasSponsored: gasEstimate.gasSponsored,
    );
  }

  // ── Helpers (moved from EvmSwapOutOperation) ─────────────────────

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

  /// Build representative lock calls for gas estimation.
  ///
  /// Values are dummies — only the ABI signature and target contract
  /// matter for gas estimation.
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
}
