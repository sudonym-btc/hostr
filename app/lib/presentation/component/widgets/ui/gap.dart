import 'package:flutter/material.dart';
import 'package:hostr/presentation/app_spacing_theme.dart';

class Gap extends StatelessWidget {
  final double? width;
  final double? height;
  final Spacing? widthToken;
  final Spacing? heightToken;

  /// Square gap where width == height.
  const Gap(double size, {super.key})
    : width = size,
      height = size,
      widthToken = null,
      heightToken = null;

  /// Gap with explicit width/height.
  const Gap.only({super.key, this.width = 0, this.height = 0})
    : widthToken = null,
      heightToken = null;

  const Gap._token({super.key, this.widthToken, this.heightToken})
    : width = null,
      height = null;

  /// Square presets.
  const Gap.xs({super.key})
    : width = null,
      height = null,
      widthToken = Spacing.xs,
      heightToken = Spacing.xs;
  const Gap.sm({super.key})
    : width = null,
      height = null,
      widthToken = Spacing.sm,
      heightToken = Spacing.sm;
  const Gap.md({super.key})
    : width = null,
      height = null,
      widthToken = Spacing.md,
      heightToken = Spacing.md;
  const Gap.lg({super.key})
    : width = null,
      height = null,
      widthToken = Spacing.lg,
      heightToken = Spacing.lg;
  const Gap.xl({super.key})
    : width = null,
      height = null,
      widthToken = Spacing.xl,
      heightToken = Spacing.xl;

  /// Directional fluent API:
  /// - `Gap.horizontal.sm()`
  /// - `Gap.vertical.md()`
  static const horizontal = GapAxisFactory._(Axis.horizontal);
  static const vertical = GapAxisFactory._(Axis.vertical);

  double _resolveToken(BuildContext context, Spacing token) {
    final spacing = AppSpacing.of(context);
    return spacing.resolve(token);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width:
          width ??
          (widthToken != null ? _resolveToken(context, widthToken!) : null),
      height:
          height ??
          (heightToken != null ? _resolveToken(context, heightToken!) : null),
    );
  }
}

class GapAxisFactory {
  final Axis _axis;

  const GapAxisFactory._(this._axis);

  Gap _gap(double size, {Key? key}) {
    return _axis == Axis.horizontal
        ? Gap.only(key: key, width: size)
        : Gap.only(key: key, height: size);
  }

  Gap _tokenGap(Spacing token, {Key? key}) {
    return _axis == Axis.horizontal
        ? Gap._token(key: key, widthToken: token)
        : Gap._token(key: key, heightToken: token);
  }

  Gap none({Key? key}) => _tokenGap(Spacing.none, key: key);
  Gap xxs({Key? key}) => _tokenGap(Spacing.xxs, key: key);
  Gap xs({Key? key}) => _tokenGap(Spacing.xs, key: key);
  Gap sm({Key? key}) => _tokenGap(Spacing.sm, key: key);
  Gap md({Key? key}) => _tokenGap(Spacing.md, key: key);
  Gap lg({Key? key}) => _tokenGap(Spacing.lg, key: key);
  Gap xl({Key? key}) => _tokenGap(Spacing.xl, key: key);
  Gap custom(double size, {Key? key}) => _gap(size, key: key);
}
