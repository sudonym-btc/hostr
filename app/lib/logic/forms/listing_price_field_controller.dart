import 'package:hostr/logic/forms/amount_field_controller.dart';
import 'package:hostr/logic/forms/form_field_controller.dart';
import 'package:models/main.dart';

/// Well-known decimal precision for each denomination.
///
/// BTC uses 8 decimals (satoshis), USD uses 6 (micro-dollars),
/// ETH uses 18 (wei).  Add entries here as new denominations
/// are supported.
const denominationDecimals = <String, int>{'BTC': 8, 'USD': 6, 'ETH': 18};

/// Returns the canonical decimal count for [denomination], defaulting to 8.
int decimalsForDenomination(String denomination) =>
    denominationDecimals[denomination] ?? 8;

/// Manages listing price state as a thin wrapper around [AmountFieldController].
///
/// Adds frequency (daily/weekly/etc.) and the [Price] ↔ [DenominatedAmount]
/// bridging that the underlying amount controller doesn't know about.
class ListingPriceFieldController extends FormFieldController {
  /// The amount sub-controller — owns the denomination, text editing, and
  /// integer-vs-decimal parsing.
  final AmountFieldController amountField = AmountFieldController();

  // ── Delegated accessors ─────────────────────────────────────────

  /// Shortcut: the active denomination (e.g. `"BTC"`, `"USD"`).
  String get denomination => amountField.denomination;

  /// Shortcut: the active decimal precision.
  int get decimals => amountField.decimals;

  /// Shortcut: the current amount (may be `null` if empty/zero).
  DenominatedAmount? get amount => amountField.amount;

  /// The current amount for display — never null, returns zero when empty.
  DenominatedAmount get displayAmount =>
      amountField.amount ??
      DenominatedAmount.zero(amountField.denomination, amountField.decimals);

  // ── Dirty / Valid ───────────────────────────────────────────────

  @override
  bool get isDirty => amountField.isDirty;

  @override
  bool get isValid => validatePrice() == null;

  // ── Denomination ────────────────────────────────────────────────

  /// Switch denomination, clearing the entered value.
  void setDenomination(String denomination) {
    amountField.setDenomination(denomination);
    notifyListeners();
  }

  // ── State (from model) ──────────────────────────────────────────

  /// Initialise from the listing's existing prices.
  void setState(List<Price> prices) {
    final nightly = prices.firstWhere(
      (p) => p.frequency == Frequency.daily,
      orElse: () => prices.isNotEmpty
          ? prices.first
          : Price(
              amount: DenominatedAmount.zero(
                amountField.denomination,
                amountField.decimals,
              ),
              frequency: Frequency.daily,
            ),
    );

    // Initialise the amount controller with the nightly amount.
    // A zero value is treated as "empty" — display blank.
    final a = nightly.amount;
    amountField.setState(a.value > BigInt.zero ? a : null);
    notifyListeners();
  }

  /// Set the amount directly (e.g. from the keypad bottom sheet).
  void setAmount(DenominatedAmount? value) {
    amountField.setState(value);
    notifyListeners();
  }

  // ── Validation ──────────────────────────────────────────────────

  String? validatePrice([String? _]) {
    final a = amountField.amount;
    if (a == null || a.value <= BigInt.zero) {
      return 'Enter a valid price';
    }
    return null;
  }

  // ── Build model ─────────────────────────────────────────────────

  /// Build the updated price list, replacing or appending the daily price.
  List<Price> buildUpdatedPrices(List<Price> currentPrices) {
    final updatedAmount =
        amountField.amount ??
        DenominatedAmount.zero(amountField.denomination, amountField.decimals);

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

  // ── Lifecycle ───────────────────────────────────────────────────

  ListingPriceFieldController() {
    // Forward change notifications from the child amount controller.
    amountField.addListener(notifyListeners);
  }

  @override
  void dispose() {
    amountField.removeListener(notifyListeners);
    amountField.dispose();
    super.dispose();
  }
}
