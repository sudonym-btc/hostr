import 'dart:math' as math;

import 'package:models/main.dart';

import '../swagger_generated/boltz.swagger.dart';

/// Fee estimate for a Boltz swap, computed locally from pair rate data.
///
/// Aligned with the [Boltz web-app fee formulas](https://github.com/BoltzExchange/boltz-web-app/blob/main/src/utils/calculate.ts):
///
/// | Direction   | Given side | Formula                                               |
/// |-------------|------------|-------------------------------------------------------|
/// | **Reverse** | receive    | `send = ceil((receive + minerFee) / (1 − pct/100))`  |
/// | **Reverse** | send       | `receive = send − ceil(send × pct/100) − minerFee`   |
/// | **Submarine** | receive  | `send = floor(receive + ceil(receive × pct/100) + minerFee)` |
/// | **Submarine** | send     | `receive = floor((send − minerFee) / (1 + pct/100))` |
///
/// Reverse minerFee = `lockup + claim` (matches web app).
/// Submarine minerFee = flat `pair.fees.minerFees`.
class BoltzFeeEstimate {
  /// Boltz percentage fee rate (e.g. 0.25 means 0.25 %).
  final double percentageRate;

  /// Combined fixed miner fee in sats (lockup + claim for reverse, flat for submarine).
  final int minerFeeSat;

  /// Locally-estimated amount the user **sends** (LN invoice for reverse,
  /// on-chain lock for submarine).
  final int sendSat;

  /// Locally-estimated amount the user **receives** (on-chain for reverse,
  /// LN invoice for submarine).
  final int receiveSat;

  /// Minimum swap amount in sats (from Boltz pair limits).
  final int minSat;

  /// Maximum swap amount in sats (from Boltz pair limits).
  final int maxSat;

  const BoltzFeeEstimate({
    required this.percentageRate,
    required this.minerFeeSat,
    required this.sendSat,
    required this.receiveSat,
    required this.minSat,
    required this.maxSat,
  });

  /// Total fee = send − receive.
  int get totalFeeSat => sendSat - receiveSat;

  // ═══════════════════════════════════════════════════════════════════════
  //  Reverse swap (swap-in: Lightning → on-chain)
  // ═══════════════════════════════════════════════════════════════════════

  /// Given a desired **on-chain receive** amount, compute the LN send amount.
  ///
  /// Matches web-app `calculateSendAmount(receive, pct, miner, Reverse)`:
  ///   `send = ceil((receive + minerFee) / (1 − pct/100))`
  factory BoltzFeeEstimate.reverseFromReceive(
    ReversePair pair,
    int onchainSat,
  ) {
    final pct = pair.fees.percentage;
    final minerFee =
        pair.fees.minerFees.lockup.ceil() + pair.fees.minerFees.claim.ceil();
    final invoiceSat = ((onchainSat + minerFee) / (1.0 - pct / 100.0)).ceil();
    return BoltzFeeEstimate(
      percentageRate: pct,
      minerFeeSat: minerFee,
      sendSat: invoiceSat,
      receiveSat: onchainSat,
      minSat: pair.limits.minimal.ceil(),
      maxSat: pair.limits.maximal.floor(),
    );
  }

  /// Given a desired **LN send** amount, compute the on-chain receive amount.
  ///
  /// Matches web-app `calculateReceiveAmount(send, pct, miner, Reverse)`:
  ///   `receive = send − ceil(send × pct/100) − minerFee`
  factory BoltzFeeEstimate.reverseFromSend(ReversePair pair, int invoiceSat) {
    final pct = pair.fees.percentage;
    final minerFee =
        pair.fees.minerFees.lockup.ceil() + pair.fees.minerFees.claim.ceil();
    final onchainSat =
        invoiceSat - (invoiceSat * pct / 100.0).ceil() - minerFee;
    return BoltzFeeEstimate(
      percentageRate: pct,
      minerFeeSat: minerFee,
      sendSat: invoiceSat,
      receiveSat: math.max(0, onchainSat),
      minSat: pair.limits.minimal.ceil(),
      maxSat: pair.limits.maximal.floor(),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  Submarine swap (swap-out: on-chain → Lightning)
  // ═══════════════════════════════════════════════════════════════════════

  /// Given a desired **LN receive** amount, compute the on-chain lock amount.
  ///
  /// Matches web-app `calculateSendAmount(receive, pct, miner, Submarine)`:
  ///   `send = floor(receive + ceil(receive × pct/100) + minerFee)`
  factory BoltzFeeEstimate.submarineFromReceive(
    SubmarinePair pair,
    int invoiceSat,
  ) {
    final pct = pair.fees.percentage;
    final minerFee = pair.fees.minerFees.ceil();
    final lockSat = (invoiceSat + (invoiceSat * pct / 100.0).ceil() + minerFee)
        .floor();
    return BoltzFeeEstimate(
      percentageRate: pct,
      minerFeeSat: minerFee,
      sendSat: lockSat,
      receiveSat: invoiceSat,
      minSat: pair.limits.minimal.ceil(),
      maxSat: pair.limits.maximal.floor(),
    );
  }

  /// Given an **on-chain lock** (send) amount, compute the LN receive amount.
  ///
  /// Matches web-app `calculateReceiveAmount(send, pct, miner, Submarine)`:
  ///   `receive = floor((send − minerFee) / (1 + pct/100))`
  factory BoltzFeeEstimate.submarineFromSend(SubmarinePair pair, int lockSat) {
    final pct = pair.fees.percentage;
    final minerFee = pair.fees.minerFees.ceil();
    final invoiceSat = ((lockSat - minerFee) / (1.0 + pct / 100.0)).floor();
    return BoltzFeeEstimate(
      percentageRate: pct,
      minerFeeSat: minerFee,
      sendSat: lockSat,
      receiveSat: math.max(0, invoiceSat),
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
      'send=$sendSat, receive=$receiveSat, fee=$totalFeeSat, '
      'limits=$minSat–$maxSat)';
}
