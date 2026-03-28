import 'denominated_amount.dart';
import 'src/decimal_math.dart';
import 'token.dart';
import 'token_unit.dart';

/// A monetary value denominated in a specific [Token].
///
/// Replaces the former `Amount` (model layer) and `BitcoinAmount` (SDK layer)
/// with a single unified type that carries its token throughout the stack.
///
/// The [value] is always in the token's **smallest unit**:
/// - BTC Lightning → satoshis (8 decimals)
/// - RBTC native   → wei (18 decimals)
/// - USDT          → micro-dollars (6 decimals)
class TokenAmount {
  final BigInt value;
  final Token token;

  const TokenAmount({required this.value, required this.token});

  factory TokenAmount.zero(Token token) =>
      TokenAmount(value: BigInt.zero, token: token);

  /// Construct from an [int] amount in the given [unit], scaled to [token]'s
  /// native precision.
  ///
  /// Follows the `EtherAmount.fromInt(EtherUnit, int)` pattern.
  ///
  /// ```dart
  /// // 200 000 sats → RBTC wei (18 decimals)
  /// TokenAmount.fromInt(TokenUnit.sat, 200000, rbtcToken);
  /// ```
  factory TokenAmount.fromInt(TokenUnit unit, int amount, Token token) =>
      TokenAmount(
        value: _scaleToSmallest(BigInt.from(amount), unit, token),
        token: token,
      );

  /// Construct from a [BigInt] amount in the given [unit], scaled to [token]'s
  /// native precision.
  ///
  /// Follows the `EtherAmount.fromBigInt(EtherUnit, BigInt)` pattern.
  ///
  /// ```dart
  /// // Raw wei value, no scaling
  /// TokenAmount.fromBigInt(TokenUnit.wei, weiValue, rbtcToken);
  /// ```
  factory TokenAmount.fromBigInt(TokenUnit unit, BigInt amount, Token token) =>
      TokenAmount(value: _scaleToSmallest(amount, unit, token), token: token);

  /// Parse a human-readable decimal string (e.g. `"0.005"`) into a
  /// [TokenAmount] using the token's [Token.decimals].
  factory TokenAmount.fromDecimal(String decimal, Token token) {
    return TokenAmount(
      value: parseDecimalToBigInt(decimal, token.decimals),
      token: token,
    );
  }

  /// Construct from a JSON map produced by [toJson].
  factory TokenAmount.fromJson(Map<String, dynamic> json) {
    final token = Token.fromJson(json['token'] as Map<String, dynamic>);
    final raw = json['value'];
    final BigInt parsedValue;
    if (raw is BigInt) {
      parsedValue = raw;
    } else if (raw is int) {
      parsedValue = BigInt.from(raw);
    } else if (raw is String) {
      parsedValue = parseDecimalToBigInt(raw, token.decimals);
    } else if (raw is num) {
      parsedValue = parseDecimalToBigInt(raw.toString(), token.decimals);
    } else {
      throw ArgumentError('Invalid token amount value: $raw');
    }
    return TokenAmount(value: parsedValue, token: token);
  }

