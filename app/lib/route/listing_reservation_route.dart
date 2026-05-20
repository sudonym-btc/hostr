import 'package:models/main.dart';

const reserveAmountValueQueryParam = 'reserveAmountValue';
const reserveAmountDenominationQueryParam = 'reserveAmountDenomination';
const reserveAmountDecimalsQueryParam = 'reserveAmountDecimals';
const autoReserveQueryParam = 'autoReserve';

String? reserveAmountValueQuery(DenominatedAmount? amount) =>
    amount?.value.toString();

String? reserveAmountDenominationQuery(DenominatedAmount? amount) =>
    amount?.denomination;

String? reserveAmountDecimalsQuery(DenominatedAmount? amount) =>
    amount?.decimals.toString();

String? autoReserveQuery(bool autoReserve) => autoReserve ? '1' : null;

bool parseAutoReserveQuery(String? value) {
  final normalized = value?.trim().toLowerCase();
  return normalized == '1' || normalized == 'true';
}

DenominatedAmount? parseReserveAmountQuery({
  required String? value,
  required String? denomination,
  required String? decimals,
}) {
  if (value == null || denomination == null || decimals == null) {
    return null;
  }
  final parsedValue = BigInt.tryParse(value);
  final parsedDecimals = int.tryParse(decimals);
  if (parsedValue == null || parsedDecimals == null) {
    return null;
  }
  if (denomination.trim().isEmpty || parsedValue <= BigInt.zero) {
    return null;
  }
  return DenominatedAmount(
    denomination: denomination,
    value: parsedValue,
    decimals: parsedDecimals,
  );
}
