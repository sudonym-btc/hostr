import 'package:models/amount.dart';
import 'package:wallet/wallet.dart';

/// Utility class to easily convert amounts of Ether into different units of
/// quantities.
class BitcoinAmount {
  const BitcoinAmount.inWei(this._value);

  BitcoinAmount.zero() : this.inWei(BigInt.zero);

  /// Constructs an amount of Ether by a unit and its amount.
  factory BitcoinAmount.fromInt(BitcoinUnit unit, int amount) {
    final wei = _factors[unit]! * BigInt.from(amount);

    return BitcoinAmount.inWei(wei);
  }

  /// Constructs an amount of Ether by a unit and its amount.
  factory BitcoinAmount.fromBigInt(BitcoinUnit unit, BigInt amount) {
    final wei = _factors[unit]! * amount;

    return BitcoinAmount.inWei(wei);
  }

  /// Constructs an amount of Ether by a unit and its amount.
  factory BitcoinAmount.fromBase10String(BitcoinUnit unit, String amount) {
    final wei = _factors[unit]! * BigInt.parse(amount);

    return BitcoinAmount.inWei(wei);
  }

  /// Constructs an amount of Ether from a decimal string in the given [unit].
  ///
  /// This parses using integer math and preserves precision down to wei.
  /// Throws [FormatException] if more fractional digits are provided than the
  /// unit supports (unless the extra digits are all zeros).
  factory BitcoinAmount.fromDecimal(BitcoinUnit unit, String amount) {
    final decimals = _unitDecimals[unit]!;
    final wei = _parseDecimalToBigInt(amount, decimals);
    return BitcoinAmount.inWei(wei);
  }

  factory BitcoinAmount.fromAmount(Amount amount) {
    return BitcoinAmount.fromBigInt(BitcoinUnit.sat, amount.value);
  }

  EtherAmount toEtherAmount() {
    return EtherAmount.inWei(_value);
  }

  Amount toAmount() {
    return Amount(value: getInSats, currency: Currency.BTC);
  }

  /// Gets the value of this amount in the specified unit as a whole number.
  /// **WARNING**: For all units except for [BitcoinUnit.wei], this method will
  /// discard the remainder occurring in the division, making it unsuitable for
  /// calculations or storage. You should store and process amounts of ether by
  /// using a BigInt storing the amount in wei.
  BigInt getValueInUnitBI(BitcoinUnit unit) => _value ~/ _factors[unit]!;

  static final Map<BitcoinUnit, BigInt> _factors = {
    BitcoinUnit.wei: BigInt.one,
    BitcoinUnit.kwei: BigInt.from(10).pow(3),
    BitcoinUnit.mwei: BigInt.from(10).pow(6),
    BitcoinUnit.gwei: BigInt.from(10).pow(9),
    BitcoinUnit.szabo: BigInt.from(10).pow(12),
    BitcoinUnit.finney: BigInt.from(10).pow(15),
    BitcoinUnit.ether: BigInt.from(10).pow(18),
    BitcoinUnit.sat: BigInt.from(10).pow(10),
    BitcoinUnit.msat: BigInt.from(10).pow(7),
    BitcoinUnit.bitcoin: BigInt.from(10).pow(18),
  };

  static final Map<BitcoinUnit, int> _unitDecimals = {
    BitcoinUnit.wei: 0,
    BitcoinUnit.kwei: 3,
    BitcoinUnit.mwei: 6,
    BitcoinUnit.gwei: 9,
    BitcoinUnit.szabo: 12,
    BitcoinUnit.finney: 15,
    BitcoinUnit.ether: 18,
    BitcoinUnit.msat: 7,
    BitcoinUnit.sat: 10,
    BitcoinUnit.bitcoin: 18,
  };

  final BigInt _value;

  BigInt get getInWei => _value;
  BigInt get getInSats => getValueInUnitBI(BitcoinUnit.sat);
  BigInt get getInMSats => getValueInUnitBI(BitcoinUnit.msat);
  BigInt get getInBitcoin => getValueInUnitBI(BitcoinUnit.bitcoin);