  // ── Serialization ─────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'value': toDecimalString(),
        'token': token.toJson(),
      };

  /// Format as a decimal string using the token's native precision.
  /// e.g. `50000000` sats → `"0.50000000"` for 8-decimal BTC.
  String toDecimalString({int? maxDecimals}) {
    return formatDecimal(value, token.decimals, maxDecimals: maxDecimals);
  }

  // ── EVM helpers ───────────────────────────────────────────────────

  /// Convert to a chain-agnostic [DenominatedAmount].
  ///
  /// When [denomination] is provided it is used directly (e.g. `"BTC"` for
  /// tBTC, `"USD"` for USDT).  Otherwise native tokens default to `"BTC"`
  /// and ERC-20 tokens fall back to the token's [Token.tagId].
  DenominatedAmount toDenominated({String? denomination}) => DenominatedAmount(
        value: value,
        denomination: denomination ?? (token.isNative ? 'BTC' : token.tagId),
        decimals: token.decimals,
      );

  /// Create a [TokenAmount] from a [DenominatedAmount] and a concrete [Token].
  ///
  /// Scales the value if the denomination decimals differ from the token
  /// decimals (e.g. BTC 8 decimals → RBTC 18 decimals).
  static TokenAmount fromDenominated(DenominatedAmount da, Token token) {
    if (da.decimals == token.decimals) {
      return TokenAmount(value: da.value, token: token);
    }
    final diff = token.decimals - da.decimals;
    final scaled = diff > 0
        ? da.value * BigInt.from(10).pow(diff)
        : da.value ~/ BigInt.from(10).pow(-diff);
    return TokenAmount(value: scaled, token: token);
  }

  /// The raw value suitable for on-chain contract calls.
  ///
  /// For native RBTC and ERC-20 tokens the [value] is already in the
  /// on-chain smallest unit (wei or token-specific smallest unit).
  BigInt get asEvm => value;

  // ── Arithmetic ────────────────────────────────────────────────────

  TokenAmount operator +(TokenAmount other) {
    _assertSameToken(other);
    return TokenAmount(value: value + other.value, token: token);
  }

  TokenAmount operator -(TokenAmount other) {
    _assertSameToken(other);
    return TokenAmount(value: value - other.value, token: token);
  }

  TokenAmount abs() => TokenAmount(value: value.abs(), token: token);

  /// Whether this amount is exactly zero.
  bool get isZero => value == BigInt.zero;

  /// Whether this amount is negative.
  bool get isNegative => value.isNegative;

  /// Multiply by a scalar integer (e.g. gas price × gas limit).
  TokenAmount operator *(int scalar) =>
      TokenAmount(value: value * BigInt.from(scalar), token: token);

  /// Integer-divide by a scalar.
  TokenAmount scalarDiv(int divisor) =>
      TokenAmount(value: value ~/ BigInt.from(divisor), token: token);

  int compareTo(TokenAmount other) {
    _assertSameToken(other);
    return value.compareTo(other.value);
  }

  bool operator <(TokenAmount other) => compareTo(other) < 0;
  bool operator <=(TokenAmount other) => compareTo(other) <= 0;
  bool operator >(TokenAmount other) => compareTo(other) > 0;
  bool operator >=(TokenAmount other) => compareTo(other) >= 0;

  static TokenAmount max(TokenAmount a, TokenAmount b) => a >= b ? a : b;
  static TokenAmount min(TokenAmount a, TokenAmount b) => a <= b ? a : b;

  // ── Equality ──────────────────────────────────────────────────────

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TokenAmount && token == other.token && value == other.value;

  @override
  int get hashCode => token.hashCode ^ value.hashCode;

  @override
  String toString() => 'TokenAmount(${toDecimalString()} ${token.tagId})';

  // ── Private helpers ───────────────────────────────────────────────

  void _assertSameToken(TokenAmount other) {
    if (token != other.token) {
      throw ArgumentError(
        'Cannot combine amounts of different tokens: '
        '${token.tagId} vs ${other.token.tagId}',
      );
    }
  }

  /// Scale [amount] from [unit]'s decimal precision to [token]'s.
  ///
  /// - `TokenUnit.wei` (decimals = 0): no scaling — input is already in the
  ///   token's smallest unit.
  /// - `TokenUnit.sat` (decimals = 8): scales from 8-decimal sats to the
  ///   token's actual precision (e.g. ×10¹⁰ for 18-decimal RBTC).
  static BigInt _scaleToSmallest(BigInt amount, TokenUnit unit, Token token) {
    if (unit.decimals == 0) return amount; // wei — no conversion
    final diff = token.decimals - unit.decimals;
    if (diff == 0) return amount;
    return diff > 0
        ? amount * BigInt.from(10).pow(diff)
        : amount ~/ BigInt.from(10).pow(-diff);
  }
}
