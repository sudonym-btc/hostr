import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:intl/intl.dart';
import 'package:models/main.dart';

var format = (bool fiat) => NumberFormat.currency(
  locale: "en_US",
  name: null,
  symbol: '',
  decimalDigits: fiat ? 2 : 0,
);

var compactFormat = (bool fiat) => NumberFormat.compact(locale: "en_US");

final _commaFormat = NumberFormat('#,##0', 'en_US');

DenominatedAmount? highestComparableAmount(
  DenominatedAmount amount,
  Iterable<DenominatedAmount> limits,
) {
  DenominatedAmount? result;
  for (final limit in limits) {
    final comparable = _comparableLimit(amount, limit);
    if (comparable == null) {
      continue;
    }
    if (result == null || comparable.value > result.value) {
      result = comparable;
    }
  }
  return result;
}

DenominatedAmount? lowestComparableAmount(
  DenominatedAmount amount,
  Iterable<DenominatedAmount> limits,
) {
  DenominatedAmount? result;
  for (final limit in limits) {
    final comparable = _comparableLimit(amount, limit);
    if (comparable == null) {
      continue;
    }
    if (result == null || comparable.value < result.value) {
      result = comparable;
    }
  }
  return result;
}

bool amountIsBelowLimit(DenominatedAmount amount, DenominatedAmount? limit) {
  final comparable = _comparableLimit(amount, limit);
  return comparable != null && amount.value < comparable.value;
}

bool amountIsAboveLimit(DenominatedAmount amount, DenominatedAmount? limit) {
  final comparable = _comparableLimit(amount, limit);
  return comparable != null && amount.value > comparable.value;
}

bool amountIsWithinLimits(
  DenominatedAmount amount, {
  required Iterable<DenominatedAmount> min,
  required Iterable<DenominatedAmount> max,
}) {
  return !amountIsBelowLimit(amount, highestComparableAmount(amount, min)) &&
      !amountIsAboveLimit(amount, lowestComparableAmount(amount, max));
}

DenominatedAmount? _comparableLimit(
  DenominatedAmount amount,
  DenominatedAmount? limit,
) {
  if (limit == null || limit.denomination != amount.denomination) {
    return null;
  }
  return limit.decimals == amount.decimals
      ? limit
      : limit.rescale(amount.decimals);
}

DenominatedAmount? comparableAmountLimit(
  DenominatedAmount amount,
  DenominatedAmount? limit,
) => _comparableLimit(amount, limit);

/// Returns the amount expressed in satoshis for BTC-family tokens.
///
/// - Lightning BTC (8 decimals): value is already sats.
/// - Native RBTC (18 decimals): divides out the 10^10 factor.
BigInt _toSats(TokenAmount amount) {
  if (amount.token.decimals <= 8) return amount.value;
  final factor = BigInt.from(10).pow(amount.token.decimals - 8);
  return amount.value ~/ factor;
}

/// Format a [DenominatedAmount] for display (listing prices, negotiation amounts).
///
/// - BTC -> `"₿ 50,000"` (integer sats)
/// - USD -> `"$ 12.50"` (2-decimal fiat)
/// - Unknown -> decimal string with no prefix
String formatAmount(DenominatedAmount amount, {bool exact = true}) {
  if (amount.isBtc) {
    const prefix = '₿ ';
    // Rescale to sats (8 decimals) - tBTC has 18 decimals, Lightning has 8.
    final sats = amount.decimals <= 8
        ? amount.value
        : amount.value ~/ BigInt.from(10).pow(amount.decimals - 8);
    final value = exact
        ? _commaFormat.format(sats.toInt())
        : compactFormat(false).format(sats.toInt());
    return '$prefix$value';
  }

  if (amount.isUsd) {
    final amountAsDouble = amount.value / BigInt.from(10).pow(amount.decimals);
    if (!exact) {
      return '\$ ${compactFormat(true).format(amountAsDouble)}';
    }
    return '\$ ${format(true).format(amountAsDouble)}';
  }

  if (amount.isEth) {
    const prefix = 'Ξ ';
    final amountAsDouble = amount.value / BigInt.from(10).pow(amount.decimals);
    if (!exact) {
      return '$prefix${compactFormat(true).format(amountAsDouble)}';
    }
    final formatted = trimTrailingZeros(amountAsDouble.toStringAsFixed(8));
    return '$prefix$formatted';
  }

  var amountAsDouble = amount.value / BigInt.from(10).pow(amount.decimals);

  if (!exact) {
    final value = compactFormat(true).format(amountAsDouble);
    return value;
  }

  final value = trimTrailingZeros(format(true).format(amountAsDouble));
  return value;
}

/// Lazily-built resolver backed by [getIt<Hostr>] chain configs.
TokenDisplayResolver? _cachedResolver;

TokenDisplayResolver? get _resolver {
  if (_cachedResolver != null) return _cachedResolver;
  try {
    _cachedResolver = TokenDisplayResolver(
      getIt<Hostr>().evm.configuredChains.map((c) => c.config),
    );
  } catch (_) {
    // getIt not yet configured (e.g. during tests) - leave null.
  }
  return _cachedResolver;
}

/// Format a [TokenAmount] for display (on-chain amounts like escrow events).
///
/// Denomination is resolved automatically from the app's chain configuration
/// via [TokenDisplayResolver]. Falls back to BTC display for native tokens
/// and a raw decimal string for unrecognised ERC-20s.
String formatTokenAmount(TokenAmount amount, {bool exact = true}) {
  // Attempt config-based denomination lookup.
  final info = _resolver?.resolve(amount.token);
  if (info != null && info.denomination.isNotEmpty) {
    return formatAmount(
      amount.toDenominated(denomination: info.denomination),
      exact: exact,
    );
  }

  // Fallback: no resolver or unknown token - use token type heuristics.
  if (amount.token.isNative) {
    const prefix = '₿ ';
    final sats = _toSats(amount).toInt();
    final value = exact
        ? _commaFormat.format(sats)
        : compactFormat(false).format(sats);
    return '$prefix$value';
  }

  var amountAsDouble =
      amount.value / BigInt.from(10).pow(amount.token.decimals);

  if (!exact) {
    final value = compactFormat(true).format(amountAsDouble);
    return value;
  }

  final value = trimTrailingZeros(format(true).format(amountAsDouble));
  return value;
}

String trimTrailingZeros(String value) {
  if (value.contains('.')) {
    value = value.replaceAll(RegExp(r'0*$'), '');
    value = value.replaceAll(RegExp(r'\.$'), '');
  }
  return value;
}
