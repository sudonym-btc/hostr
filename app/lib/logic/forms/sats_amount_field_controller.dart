import 'package:flutter/material.dart';
import 'package:hostr/core/util/thousands_separator_formatter.dart';
import 'package:hostr/logic/forms/form_field_controller.dart';
import 'package:models/main.dart';

/// Manages an optional sats-denominated [DenominatedAmount] field.
///
/// Used for fields like security deposit and minimum payment amount
/// where the value may be null (unset) or a positive amount in sats.
class SatsAmountFieldController extends FormFieldController {
  final TextEditingController textController = TextEditingController();
  String _denomination = 'BTC';
  int _decimals = 8;
  String _originalSats = '';

  @override
  bool get isDirty {
    final currentSats = _rawText;
    return currentSats != _originalSats;
  }

  String get _rawText => textController.text.replaceAll(',', '').trim();

  /// The current value as a [DenominatedAmount], or `null` if empty/zero.
  DenominatedAmount? get amount {
    final raw = _rawText;
    if (raw.isEmpty) return null;
    final sats = BigInt.tryParse(raw) ?? BigInt.zero;
    if (sats <= BigInt.zero) return null;
    return DenominatedAmount(
      denomination: _denomination,
      value: sats,
      decimals: _decimals,
    );
  }

  /// Whether the field has been explicitly cleared (was non-null, now empty).
  bool get isCleared => _originalSats.isNotEmpty && _rawText.isEmpty;

  void setState(DenominatedAmount? value) {
    _denomination = value?.denomination ?? 'BTC';
    _decimals = value?.decimals ?? 8;
    if (value != null && value.value > BigInt.zero) {
      _originalSats = value.value.toString();
      textController.text = formatWithCommas(_originalSats);
    } else {
      _originalSats = '';
      textController.text = '';
    }
    notifyListeners();
  }

  String? validate(String? value) {
    // Empty is valid — field is optional.
    final raw = (value ?? '').replaceAll(',', '').trim();
    if (raw.isEmpty) return null;
    final parsed = BigInt.tryParse(raw);
    if (parsed == null || parsed < BigInt.zero) {
      return 'Enter a valid amount';
    }
    return null;
  }

  @override
  void dispose() {
    textController.dispose();
    super.dispose();
  }
}