  /// Gets the value of this amount in the specified unit. **WARNING**: Due to
  /// rounding errors, the return value of this function is not reliable,
  /// especially for larger amounts or smaller units. While it can be used to
  /// display the amount of ether in a human-readable format, it should not be
  /// used for anything else.
  double getValueInUnit(BitcoinUnit unit) {
    final factor = _factors[unit]!;
    final value = _value ~/ factor;
    final remainder = _value.remainder(factor);

    return value.toInt() + (remainder.toInt() / factor.toInt());
  }

  @override
  String toString() {
    return 'BitcoinAmount: $getInWei wei';
  }

  @override
  int get hashCode => getInWei.hashCode;

  @override
  bool operator ==(Object other) =>
      other is BitcoinAmount && other.getInWei == getInWei;

  BitcoinAmount abs() {
    return BitcoinAmount.inWei(_value.abs());
  }

  int compareTo(BitcoinAmount other) => _value.compareTo(other._value);

  bool operator <(BitcoinAmount other) => compareTo(other) < 0;

  bool operator <=(BitcoinAmount other) => compareTo(other) <= 0;

  bool operator >(BitcoinAmount other) => compareTo(other) > 0;

  bool operator >=(BitcoinAmount other) => compareTo(other) >= 0;

  static BitcoinAmount max(BitcoinAmount a, BitcoinAmount b) {
    return a >= b ? a : b;
  }

  BitcoinAmount operator +(BitcoinAmount other) {
    return BitcoinAmount.inWei(_value + other._value);
  }

  BitcoinAmount operator -(BitcoinAmount other) {
    return BitcoinAmount.inWei(_value - other._value);
  }

  /// Returns a new amount rounded down (floor) to the given [unit].
  BitcoinAmount roundDown(BitcoinUnit unit) {
    final factor = _factors[unit]!;
    final remainder = _value.remainder(factor);
    if (remainder == BigInt.zero) {
      return this;
    }

    final rounded = _value >= BigInt.zero
        ? _value - remainder
        : _value - (factor + remainder);
    return BitcoinAmount.inWei(rounded);
  }

  /// Returns a new amount rounded up (ceil) to the given [unit].
  BitcoinAmount roundUp(BitcoinUnit unit) {
    final factor = _factors[unit]!;
    final remainder = _value.remainder(factor);
    if (remainder == BigInt.zero) {
      return this;
    }

    final rounded = _value >= BigInt.zero
        ? _value + (factor - remainder)
        : _value - remainder;
    return BitcoinAmount.inWei(rounded);
  }
}

BigInt _parseDecimalToBigInt(String input, int decimals) {
  final trimmed = input.trim();
  if (trimmed.isEmpty) {
    return BigInt.zero;
  }

  final isNegative = trimmed.startsWith('-');
  final normalized = isNegative ? trimmed.substring(1) : trimmed;
  final parts = normalized.split('.');
  if (parts.length > 2) {
    throw FormatException('Invalid amount: $input');
  }

  final wholePart = parts[0].isEmpty ? '0' : parts[0];
  final fracPart = parts.length > 1 ? parts[1] : '';

  final fracPadded = fracPart.padRight(decimals, '0').substring(0, decimals);
  final whole = BigInt.parse(wholePart);
  final frac = fracPadded.isEmpty ? BigInt.zero : BigInt.parse(fracPadded);
  final factor = BigInt.from(10).pow(decimals);
  final value = (whole * factor) + frac;
  return isNegative ? -value : value;
}

enum BitcoinUnit {
  /// Wei, the smallest and atomic amount of Ether
  wei,

  /// kwei, 1000 wei
  kwei,

  /// Mwei, one million wei
  mwei,

  /// Gwei, one billion wei. Typically a reasonable unit to measure gas prices.
  gwei,

  /// szabo, 10^12 wei or 1 μEther
  szabo,

  /// finney, 10^15 wei or 1 mEther
  finney,

  /// 1 Ether
  ether,

  msat,

  sat,

  bitcoin,
}
