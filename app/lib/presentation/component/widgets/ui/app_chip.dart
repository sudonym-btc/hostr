import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/presentation/layout/app_layout.dart';

// ─── Size tokens ─────────────────────────────────────────────

enum _ChipSize { xs, sm, md, lg }

VisualDensity _densityFor(_ChipSize size) => switch (size) {
  _ChipSize.xs => const VisualDensity(horizontal: -4, vertical: -4),
  _ChipSize.sm => const VisualDensity(horizontal: -2, vertical: -2),
  _ChipSize.md => VisualDensity.standard,
  _ChipSize.lg => const VisualDensity(horizontal: 2, vertical: 2),
};

// ─── Variant tokens ──────────────────────────────────────────

enum _ChipVariant { none, neutral, success, error, warning, info }

// ─── Shared Material chip tokens ─────────────────────────────

abstract final class AppChipStyles {
  static const shape = AppShapes.chip;
  static const padding = EdgeInsets.symmetric(
    horizontal: kSpace2,
    vertical: kSpace1,
  );
  static const labelPadding = EdgeInsets.symmetric(horizontal: kSpace1);
  static const inputLabelPadding = EdgeInsets.only(left: kSpace2, right: 6);
  static const visualDensity = VisualDensity(horizontal: -2, vertical: -2);
  static const materialTapTargetSize = MaterialTapTargetSize.shrinkWrap;
  static const borderWidth = 1.0;

  static TextStyle labelStyle(BuildContext context, {Color? color}) {
    final base =
        Theme.of(context).textTheme.bodySmall ??
        DefaultTextStyle.of(context).style;
    return base.copyWith(fontWeight: FontWeight.w500, color: color);
  }

  static TextStyle statefulLabelStyle(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return labelStyle(context).copyWith(
      color: WidgetStateColor.resolveWith((states) {
        if (states.contains(WidgetState.disabled)) {
          return cs.onSurface.withValues(alpha: 0.38);
        }
        if (states.contains(WidgetState.selected)) {
          return cs.onSecondaryContainer;
        }
        return cs.onSurfaceVariant;
      }),
    );
  }

  static IconThemeData iconTheme(BuildContext context) {
    return IconThemeData(
      size: kIconSm,
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );
  }

  static Color neutralBackground(BuildContext context) {
    return AppSurface.stepped(context, 2);
  }

  static BorderSide neutralSide(BuildContext context) {
    return BorderSide(
      color: Theme.of(context).colorScheme.outlineVariant,
      width: borderWidth,
    );
  }

  static WidgetStateProperty<Color?> selectableColor(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return cs.onSurface.withValues(alpha: 0.08);
      }
      if (states.contains(WidgetState.selected)) {
        return cs.secondaryContainer;
      }
      if (states.contains(WidgetState.pressed) ||
          states.contains(WidgetState.hovered) ||
          states.contains(WidgetState.focused)) {
        return AppSurface.stepped(context, 3);
      }
      return neutralBackground(context);
    });
  }

  static WidgetStateBorderSide selectableSide(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return WidgetStateBorderSide.resolveWith((states) {
      if (states.contains(WidgetState.disabled)) {
        return BorderSide(
          color: cs.onSurface.withValues(alpha: 0.12),
          width: borderWidth,
        );
      }
      if (states.contains(WidgetState.selected)) {
        return BorderSide(color: cs.secondary, width: borderWidth);
      }
      return neutralSide(context);
    });
  }
}

// ─── AppChip ─────────────────────────────────────────────────

