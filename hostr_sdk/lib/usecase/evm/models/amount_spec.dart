import 'package:models/main.dart';

/// Which side of the swap the user-specified amount refers to.
///
/// - [input]  — the user specifies how much they **send** (e.g. LN sats for
///   swap-in, or on-chain balance for swap-out). The other side is computed
///   from Boltz pair rates.
///
/// - [output] — the user specifies how much they want to **receive** (e.g.
///   on-chain tokens for swap-in / escrow-fund, or LN sats for swap-out).
///   The send side is computed.
enum AmountSide { input, output }

/// Pairs a [TokenAmount] with an [AmountSide] so that downstream services
/// (quote, swap creation) know which Boltz API parameter to use and which
/// fee formula direction to apply.
///
/// ```dart
/// // Escrow fund: "deliver exactly 100 USDT on-chain"
/// AmountSpec.output(fundingAmount)
///
/// // Swap-out send-all: "spend my entire on-chain balance"
/// AmountSpec.input(balance)
/// ```
class AmountSpec {
  final TokenAmount amount;
  final AmountSide side;

  const AmountSpec.input(this.amount) : side = AmountSide.input;
  const AmountSpec.output(this.amount) : side = AmountSide.output;

  @override
  String toString() => 'AmountSpec.${side.name}($amount)';
}
