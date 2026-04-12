import 'package:flutter/material.dart';
import 'package:hostr/core/util/thousands_separator_formatter.dart';
import 'package:hostr/logic/forms/form_field_controller.dart';
import 'package:hostr/logic/forms/listing_price_field_controller.dart';
import 'package:models/main.dart';

/// Manages an optional [DenominatedAmount] field that supports any
/// denomination (BTC, USD, ETH, …).
///
/// Used for fields like security deposit and minimum payment amount
/// where the value may be null (unset) or a positive amount.
///
/// For BTC the input is integer sats; for other denominations the input
/// is a decimal string parsed via [DenominatedAmount.fromDecimal].
class AmountFieldController extends FormFieldController {
  final TextEditingController textController = TextEditingController();
  String _denomination = 'BTC';
  int _decimals = 8;
  String _originalValue = '';

  /// The active denomination (e.g. `"BTC"`, `"USD"`).
  String get denomination => _denomination;

  /// The active decimal precision.
  int get decimals => _decimals;

  /// Whether the active denomination uses integer-based input (like BTC/sats).
  bool get _isIntegerInput => _denomination == 'BTC';

  @override
  bool get isDirty {
    final current = _rawText;
    return current != _originalValue;
  }

  String get _rawText => textController.text.replaceAll(',', '').trim();

  /// The current value as a [DenominatedAmount], or `null` if empty/zero.
  DenominatedAmount? get amount {
    final raw = _rawText;
    if (raw.isEmpty) return null;

    if (_isIntegerInput) {
      final sats = BigInt.tryParse(raw) ?? BigInt.zero;
      if (sats <= BigInt.zero) return null;
      return DenominatedAmount(
        denomination: _denomination,
        value: sats,
        decimals: _decimals,
      );
    }

    // Decimal input (USD, ETH, etc.)
    try {
      final parsed = DenominatedAmount.fromDecimal(
        raw,
        _denomination,
        _decimals,
      );
      if (parsed.value <= BigInt.zero) return null;
      return parsed;
    } catch (_) {
      return null;
    }
  }

  /// Whether the field has been explicitly cleared (was non-null, now empty).
  bool get isCleared => _originalValue.isNotEmpty && _rawText.isEmpty;

  /// Switch to a different denomination, clearing the entered value.
  void setDenomination(String denomination) {
    if (denomination == _denomination) return;
    _denomination = denomination;
    _decimals = decimalsForDenomination(denomination);
    _originalValue = '';
    textController.text = '';
    notifyListeners();
  }

  void setState(DenominatedAmount? value) {
    _denomination = value?.denomination ?? _denomination;
    _decimals = value?.decimals ?? decimalsForDenomination(_denomination);
    if (value != null && value.value > BigInt.zero) {
      if (_isIntegerInput) {
        _originalValue = value.value.toString();
        textController.text = formatWithCommas(_originalValue);
      } else {
        _originalValue = value.toDecimalString();
        textController.text = _originalValue;
      }
    } else {
      _originalValue = '';
      textController.text = '';
    }
    notifyListeners();
  }

  String? validate(String? value) {
    // Empty is valid — field is optional.
    final raw = (value ?? '').replaceAll(',', '').trim();
    if (raw.isEmpty) return null;

    if (_isIntegerInput) {
      final parsed = BigInt.tryParse(raw);
      if (parsed == null || parsed < BigInt.zero) {
        return 'Enter a valid amount';
      }
    } else {
      try {
        DenominatedAmount.fromDecimal(raw, _denomination, _decimals);
      } catch (_) {
        return 'Enter a valid amount';
      }
    }
    return null;
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}
