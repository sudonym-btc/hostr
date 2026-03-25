import 'package:injectable/injectable.dart';
import 'package:models/main.dart';

import '../../../../datasources/boltz/boltz.dart';
import '../../../../injection.dart';
import '../../../../util/token_amount_ext.dart';

/// Immutable quote describing a swap-out (RBTC → BTC).
class SwapOutQuote {
  final TokenAmount balance;
  final TokenAmount invoiceAmount;
  final DenominatedAmount estimatedGasFee;
  final DenominatedAmount estimatedSwapFee;

  const SwapOutQuote({
    required this.balance,
    required this.invoiceAmount,
    required this.estimatedGasFee,
    required this.estimatedSwapFee,
  });
}

/// Encapsulates the Boltz pair-fee maths for submarine (swap-out) quoting.
///
/// Stateless — safe to share across operations. Depends only on [BoltzClient]
/// for pair info; callers supply the chain-specific balance and gas estimate.
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

  /// Build a [SwapOutQuote] for the given balance, gas estimate, and
  /// optional desired amount.
  ///
  /// [boltzCurrency] is the Boltz pair currency for the chain (e.g. 'RBTC',
  /// 'tBTC'). Defaults to 'RBTC' for backwards compatibility.
  ///
  /// Throws [StateError] when balance is insufficient or the requested amount
  /// falls outside Boltz limits.
  Future<SwapOutQuote> buildQuote({
    required TokenAmount balance,
    required TokenAmount estimatedGasFee,
    TokenAmount? requestedAmount,
    String boltzCurrency = 'RBTC',
  }) async {
    final balanceRounded = TokenAmountEvmExt(balance).roundDownToSats();
    final gasFeeRounded = TokenAmountEvmExt(estimatedGasFee).roundUpToSats();

    final pair = await getIt<BoltzClient>().getSubmarinePair(
      from: boltzCurrency,
      to: 'BTC',
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
        '${TokenAmountEvmExt(estimatedGasFee).getInSats} sats.',
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
      requestedAmount ?? maxInvoice,
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
    );
  }
}
