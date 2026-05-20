import 'src/decimal_math.dart';

/// A monetary value expressed in a named denomination (e.g. "BTC", "USD"),
/// without any chain-specific binding.
///
/// Use this for listing prices, order negotiation amounts, and
/// any context where the *denomination* matters but not the concrete
/// on-chain token. Chain-specific [Token]/[TokenAmount] should only
/// appear at the on-chain execution boundary (funding, verification).
///
/// The [value] is always in the denomination's **smallest unit**:
/// - `"BTC"` → satoshis ([decimals] = 8)
/// - `"USD"` → micro-dollars ([decimals] = 6, if convention)
class DenominatedAmount {
  /// Well-known decimal precision for each denomination.
  ///
  /// BTC uses 8 decimals (satoshis), USD uses 6 (micro-dollars),
  /// ETH uses 18 (wei).  Add entries here as new denominations
  /// are supported.
  static const denominationDecimals = <String, int>{
    'BTC': 8,
    'USD': 6,
    'ETH': 18,
  };

  /// Returns the canonical decimal count for [denomination],
  /// defaulting to 8 for unknown denominations.
  static int decimalsFor(String denomination) =>
      denominationDecimals[denomination] ?? 8;

  /// Human-readable denomination identifier.
  ///
  /// By convention this matches the EscrowMethod "a"-tag denomination
  /// field (e.g. `"BTC"`, `"USD"`).
  final String denomination;

  /// Raw integer value in the denomination's smallest unit.
  final BigInt value;

  /// Number of decimal places for the denomination's smallest unit.
  /// e.g. 8 for BTC (satoshis), 6 for a six-decimal stablecoin.
  final int decimals;

  const DenominatedAmount({
    required this.denomination,
    required this.value,
    required this.decimals,
  });

  /// A zero amount for the given denomination.
  factory DenominatedAmount.zero(String denomination, int decimals) =>
      DenominatedAmount(
        denomination: denomination,
        value: BigInt.zero,
        decimals: decimals,
      );

  /// Parse a human-readable decimal string (e.g. `"0.005"`) into a
  /// [DenominatedAmount].
  factory DenominatedAmount.fromDecimal(
    String decimal,
    String denomination,
    int decimals,
  ) {
    return DenominatedAmount(
      denomination: denomination,
      value: parseDecimalToBigInt(decimal, decimals),
      decimals: decimals,
    );
  }

  /// Construct from a JSON map produced by [toJson].
  factory DenominatedAmount.fromJson(Map<String, dynamic> json) {
    final denomination = json['denomination'] as String;
    final decimals = json['decimals'] as int;
    final raw = json['value'];
    final BigInt parsedValue;
    if (raw is BigInt) {
      parsedValue = raw;
    } else if (raw is int) {
      parsedValue = BigInt.from(raw);
    } else if (raw is String) {
      parsedValue = parseDecimalToBigInt(raw, decimals);
    } else if (raw is num) {
      parsedValue = parseDecimalToBigInt(raw.toString(), decimals);
    } else {
      throw ArgumentError('Invalid denominated amount value: $raw');
    }
    return DenominatedAmount(
      denomination: denomination,
      value: parsedValue,
      decimals: decimals,
    );
  }

  // ── Serialization ─────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'value': toDecimalString(),
        'denomination': denomination,
        'decimals': decimals,
      };

  /// Format as a decimal string using the denomination's native precision.
  /// e.g. `50000000` sats → `"0.50000000"` for 8-decimal BTC.
  String toDecimalString({int? maxDecimals}) {
    return formatDecimal(value, decimals, maxDecimals: maxDecimals);
  }

  // ── Arithmetic ────────────────────────────────────────────────────

  DenominatedAmount operator +(DenominatedAmount other) {
    _assertSameDenomination(other);
    return DenominatedAmount(
      denomination: denomination,
      value: value + other.value,
      decimals: decimals,
    );
  }

  DenominatedAmount operator -(DenominatedAmount other) {
    _assertSameDenomination(other);
    return DenominatedAmount(
      denomination: denomination,
      value: value - other.value,
      decimals: decimals,
    );
  }

  DenominatedAmount abs() => DenominatedAmount(
        denomination: denomination,
        value: value.abs(),
        decimals: decimals,
      );

  /// Whether this amount is exactly zero.
  bool get isZero => value == BigInt.zero;

  /// Whether this amount is negative.
  bool get isNegative => value.isNegative;

  /// Multiply by a scalar integer.
  DenominatedAmount operator *(int scalar) => DenominatedAmount(
        denomination: denomination,
        value: value * BigInt.from(scalar),
        decimals: decimals,
      );

  /// Integer-divide by a scalar.
  DenominatedAmount scalarDiv(int divisor) => DenominatedAmount(
        denomination: denomination,
        value: value ~/ BigInt.from(divisor),
        decimals: decimals,
      );

  int compareTo(DenominatedAmount other) {
    _assertSameDenomination(other);
    return value.compareTo(other.value);
  }

  bool operator <(DenominatedAmount other) => compareTo(other) < 0;
  bool operator <=(DenominatedAmount other) => compareTo(other) <= 0;
  bool operator >(DenominatedAmount other) => compareTo(other) > 0;
  bool operator >=(DenominatedAmount other) => compareTo(other) >= 0;

  static DenominatedAmount max(DenominatedAmount a, DenominatedAmount b) =>
      a >= b ? a : b;
  static DenominatedAmount min(DenominatedAmount a, DenominatedAmount b) =>
      a <= b ? a : b;

  // ── Scale conversion ────────────────────────────────────────────────

  /// Returns a new [DenominatedAmount] with the same denomination but
  /// a different number of [decimals].
  ///
  /// If [newDecimals] < [decimals], the value is integer-divided (truncated).
  /// If [newDecimals] > [decimals], the value is scaled up.
  DenominatedAmount rescale(int newDecimals) {
    if (newDecimals == decimals) return this;
    final diff = decimals - newDecimals;
    final factor = BigInt.from(10).pow(diff.abs());
    return DenominatedAmount(
      denomination: denomination,
      value: diff > 0 ? value ~/ factor : value * factor,
      decimals: newDecimals,
    );
  }

  // ── Predicates ────────────────────────────────────────────────────

  /// Whether this denomination represents the BTC family (Lightning, RBTC).
  bool get isBtc => denomination == 'BTC';

  /// Whether this denomination represents US-dollar stablecoins (USDT, etc.).
  bool get isUsd => denomination == 'USD';

  /// Whether this denomination represents the ETH family (Arbitrum, Ethereum).
  bool get isEth => denomination == 'ETH';

  // ── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DenominatedAmount &&
          denomination == other.denomination &&
          value == other.value;

  @override
  int get hashCode => denomination.hashCode ^ value.hashCode;

  @override
  String toString() => 'DenominatedAmount(${toDecimalString()} $denomination)';

  // ── Private helpers ───────────────────────────────────────────────

  void _assertSameDenomination(DenominatedAmount other) {
    if (denomination != other.denomination) {
      throw ArgumentError(
        'Cannot combine amounts of different denominations: '
        '$denomination vs ${other.denomination}',
      );
    }
    if (decimals != other.decimals) {
      throw ArgumentError(
        'Cannot combine amounts with different decimal scales: '
        '$denomination ($decimals decimals) vs '
        '${other.denomination} (${other.decimals} decimals). '
        'Use .rescale() to align them first.',
      );
    }
  }
}
