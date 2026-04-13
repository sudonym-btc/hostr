import 'package:models/main.dart';

import '../../../datasources/boltz/boltz_fee_estimate.dart';
import 'dex_quote.dart';
import 'fee_breakdown.dart';

/// Unified quote for both swap-in (Lightning → on-chain) and swap-out
/// (on-chain → Lightning).
///
/// Models pure Boltz swap economics: amounts, fees, gas, and an optional
/// DEX hop. Application-layer concerns (e.g. escrow fees) belong on a
/// wrapper such as `EscrowFundQuote`, not here.
///
/// Follows the Boltz web app pattern: one model for any direction, with
/// an optional [dexQuote] when a DEX hop is needed (e.g. tBTC ↔ USDT).
class SwapQuote {
  /// Boltz fee estimate (limits + per-swap fee), from one pair fetch.
  final BoltzFeeEstimate boltzEstimate;

  /// EVM gas cost in native token (e.g. RBTC), even when sponsored.
  final TokenAmount gasFee;

  /// Whether the gas fee is covered by a paymaster.
  final bool gasSponsored;

  /// What the user sends — the Lightning invoice amount (swap-in) or
  /// the on-chain lock amount (swap-out). Equivalent to the former
  /// `SwapInQuote.resolvedSwapAmount` / `SwapOutQuote.invoiceAmount`.
  final TokenAmount sendAmount;

  /// What the user receives — the on-chain token (swap-in) or Lightning
  /// sats (swap-out). For swap-out this is the max LN invoice amount.
  final TokenAmount receiveAmount;

  /// Optional DEX quote when the listing token differs from the Boltz
  /// funding token (e.g. escrow needs USDT but Boltz sends tBTC).
  ///
  /// `null` for same-token swaps. Zero slippage is enforced at execution
  /// time — the DEX must deliver the exact quoted amount.
  final DexQuote? dexQuote;

  const SwapQuote({
    required this.boltzEstimate,
    required this.gasFee,
    required this.gasSponsored,
    required this.sendAmount,
    required this.receiveAmount,
    this.dexQuote,
  });

  /// Boltz swap fee as a [DenominatedAmount] in BTC denomination.
  DenominatedAmount get swapFee => boltzEstimate.feesAsDenominated;

  /// Boltz swap limits as [TokenAmount] in the given token.
  ({TokenAmount min, TokenAmount max}) limitsIn(Token token) => (
    min: TokenAmount.fromDenominated(boltzEstimate.limitsMin, token),
    max: TokenAmount.fromDenominated(boltzEstimate.limitsMax, token),
  );

  /// Fee breakdown for UI display (swap + gas only, no escrow fee).
  FeeBreakdown get feeBreakdown => FeeBreakdown(
    swapFee: swapFee,
    gasFee: gasFee,
    gasSponsored: gasSponsored,
  );
}
