import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';

abstract final class AppButtonStyles {
  static const shape = AppShapes.button;

  static ButtonStyle primary(BuildContext context) {
    return primaryFromScheme(Theme.of(context).colorScheme);
  }

  static ButtonStyle primaryFromScheme(ColorScheme colors) {
    return FilledButton.styleFrom(
      backgroundColor: colors.primary,
      foregroundColor: colors.onPrimary,
      disabledBackgroundColor: colors.onSurface.withValues(alpha: 0.12),
      disabledForegroundColor: colors.onSurface.withValues(alpha: 0.38),
      shape: shape,
    );
  }

  static ButtonStyle secondary(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FilledButton.styleFrom(
      backgroundColor: colors.secondary,
      foregroundColor: colors.onSecondary,
      disabledBackgroundColor: colors.onSurface.withValues(alpha: 0.12),
      disabledForegroundColor: colors.onSurface.withValues(alpha: 0.38),
      shape: shape,
    );
  }

  static ButtonStyle destructive(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return FilledButton.styleFrom(
      backgroundColor: colors.error,
      foregroundColor: colors.onError,
      disabledBackgroundColor: colors.onSurface.withValues(alpha: 0.12),
      disabledForegroundColor: colors.onSurface.withValues(alpha: 0.38),
      shape: shape,
    );
  }

  static ButtonStyle destructiveOutline(
    BuildContext context, {
    VisualDensity? visualDensity,
    MaterialTapTargetSize? tapTargetSize,
  }) {
    final colors = Theme.of(context).colorScheme;
    return OutlinedButton.styleFrom(
      foregroundColor: colors.error,
      side: BorderSide(color: colors.error),
      visualDensity: visualDensity,
      tapTargetSize: tapTargetSize,
      shape: shape,
    );
  }

  static ButtonStyle outlined(BuildContext context) {
    return OutlinedButton.styleFrom(shape: shape);
  }

  static ButtonStyle text(BuildContext context) {
    return TextButton.styleFrom(shape: shape);
  }
}
