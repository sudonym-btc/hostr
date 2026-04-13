import 'package:flutter/material.dart';

/// A compact ﹣/value/﹢ row for picking an int.
///
/// When [min] is `null` (the default – useful for search filters):
/// * `null` means "Any" (no preference).
/// * Pressing ﹢ when value is `null` sets it to 1.
/// * Pressing ﹣ when value is 1 resets to `null` ("Any").
///
/// When [min] is set (e.g. `0` – useful for edit forms):
/// * The value is clamped to [min] and "Any" never appears.
///
/// If [label] is provided it is shown at the leading edge of the row (useful
/// for inline filters like "Bedrooms  ﹣ 2 ﹢").
class IntFieldSelector extends StatelessWidget {
  final String? label;
  final int? value;
  final ValueChanged<int?> onChanged;

  /// Upper bound (inclusive). `null` = unlimited.
  final int? max;

  /// Lower bound (inclusive). `null` = the widget uses nullable "Any" mode.
  final int? min;

  const IntFieldSelector({
    super.key,
    this.label,
    required this.value,
    required this.onChanged,
    this.max,
    this.min,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    final bool canDecrement;
    final VoidCallback? onDecrement;

    if (min != null) {
      // Bounded mode – value should never be null.
      final v = value ?? min!;
      canDecrement = v > min!;
      onDecrement = canDecrement ? () => onChanged(v - 1) : null;
    } else {
      // Nullable "Any" mode.
      canDecrement = value != null;
      onDecrement = canDecrement
          ? () => onChanged(value! <= 1 ? null : value! - 1)
          : null;
    }

    final bool canIncrement = !(max != null && value != null && value! >= max!);

    return Row(
      children: [
        if (label != null)
          Expanded(child: Text(label!, style: theme.textTheme.bodyLarge)),
        IconButton.outlined(
          onPressed: onDecrement,
          icon: const Icon(Icons.remove, size: 18),
          visualDensity: VisualDensity.compact,
        ),
        SizedBox(
          width: 40,
          child: Text(
            value?.toString() ?? (min != null ? min.toString() : 'Any'),
            style: theme.textTheme.titleSmall,
            textAlign: TextAlign.center,
          ),
        ),
        IconButton.outlined(
          onPressed: canIncrement
              ? () => onChanged((value ?? min ?? 0) + 1)
              : null,
          icon: const Icon(Icons.add, size: 18),
          visualDensity: VisualDensity.compact,
        ),
      ],
    );
  }
}
