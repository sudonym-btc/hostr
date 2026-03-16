import 'dart:ui' show lerpDouble;

import 'package:flutter/material.dart';

import 'layout/app_layout.dart';

enum Spacing { none, xxs, xs, sm, md, lg, xl }

@immutable
class AppSpacingTheme extends ThemeExtension<AppSpacingTheme> {
  final double compactScale;
  final double mediumScale;
  final double expandedScale;
  final double chipSpacing;
  final double chipRunSpacing;
  final double chipRowHeight;

  const AppSpacingTheme({
    this.compactScale = 1.0,
    this.mediumScale = 1.1,
    this.expandedScale = 1.5,
    this.chipSpacing = 8.0,
    this.chipRunSpacing = 6.0,
    this.chipRowHeight = 32.0,
  });

  double _scaleFor(AppViewportSize size) {
    return switch (size) {
      AppViewportSize.compact => compactScale,
      AppViewportSize.medium => mediumScale,
      AppViewportSize.expanded => expandedScale,
    };
  }

  AppSpacing resolve(AppLayoutSpec layout) {
    final scale = _scaleFor(layout.size);
    return AppSpacing._(
      xxs: 4.0 * scale,
      xs: 8.0 * scale,
      sm: 12.0 * scale,
      md: 16.0 * scale,
      lg: 20.0 * scale,
      xl: 24.0 * scale,
      defaultPadding: 16.0 * scale,
      chipSpacing: chipSpacing * scale,
      chipRunSpacing: chipRunSpacing * scale,
      chipRowHeight: chipRowHeight * scale,
      pagePadding: EdgeInsets.fromLTRB(
        20.0 * scale,
        16.0 * scale,
        20.0 * scale,
        16.0 * scale,
      ),
      panelPadding: EdgeInsets.all(20.0 * scale),
    );
  }

  @override
  AppSpacingTheme copyWith({
    double? compactScale,
    double? mediumScale,
    double? expandedScale,
    double? chipSpacing,
    double? chipRunSpacing,
    double? chipRowHeight,
  }) {
    return AppSpacingTheme(
      compactScale: compactScale ?? this.compactScale,
      mediumScale: mediumScale ?? this.mediumScale,
      expandedScale: expandedScale ?? this.expandedScale,
      chipSpacing: chipSpacing ?? this.chipSpacing,
      chipRunSpacing: chipRunSpacing ?? this.chipRunSpacing,
      chipRowHeight: chipRowHeight ?? this.chipRowHeight,
    );
  }

  @override
  AppSpacingTheme lerp(ThemeExtension<AppSpacingTheme>? other, double t) {
    if (other is! AppSpacingTheme) return this;
    return AppSpacingTheme(
      compactScale: lerpDouble(compactScale, other.compactScale, t)!,
      mediumScale: lerpDouble(mediumScale, other.mediumScale, t)!,
      expandedScale: lerpDouble(expandedScale, other.expandedScale, t)!,
      chipSpacing: lerpDouble(chipSpacing, other.chipSpacing, t)!,
      chipRunSpacing: lerpDouble(chipRunSpacing, other.chipRunSpacing, t)!,
      chipRowHeight: lerpDouble(chipRowHeight, other.chipRowHeight, t)!,
    );
  }
}

@immutable
class AppSpacing {
  final double xxs;
  final double xs;
  final double sm;
  final double md;
  final double lg;
  final double xl;
  final double defaultPadding;
  final double chipSpacing;
  final double chipRunSpacing;
  final double chipRowHeight;
  final EdgeInsets pagePadding;
  final EdgeInsets panelPadding;

  const AppSpacing._({
    required this.xxs,
    required this.xs,
    required this.sm,
    required this.md,
    required this.lg,
    required this.xl,
    required this.defaultPadding,
    required this.chipSpacing,
    required this.chipRunSpacing,
    required this.chipRowHeight,
    required this.pagePadding,
    required this.panelPadding,
  });

  double resolve(Spacing token) {
    return switch (token) {
      Spacing.none => 0,
      Spacing.xxs => xxs,
      Spacing.xs => xs,
      Spacing.sm => sm,
      Spacing.md => md,
      Spacing.lg => lg,
      Spacing.xl => xl,
    };
  }

  static AppSpacing of(BuildContext context) {
    final themeExtension =
        Theme.of(context).extension<AppSpacingTheme>() ??
        const AppSpacingTheme();
    return themeExtension.resolve(AppLayoutSpec.of(context));
  }
}
