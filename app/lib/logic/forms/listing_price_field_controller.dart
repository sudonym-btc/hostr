import 'package:flutter/material.dart';
import 'package:hostr/core/util/thousands_separator_formatter.dart';
import 'package:hostr/logic/forms/form_field_controller.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

/// Manages listing price state — currency, text editing, and conversion
/// to/from [Amount] and [Price] model objects.
class ListingPriceFieldController extends FormFieldController {
  final TextEditingController textController = TextEditingController();
  Currency currency = Currency.BTC;
  String _originalSats = '0';

  @override
  bool get isDirty {
    final currentSats = textController.text.replaceAll(',', '').trim();
    return currentSats != _originalSats;
  }

  @override
  bool get isValid => validatePrice(textController.text) == null;

  /// Set the initial state from the listing's existing prices.
  void setState(List<Price> prices) {
    currency = Currency.BTC;
    final nightly = prices.firstWhere(
      (p) => p.frequency == Frequency.daily,
      orElse: () => prices.isNotEmpty
          ? prices.first
          : Price(
              amount: Amount(value: BigInt.zero, currency: Currency.BTC),
              frequency: Frequency.daily,
            ),
    );
    final bitcoinAmount = BitcoinAmount.fromAmount(nightly.amount);
    _originalSats = bitcoinAmount.getInSats.toString();
    textController.text = formatWithCommas(_originalSats);
    notifyListeners();
  }

  String? validatePrice(String? value) {
    final amount = amountFromSatsInput(value ?? '');
    if (amount.value <= BigInt.zero) {
      return 'Enter a valid price';
    }
    return null;
  }

  /// Build the updated price list, replacing or appending the daily price.
  List<Price> buildUpdatedPrices(List<Price> currentPrices) {
    final updatedAmount = amountFromSatsInput(textController.text);
    if (currentPrices.isEmpty) {
      return [Price(amount: updatedAmount, frequency: Frequency.daily)];
    }

    bool replaced = false;
    final updated = currentPrices.map((price) {
      if (price.frequency == Frequency.daily) {
        replaced = true;
        return Price(amount: updatedAmount, frequency: Frequency.daily);
      }
      return price;
    }).toList();

    if (!replaced) {
      updated.add(Price(amount: updatedAmount, frequency: Frequency.daily));
    }

    return updated;
  }

  Amount amountFromSatsInput(String input) {
    final trimmed = input.replaceAll(',', '').trim();
    if (trimmed.isEmpty) {
      return Amount(value: BigInt.zero, currency: Currency.BTC);
    }

    try {
      final btcAmount = BitcoinAmount.fromBase10String(
        BitcoinUnit.sat,
        trimmed,
      );
      return btcAmount.toAmount();
    } on FormatException {
      return Amount(value: BigInt.zero, currency: Currency.BTC);
    }
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}
