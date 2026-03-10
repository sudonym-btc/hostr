import 'package:flutter/services.dart';

/// Formats numeric input with thousands separators (commas).
///
/// Example: `1234567` → `1,234,567`
class ThousandsSeparatorFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(',', '');
    if (digits.isEmpty) return newValue.copyWith(text: '');

    final formatted = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final posFromEnd = digits.length - i;
      if (i > 0 && posFromEnd % 3 == 0) formatted.write(',');
      formatted.write(digits[i]);
    }

    final result = formatted.toString();

    // Figure out how many raw digits precede the cursor in the new value.
    final rawCursor = newValue.selection.end.clamp(0, newValue.text.length);
    var digitsSeen = 0;
    for (var i = 0; i < rawCursor && i < newValue.text.length; i++) {
      if (newValue.text[i] != ',') digitsSeen++;
    }

    // Walk the formatted string to place the cursor after the same
    // number of digits.
    var formattedCursor = 0;
    var counted = 0;
    for (var i = 0; i < result.length && counted < digitsSeen; i++) {
      formattedCursor = i + 1;
      if (result[i] != ',') counted++;
    }

    return TextEditingValue(
      text: result,
      selection: TextSelection.collapsed(offset: formattedCursor),
    );
  }
}

/// Formats a raw digit string with comma thousands separators.
String formatWithCommas(String digits) {
  final buf = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    final posFromEnd = digits.length - i;
    if (i > 0 && posFromEnd % 3 == 0) buf.write(',');
    buf.write(digits[i]);
  }
  return buf.toString();
}
