class Amount {
  /// Amount stored in the smallest unit for the given [currency].
  /// For BTC this is wei-btc (10^18), for USD this is cents (10^2).
  final BigInt value;
  final Currency currency;

  const Amount({required this.value, required this.currency});

  factory Amount.fromDecimal({
    required String decimal,
    required Currency currency,
  }) {
    return Amount(
      value: _parseDecimalToBigInt(decimal, currency.decimals),
      currency: currency,
    );
  }

  factory Amount.fromJson(Map<String, dynamic> json) {
    final currency = Currency.values.firstWhere(
      (e) => e.toString() == 'Currency.${json['currency']}',
    );
    final raw = json['value'];
    final BigInt parsedValue;
    if (raw is BigInt) {
      parsedValue = raw;
    } else if (raw is int) {
      parsedValue = BigInt.from(raw);
    } else if (raw is String) {
      parsedValue = _parseDecimalToBigInt(raw, currency.decimals);
    } else if (raw is num) {
      parsedValue = _parseDecimalToBigInt(raw.toString(), currency.decimals);
    } else {
      throw ArgumentError('Invalid amount value: $raw');
    }
    return Amount(
      value: parsedValue,
      currency: currency,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'value': toDecimalString(),
      'currency': currency.toString().split('.').last,
    };
  }

  String toDecimalString({int? maxDecimals}) {
    return _formatDecimal(value, currency.decimals, maxDecimals: maxDecimals);
  }
}

enum Currency { BTC, USD }

extension CurrencyExtension on Currency {
  int get decimals {
    switch (this) {
      case Currency.BTC:
        return 8;
      case Currency.USD:
        return 2;
    }
  }

  String get prefix {
    switch (this) {
      case Currency.BTC:
        return '₿';
      case Currency.USD:
        return '\$';
    }
  }

  String get suffix {
    switch (this) {
      case Currency.BTC:
        return '';
      case Currency.USD:
        return '';
    }
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
