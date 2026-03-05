import 'package:flutter/material.dart';
import 'package:hostr/core/main.dart';

import 'date_range_controller.dart';

class DateRangeButtons extends StatelessWidget {
  /// Preferred: pass a controller for full lifecycle management.
  final DateRangeController? controller;

  /// Legacy / convenience: called when the widget is tapped.
  /// Ignored when [controller] is provided.
  final Function? onTap;

  /// Legacy / convenience: the range to display.
  /// Ignored when [controller] is provided.
  final DateTimeRange? selectedDateRange;

  const DateRangeButtons({
    super.key,
    this.controller,
    this.onTap,
    this.selectedDateRange,
  });

  DateTimeRange? get _effectiveRange =>
      controller?.dateRange ?? selectedDateRange;

  void _handleTap(BuildContext context) {
    if (controller != null) {
      controller!.pick(context);
    } else {
      onTap?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Row(
      children: [
        Expanded(
          child: _DateTile(
            icon: Icons.calendar_today,
            label: 'Check in',
            value: _effectiveRange != null
                ? formatDate(_effectiveRange!.start)
                : null,
            colorScheme: colorScheme,
            theme: theme,
            onTap: () => _handleTap(context),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _DateTile(
            icon: Icons.calendar_today,
            label: 'Check out',
            value: _effectiveRange != null
                ? formatDate(_effectiveRange!.end)
                : null,
            colorScheme: colorScheme,
            theme: theme,
            onTap: () => _handleTap(context),
          ),
        ),
      ],
    );
  }
}

class _DateTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback onTap;

  const _DateTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.colorScheme,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: colorScheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          child: Row(
            children: [
              Icon(icon, size: 18, color: colorScheme.primary),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: colorScheme.onSurface,
                      ),
                    ),
                    if (value != null)
                      Text(
                        value!,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                size: 18,
                color: colorScheme.onSurfaceVariant,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
