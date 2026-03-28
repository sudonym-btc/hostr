/// Shared decimal ↔ BigInt conversion helpers.
///
/// Used by both [TokenAmount] and [DenominatedAmount] to avoid duplicating
/// the parsing / formatting logic.

/// Parse a human-readable decimal string (e.g. `"0.005"`) into a [BigInt]
/// representing the value in smallest units for the given [decimals].
BigInt parseDecimalToBigInt(String input, int decimals) {
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

/// Format a [BigInt] smallest-unit value as a human-readable decimal string.
///
/// e.g. `50000000` with 8 decimals → `"0.50000000"`.
String formatDecimal(
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