/// A [Chip] wrapper with semantic variant and size factories.
///
/// **Variants** auto-set the background colour from the active [ColorScheme]:
/// - [AppChip.success] → tertiary container
/// - [AppChip.error]   → error
/// - [AppChip.warning] → amber
/// - [AppChip.info]    → secondary container
///
/// **Sizes** are exposed as methods on each variant factory and affect
/// [VisualDensity]:
/// | token | density                          |
/// |-------|----------------------------------|
/// | xs    | `(horizontal: -4, vertical: -4)` |
/// | sm    | `(horizontal: -2, vertical: -2)` |
/// | md    | `VisualDensity.standard` (default)|
/// | lg    | `(horizontal:  2, vertical:  2)` |
///
/// ## Usage
/// ```dart
/// // Plain default chip
/// AppChip(label: Text('Hello'))
///
/// // Variant — default (md) size
/// AppChip.success(label: Text('Verified'))
/// AppChip.error(label: Text('Failed'))
///
/// // Variant + explicit size
/// AppChip.error.xs(label: Text('Tiny error'))
/// AppChip.success.lg(label: Text('Big success'))
///
/// // Override colour even on a variant chip
/// AppChip.error.sm(label: Text('Custom'), backgroundColor: Colors.purple)
///
/// // Interactive chip
/// AppChip.info.sm(label: Text('Details'), onTap: () {})
/// ```
class AppChip extends StatelessWidget {
  final Widget label;
  final Widget? avatar;
  final Color? backgroundColor;
  final OutlinedBorder? shape;
  final VoidCallback? onTap;
  final _ChipVariant _variant;
  final _ChipSize _size;

  /// Default chip — no variant colour, medium density.
  const AppChip({
    super.key,
    required this.label,
    this.avatar,
    this.backgroundColor,
    this.shape,
    this.onTap,
  }) : _variant = _ChipVariant.none,
       _size = _ChipSize.md;

  const AppChip._internal({
    super.key,
    required this.label,
    this.avatar,
    this.backgroundColor,
    this.shape,
    this.onTap,
    required _ChipVariant variant,
    required _ChipSize size,
  }) : _variant = variant,
       _size = size;

  // ─── Variant factory handles ────────────────────────────────
  // Each is a callable const object so both of these work:
  //   AppChip.success(label: Text('ok'))
  //   AppChip.success.xs(label: Text('ok'))

  /// Success variant. Uses `colorScheme.tertiaryContainer`.
  static const success = _AppChipVariantFactory._(_ChipVariant.success);

  /// Error variant. Uses `colorScheme.errorContainer`.
  static const error = _AppChipVariantFactory._(_ChipVariant.error);

  /// Warning variant. Uses an amber tinted background.
  static const warning = _AppChipVariantFactory._(_ChipVariant.warning);

  /// Info variant. Uses `colorScheme.secondaryContainer`.
  static const info = _AppChipVariantFactory._(_ChipVariant.info);

  /// Neutral variant. Uses a stepped app surface.
  static const neutral = _AppChipVariantFactory._(_ChipVariant.neutral);

  // ─── Colour resolution ──────────────────────────────────────

  static const _kWarningColor = Color(0xFFFF9800);

  Color? _resolveBackgroundColor(ColorScheme cs, BuildContext context) {
    if (backgroundColor != null) return backgroundColor;
    double alpha = 0.12;
    final base = switch (_variant) {
      _ChipVariant.none => null,
      _ChipVariant.neutral => AppSurface.stepped(context, 2),
      _ChipVariant.success => cs.tertiaryContainer,
      _ChipVariant.error => cs.errorContainer,
      _ChipVariant.warning => _kWarningColor.withValues(alpha: alpha),
      _ChipVariant.info => cs.secondaryContainer,
    };
    return base;
  }

  Color? _resolveLabelColor(ColorScheme cs, BuildContext context) {
    return switch (_variant) {
      _ChipVariant.none => null,
      _ChipVariant.neutral => cs.onSurfaceVariant,
      _ChipVariant.success => cs.onTertiaryContainer,
      _ChipVariant.error => cs.onErrorContainer,
      _ChipVariant.warning => _kWarningColor,
      _ChipVariant.info => cs.onSecondaryContainer,
    };
  }

