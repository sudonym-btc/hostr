import 'package:models/main.dart';

import 'fee_breakdown.dart';
import 'swap_quote.dart';

/// Application-layer wrapper that pairs a pure [SwapQuote] with the escrow
/// operator's service fee.
///
/// [SwapQuote] models Boltz swap economics only (send/receive amounts, swap
/// fee, gas). The escrow fee is an application concern — it belongs here,
/// not on the swap quote itself.
class EscrowFundQuote {
  /// The underlying Boltz swap quote.
  final SwapQuote swapQuote;

  /// Escrow operator's service fee (in the escrow/trade token).
  final TokenAmount escrowFee;

  const EscrowFundQuote({required this.swapQuote, required this.escrowFee});

  /// Combined fee breakdown for UI display — includes escrow fee on top of
  /// the swap quote's network fees.
  FeeBreakdown get feeBreakdown => FeeBreakdown(
    escrowFee: escrowFee,
    swapFee: swapQuote.swapFee,
    gasFee: swapQuote.gasFee,
    gasSponsored: swapQuote.gasSponsored,
  );
}
