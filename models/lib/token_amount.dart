import 'denominated_amount.dart';
import 'token.dart';

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

  /// Parse a human-readable decimal string (e.g. `"0.005"`) into a
  /// [TokenAmount] using the token's [Token.decimals].
  factory TokenAmount.fromDecimal(String decimal, Token token) {
    return TokenAmount(
      value: _parseDecimalToBigInt(decimal, token.decimals),
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
      parsedValue = _parseDecimalToBigInt(raw, token.decimals);
    } else if (raw is num) {
      parsedValue = _parseDecimalToBigInt(raw.toString(), token.decimals);
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
    return _formatDecimal(value, token.decimals, maxDecimals: maxDecimals);
  }

  // ── EVM helpers ───────────────────────────────────────────────────

  /// Convert to a chain-agnostic [DenominatedAmount].
  ///
  /// When [denomination] is provided it is used directly (e.g. `"BTC"` for
  /// tBTC, `"USD"` for USDT).  Otherwise Lightning/native tokens default to
  /// `"BTC"` and ERC-20 tokens fall back to the token's [Token.tagId].
  DenominatedAmount toDenominated({String? denomination}) => DenominatedAmount(
        value: value,
        denomination: denomination ??
            ((token.isLightning || token.isNative) ? 'BTC' : token.tagId),
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
  /// Throws for Lightning BTC since it has no on-chain representation.
  BigInt get asEvm {
    if (token.isLightning) {
      throw UnsupportedError(
        'Lightning BTC has no on-chain representation',
      );
    }
    return value;
  }

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
}

// ── Shared decimal parsing / formatting ───────────────────────────────

BigInt _parseDecimalToBigInt(String input, int decimals) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) return BigInt.zero;

  final isNegative = trimmed.startsWith('-');
  final normalized = isNegative ? trimmed.substring(1) : trimmed;

  final parts = normalized.split('.');
  final wholePart = parts[0].isEmpty ? '0' : parts[0];
  final fracPart = parts.length > 1 ? parts[1] : '';

  final fracPadded = (fracPart.length >= decimals)
      ? fracPart.substring(0, decimals)
      : fracPart.padRight(decimals, '0');

  final whole = BigInt.parse(wholePart);
  final frac = fracPadded.isEmpty ? BigInt.zero : BigInt.parse(fracPadded);
  final factor = BigInt.from(10).pow(decimals);
  final value = (whole * factor) + frac;
  return isNegative ? -value : value;
}

String _formatDecimal(
  BigInt value,
  int decimals, {
  int? maxDecimals,
}) {
  final isNegative = value.isNegative;
  final absValue = value.abs();
  final factor = BigInt.from(10).pow(decimals);
  final whole = absValue ~/ factor;
  var frac = (absValue % factor).toString().padLeft(decimals, '0');

  if (maxDecimals != null && maxDecimals < decimals) {
    frac = frac.substring(0, maxDecimals);
  }

  final result = frac.isEmpty ? whole.toString() : '${whole.toString()}.$frac';
  return isNegative ? '-$result' : result;
}
