import 'package:flutter/material.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/presentation/app_spacing_theme.dart';
import 'package:hostr/presentation/component/widgets/ui/gap.dart';
import 'package:hostr/presentation/layout/app_layout.dart';

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

  /// When true, uses a more compact layout with smaller padding,
  /// icons, and border radius — suitable for inline contexts like
  /// the reserve bar.
  final bool small;

  /// When true, renders a single combined tile showing
  /// "Check in / out" with the formatted date range below.
  final bool single;

  final String? startText;
  final String? endText;

  const DateRangeButtons({
    super.key,
    this.controller,
    this.onTap,
    this.selectedDateRange,
    this.small = false,
    this.single = false,
    this.startText,
    this.endText,
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

  Widget _buildContent(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final checkIn = _DateTile(
      icon: Icons.calendar_today,
      label: startText ?? 'Check in',
      value: _effectiveRange != null
          ? formatDate(_effectiveRange!.start)
          : null,
      small: small,
      colorScheme: colorScheme,
      theme: theme,
      onTap: () => _handleTap(context),
    );
    final checkOut = _DateTile(
      icon: Icons.calendar_today,
      label: endText ?? 'Check out',
      value: _effectiveRange != null ? formatDate(_effectiveRange!.end) : null,
      small: small,
      colorScheme: colorScheme,
      theme: theme,
      onTap: () => _handleTap(context),
    );

    if (single) {
      final range = _effectiveRange;
      final subtitle = range != null
          ? formatDateRangeShort(range, Localizations.localeOf(context))
          : null;
      return _DateTile(
        icon: Icons.calendar_today,
        label: 'Check in / out',
        value: subtitle,
        small: small,
        colorScheme: colorScheme,
        theme: theme,
        onTap: () => _handleTap(context),
      );
    }

    if (small) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [checkIn, const SizedBox(width: 8), checkOut],
      );
    }

    return Row(
      children: [
        Expanded(child: checkIn),
        const SizedBox(width: 12),
        Expanded(child: checkOut),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    if (controller == null) {
      return _buildContent(context);
    }

    return ListenableBuilder(
      listenable: controller!,
      builder: (context, _) => _buildContent(context),
    );
  }
}

class _DateTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String? value;
  final bool small;
  final ColorScheme colorScheme;
  final ThemeData theme;
  final VoidCallback onTap;

  const _DateTile({
    required this.icon,
    required this.label,
    required this.value,
    this.small = false,
    required this.colorScheme,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final radius = BorderRadius.circular(small ? 12 : 16);
    final iconSize = small
        ? AppSpacing.of(context).xs
        : AppSpacing.of(context).sm;
    final chevronSize = small
        ? AppSpacing.of(context).xs
        : AppSpacing.of(context).sm;
    final padding = small
        ? EdgeInsets.symmetric(
            horizontal: AppSpacing.of(context).xs,
            vertical: AppSpacing.of(context).xs,
          )
        : EdgeInsets.symmetric(
            horizontal: AppSpacing.of(context).sm,
            vertical: AppSpacing.of(context).sm,
          );
    final labelStyle = small
        ? theme.textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          )
        : theme.textTheme.labelMedium?.copyWith(
            fontWeight: FontWeight.bold,
            color: colorScheme.onSurface,
          );
    final valueStyle = small
        ? theme.textTheme.labelSmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          )
        : theme.textTheme.bodySmall?.copyWith(
            color: colorScheme.onSurfaceVariant,
          );

    return AppSurface(
      borderRadius: radius,
      steps: 1,
      child: InkWell(
        onTap: onTap,
        borderRadius: radius,
        child: Padding(
          padding: padding,
          child: Row(
            mainAxisSize: small ? MainAxisSize.min : MainAxisSize.max,
            children: [
              Icon(icon, size: iconSize, color: colorScheme.primary),
              small ? Gap.horizontal.sm() : Gap.horizontal.sm(),
              if (small)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(label, style: labelStyle),
                    if (value != null) Text(value!, style: valueStyle),
                  ],
                )
              else
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(label, style: labelStyle),
                      if (value != null) Text(value!, style: valueStyle),
                    ],
                  ),
                ),
              if (!small)
                Icon(
                  Icons.chevron_right,
                  size: chevronSize,
                  color: colorScheme.onSurfaceVariant,
                ),
            ],
          ),
        ),
      ),
    );
  }
}
