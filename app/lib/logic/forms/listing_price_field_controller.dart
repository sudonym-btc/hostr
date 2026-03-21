import 'package:flutter/material.dart';
import 'package:hostr/core/util/thousands_separator_formatter.dart';
import 'package:hostr/logic/forms/form_field_controller.dart';
import 'package:models/main.dart';

/// Manages listing price state — currency, text editing, and conversion
/// to/from [TokenAmount] and [Price] model objects.
class ListingPriceFieldController extends FormFieldController {
  final TextEditingController textController = TextEditingController();
  Token currency = Token.btcLightning;
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
    currency = Token.btcLightning;
    final nightly = prices.firstWhere(
      (p) => p.frequency == Frequency.daily,
      orElse: () => prices.isNotEmpty
          ? prices.first
          : Price(
              amount: TokenAmount.zero(Token.btcLightning),
              frequency: Frequency.daily,
            ),
    );
    _originalSats = nightly.amount.value.toString();
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

  TokenAmount amountFromSatsInput(String input) {
    final trimmed = input.replaceAll(',', '').trim();
    if (trimmed.isEmpty) {
      return TokenAmount.zero(Token.btcLightning);
    }

    try {
      final sats = BigInt.parse(trimmed);
      return TokenAmount(value: sats, token: Token.btcLightning);
    } on FormatException {
      return TokenAmount.zero(Token.btcLightning);
    }
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}