  Color? _resolveBorderColor(ColorScheme cs) {
    return switch (_variant) {
      _ChipVariant.neutral => cs.outlineVariant,
      _ChipVariant.success ||
      _ChipVariant.error ||
      _ChipVariant.warning ||
      _ChipVariant.info => Colors.transparent,
      _ => null,
    };
  }

  // ─── Build ───────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final bg = _resolveBackgroundColor(cs, context);
    final fg = _resolveLabelColor(cs, context);
    final border = _resolveBorderColor(cs);
    final effectiveShape = shape ?? AppShapes.chipWithSide(color: border);
    final visualDensity = _densityFor(_size);
    final labelStyle = AppChipStyles.labelStyle(context, color: fg);

    if (onTap != null) {
      return InputChip(
        visualDensity: visualDensity,
        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
        shape: effectiveShape,
        backgroundColor: bg,
        avatar: avatar,
        label: label,
        labelStyle: labelStyle,
        onPressed: onTap,
      );
    }

    return Chip(
      visualDensity: visualDensity,
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
      shape: effectiveShape,
      backgroundColor: bg,
      avatar: avatar,
      label: label,
      labelStyle: labelStyle,
    );
  }
}

// ─── Variant factory ─────────────────────────────────────────

/// Callable const factory held on [AppChip] static fields.
///
/// Calling it directly (`AppChip.success(...)`) produces a chip at the
/// default (md) density. Named size methods (`AppChip.success.xs(...)`)
/// override the density.
class _AppChipVariantFactory {
  final _ChipVariant _variant;

  const _AppChipVariantFactory._(this._variant);

  /// Default (md) size.
  AppChip call({
    Key? key,
    required Widget label,
    Widget? avatar,
    Color? backgroundColor,
    OutlinedBorder? shape,
    VoidCallback? onTap,
  }) => AppChip._internal(
    key: key,
    label: label,
    avatar: avatar,
    backgroundColor: backgroundColor,
    shape: shape,
    onTap: onTap,
    variant: _variant,
    size: _ChipSize.md,
  );

  /// Extra-small — `VisualDensity(horizontal: -4, vertical: -4)`.
  AppChip xs({
    Key? key,
    required Widget label,
    Widget? avatar,
    Color? backgroundColor,
    OutlinedBorder? shape,
    VoidCallback? onTap,
  }) => AppChip._internal(
    key: key,
    label: label,
    avatar: avatar,
    backgroundColor: backgroundColor,
    shape: shape,
    onTap: onTap,
    variant: _variant,
    size: _ChipSize.xs,
  );

  /// Small — `VisualDensity(horizontal: -2, vertical: -2)` (compact).
  AppChip sm({
    Key? key,
    required Widget label,
    Widget? avatar,
    Color? backgroundColor,
    OutlinedBorder? shape,
    VoidCallback? onTap,
  }) => AppChip._internal(
    key: key,
    label: label,
    avatar: avatar,
    backgroundColor: backgroundColor,
    shape: shape,
    onTap: onTap,
    variant: _variant,
    size: _ChipSize.sm,
  );

  /// Medium — `VisualDensity.standard` (same as calling the factory directly).
  AppChip md({
    Key? key,
    required Widget label,
    Widget? avatar,
    Color? backgroundColor,
    OutlinedBorder? shape,
    VoidCallback? onTap,
  }) => AppChip._internal(
    key: key,
    label: label,
    avatar: avatar,
    backgroundColor: backgroundColor,
    shape: shape,
    onTap: onTap,
    variant: _variant,
    size: _ChipSize.md,
  );

  /// Large — `VisualDensity(horizontal: 2, vertical: 2)`.
  AppChip lg({
    Key? key,
    required Widget label,
    Widget? avatar,
    Color? backgroundColor,
    OutlinedBorder? shape,
    VoidCallback? onTap,
  }) => AppChip._internal(
    key: key,
    label: label,
    avatar: avatar,
    backgroundColor: backgroundColor,
    shape: shape,
    onTap: onTap,
    variant: _variant,
    size: _ChipSize.lg,
  );
}
