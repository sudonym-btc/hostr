import 'package:models/main.dart';

import '../swagger_generated/boltz.swagger.dart';

/// Fee estimate for a Boltz swap, computed from pair data.
///
/// Works for both reverse (swap-in) and submarine (swap-out) swaps.
/// All amounts in BTC sats (8 decimals).
class BoltzFeeEstimate {
  /// Boltz percentage fee rate (e.g. 0.25 means 0.25%).
  final double percentageRate;

  /// Fixed miner fee component in sats.
  final int minerFeeSat;

  /// Computed total fee in sats for the given amount.
  final int totalFeeSat;

  /// Minimum swap amount in sats (from Boltz pair limits).
  final int minSat;

  /// Maximum swap amount in sats (from Boltz pair limits).
  final int maxSat;

  const BoltzFeeEstimate({
    required this.percentageRate,
    required this.minerFeeSat,
    required this.totalFeeSat,
    required this.minSat,
    required this.maxSat,
  });

  /// Compute fees for a **reverse swap** (swap-in: Lightning → on-chain).
  ///
  /// Given a desired [onchainSat] amount, computes how much the Lightning
  /// invoice will exceed the on-chain amount.
  ///
  /// Boltz formula:
  ///   `invoice = (onchain + lockupFee) / (1 − pct/100)`
  ///   `fee = invoice − onchain`
  factory BoltzFeeEstimate.reverseSwap(ReversePair pair, int onchainSat) {
    final pct = pair.fees.percentage;
    final lockupFee = pair.fees.minerFees.lockup.ceil();
    final invoiceSat = ((onchainSat + lockupFee) / (1.0 - pct / 100.0)).ceil();
    return BoltzFeeEstimate(
      percentageRate: pct,
      minerFeeSat: lockupFee,
      totalFeeSat: invoiceSat - onchainSat,
      minSat: pair.limits.minimal.ceil(),
      maxSat: pair.limits.maximal.floor(),
    );
  }

  /// Compute fees for a **submarine swap** (swap-out: on-chain → Lightning).
  ///
  /// Given a desired [invoiceSat] (Lightning receive amount), computes the
  /// fee that Boltz deducts from the on-chain lock.
  ///
  /// Boltz formula:
  ///   `fee = invoice × pct/100 + minerFees`
  ///   `lockAmount = invoice + fee`
  factory BoltzFeeEstimate.submarineSwap(SubmarinePair pair, int invoiceSat) {
    final pct = pair.fees.percentage;
    final minerFee = pair.fees.minerFees.ceil();
    final fee = (invoiceSat * pct / 100.0).ceil() + minerFee;
    return BoltzFeeEstimate(
      percentageRate: pct,
      minerFeeSat: minerFee,
      totalFeeSat: fee,
      minSat: pair.limits.minimal.ceil(),
      maxSat: pair.limits.maximal.floor(),
    );
  }

  /// Total fee as a [DenominatedAmount] in BTC sats.
  DenominatedAmount get feesAsDenominated => DenominatedAmount(
    denomination: 'BTC',
    value: BigInt.from(totalFeeSat),
    decimals: 8,
  );

  /// Minimum swap amount as a [DenominatedAmount] in BTC sats.
  DenominatedAmount get limitsMin => DenominatedAmount(
    denomination: 'BTC',
    value: BigInt.from(minSat),
    decimals: 8,
  );

  /// Maximum swap amount as a [DenominatedAmount] in BTC sats.
  DenominatedAmount get limitsMax => DenominatedAmount(
    denomination: 'BTC',
    value: BigInt.from(maxSat),
    decimals: 8,
  );

  @override
  String toString() =>
      'BoltzFeeEstimate(pct=$percentageRate%, miner=$minerFeeSat, '
      'total=$totalFeeSat, limits=$minSat–$maxSat)';
}
