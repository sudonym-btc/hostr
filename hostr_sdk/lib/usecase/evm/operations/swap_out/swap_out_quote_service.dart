import 'package:hostr_sdk/injection.dart';
import 'package:injectable/injectable.dart';

import '../../../../datasources/boltz/boltz.dart';
import '../../../../util/bitcoin_amount.dart';

/// Immutable quote describing a swap-out (RBTC → BTC).
class SwapOutQuote {
  final BitcoinAmount balance;
  final BitcoinAmount invoiceAmount;
  final BitcoinAmount estimatedGasFee;
  final BitcoinAmount estimatedSwapFee;

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
  /// Build a [SwapOutQuote] for the given balance, gas estimate, and
  /// optional desired amount.
  ///
  /// Throws [StateError] when balance is insufficient or the requested amount
  /// falls outside Boltz limits.
  Future<SwapOutQuote> buildQuote({
    required BitcoinAmount balance,
    required BitcoinAmount estimatedGasFee,
    BitcoinAmount? requestedAmount,
  }) async {
    final balanceRounded = balance.roundDown(BitcoinUnit.sat);
    final gasFeeRounded = estimatedGasFee.roundUp(BitcoinUnit.sat);

    final pair = await getIt<BoltzClient>().getSubmarinePair(
      from: 'RBTC',
      to: 'BTC',
    );

    final minInvoice = BitcoinAmount.fromInt(
      BitcoinUnit.sat,
      pair.limits.minimal.ceil(),
    );
    final maxInvoiceByPair = BitcoinAmount.fromInt(
      BitcoinUnit.sat,
      pair.limits.maximal.floor(),
    );

    final percentage = pair.fees.percentage;
    final minerFeesSatsRoundedUp = pair.fees.minerFees.ceil();
    final spendableAfterGasSats =
        balanceRounded.getInSats.toDouble() -
        gasFeeRounded.getInSats.toDouble();

    if (spendableAfterGasSats <= 0) {
      throw StateError(
        'Balance ${balance.getInSats} sats is not enough to cover estimated gas '
        '${estimatedGasFee.getInSats} sats.',
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

    final maxInvoiceByBalance = BitcoinAmount.fromInt(
      BitcoinUnit.sat,
      maxInvoiceByBalanceSats,
    );
    final maxInvoice = BitcoinAmount.max(
      BitcoinAmount.zero(),
      maxInvoiceByBalance < maxInvoiceByPair
          ? maxInvoiceByBalance
          : maxInvoiceByPair,
    );

    final invoiceAmount = (requestedAmount ?? maxInvoice).roundDown(
      BitcoinUnit.sat,
    );

    if (invoiceAmount < minInvoice) {
      throw StateError(
        'Invoice amount ${invoiceAmount.getInSats} sats is below Boltz minimum '
        '${minInvoice.getInSats} sats.',
      );
    }
    if (invoiceAmount > maxInvoiceByPair) {
      throw StateError(
        'Invoice amount ${invoiceAmount.getInSats} sats exceeds Boltz maximum '
        '${maxInvoiceByPair.getInSats} sats.',
      );
    }
    if (invoiceAmount > maxInvoiceByBalance) {
      throw StateError(
        'Invoice amount ${invoiceAmount.getInSats} sats exceeds affordable maximum '
        '${maxInvoiceByBalance.getInSats} sats after gas+swap fees.',
      );
    }

    final estimatedSwapFeeSats =
        invoiceAmount.getInSats.toDouble() * (percentage / 100.0) +
        minerFeesSatsRoundedUp;
    final estimatedSwapFee = BitcoinAmount.fromInt(
      BitcoinUnit.sat,
      estimatedSwapFeeSats.ceil(),
    ).roundUp(BitcoinUnit.sat);

    return SwapOutQuote(
      balance: balanceRounded,
      invoiceAmount: invoiceAmount,
      estimatedGasFee: gasFeeRounded,
      estimatedSwapFee: estimatedSwapFee,
    );
  }
}
