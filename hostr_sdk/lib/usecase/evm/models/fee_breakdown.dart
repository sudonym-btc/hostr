import 'package:models/main.dart';

/// Unified fee breakdown returned by every operation's `estimateFees()`.
///
/// Contains all fee line-items for a single operation. Each component is a
/// [TokenAmount] denominated in the fee's native token so the UI can format
/// each line in the correct unit without manual rescaling.
///
/// For composite operations (e.g. escrow fund = swap-in + on-chain tx),
/// the breakdown captures the full cost across all sub-operations.
class FeeBreakdown {
  /// Escrow operator's service fee (in the trade token's units).
  /// Zero for non-escrow operations (swap-in, swap-out).
  final TokenAmount escrowFee;

  /// Boltz swap overhead (always in BTC sats / 8 decimals).
  /// Zero when no swap is involved.
  final TokenAmount swapFee;

  /// EVM gas cost (in the chain's native token, e.g. RBTC).
  /// This is the **real** gas cost even when sponsored.
  final TokenAmount gasFee;

  /// Whether the gas fee is currently sponsored by a paymaster.
  /// When `true`, the user does not actually pay [gasFee], but it is still
  /// shown for transparency.
  final bool gasSponsored;

  const FeeBreakdown({
    required this.escrowFee,
    required this.swapFee,
    required this.gasFee,
    this.gasSponsored = false,
  });

  /// Total fees in BTC sats (8 decimals) for display purposes.
  ///
  /// Rescales each component to 8-decimal BTC before summing.
  /// The [escrowFee] is excluded from this total because it may be in a
  /// different denomination (e.g. USDT) and is shown separately.
  DenominatedAmount get networkFees {
    final gasDA = gasFee.toDenominated();
    final gasNormalized = gasDA.decimals != 8 ? gasDA.rescale(8) : gasDA;
    final swapDA = swapFee.toDenominated();
    final swapNormalized = swapDA.decimals != 8 ? swapDA.rescale(8) : swapDA;
    return gasNormalized + swapNormalized;
  }

  @override
  String toString() =>
      'FeeBreakdown(escrow=${escrowFee.toDecimalString()}, '
      'swap=${swapFee.toDecimalString()}, '
      'gas=${gasFee.toDecimalString()}, sponsored=$gasSponsored)';
}
