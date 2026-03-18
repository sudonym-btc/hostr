import 'package:flutter/material.dart';
import 'package:hostr/presentation/app_spacing_theme.dart';

class CustomPadding extends StatelessWidget {
  final double top;
  final double bottom;
  final double left;
  final double right;
  final Widget? child;
  final bool useRawValues;
  final Spacing? topToken;
  final Spacing? bottomToken;
  final Spacing? leftToken;
  final Spacing? rightToken;

  /// Directional fluent API:
  /// - `CustomPadding.horizontal.md(child: ...)`
  /// - `CustomPadding.vertical.sm(child: ...)`
  static const horizontal = CustomPaddingAxisFactory._(Axis.horizontal);
  static const vertical = CustomPaddingAxisFactory._(Axis.vertical);

  static CustomPadding none({required Widget child, Key? key}) =>
      custom(0, child: child, key: key);
  static CustomPadding xxs({required Widget child, Key? key}) =>
      token(Spacing.xxs, child: child, key: key);
  static CustomPadding xs({required Widget child, Key? key}) =>
      token(Spacing.xs, child: child, key: key);
  static CustomPadding sm({required Widget child, Key? key}) =>
      token(Spacing.sm, child: child, key: key);
  static CustomPadding md({required Widget child, Key? key}) =>
      token(Spacing.md, child: child, key: key);
  static CustomPadding lg({required Widget child, Key? key}) =>
      token(Spacing.lg, child: child, key: key);
  static CustomPadding xl({required Widget child, Key? key}) =>
      token(Spacing.xl, child: child, key: key);
  static CustomPadding token(Spacing size, {required Widget child, Key? key}) =>
      CustomPadding._token(
        key: key,
        topToken: size,
        bottomToken: size,
        leftToken: size,
        rightToken: size,
        child: child,
      );
  static CustomPadding symmetric({
    required Widget child,
    Spacing horizontal = Spacing.none,
    Spacing vertical = Spacing.none,
    Key? key,
  }) => CustomPadding._token(
    key: key,
    topToken: vertical,
    bottomToken: vertical,
    leftToken: horizontal,
    rightToken: horizontal,
    child: child,
  );
  static CustomPadding custom(double size, {required Widget child, Key? key}) =>
      CustomPadding.only(
        key: key,
        top: size,
        bottom: size,
        left: size,
        right: size,
        child: child,
      );

  factory CustomPadding.only({
    Key? key,
    required Widget child,
    double top = 0,
    double bottom = 0,
    double left = 0,
    double right = 0,
  }) {
    return CustomPadding._raw(
      key: key,
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: child,
    );
  }

  const CustomPadding._raw({
    super.key,
    this.child,
    this.top = 0,
    this.bottom = 0,
    this.left = 0,
    this.right = 0,
  }) : useRawValues = true,
       topToken = null,
       bottomToken = null,
       leftToken = null,
       rightToken = null;

  const CustomPadding._token({
    super.key,
    this.child,
    this.topToken,
    this.bottomToken,
    this.leftToken,
    this.rightToken,
  }) : top = 0,
       bottom = 0,
       left = 0,
       right = 0,
       useRawValues = false;

  const CustomPadding({
    super.key,
    this.child,
    this.top = 1,
    this.bottom = 1,
    this.left = 1,
    this.right = 1,
  }) : useRawValues = false,
       topToken = null,
       bottomToken = null,
       leftToken = null,
       rightToken = null;

  @override
  Widget build(BuildContext context) {
    final spacing = AppSpacing.of(context);

    double resolveEdge(double value, Spacing? token) {
      if (token != null) {
        return spacing.resolve(token);
      }
      if (useRawValues) {
        return value;
      }
      return value * spacing.lg;
    }

    return Padding(
      padding: EdgeInsets.only(
        top: resolveEdge(top, topToken),
        bottom: resolveEdge(bottom, bottomToken),
        left: resolveEdge(left, leftToken),
        right: resolveEdge(right, rightToken),
      ),
      child: child ?? Container(),
    );
  }
}

class CustomPaddingAxisFactory {
  final Axis _axis;

  const CustomPaddingAxisFactory._(this._axis);

  CustomPadding _tokenPadding(Spacing size, {required Widget child, Key? key}) {
    return _axis == Axis.horizontal
        ? CustomPadding._token(
            key: key,
            topToken: Spacing.none,
            bottomToken: Spacing.none,
            leftToken: size,
            rightToken: size,
            child: child,
          )
        : CustomPadding._token(
            key: key,
            topToken: size,
            bottomToken: size,
            leftToken: Spacing.none,
            rightToken: Spacing.none,
            child: child,
          );
  }

  CustomPadding _padding(double size, {required Widget child, Key? key}) {
    return _axis == Axis.horizontal
        ? CustomPadding.only(
            key: key,
            top: 0,
            bottom: 0,
            left: size,
            right: size,
            child: child,
          )
        : CustomPadding.only(
            key: key,
            top: size,
            bottom: size,
            left: 0,
            right: 0,
            child: child,
          );
  }

  CustomPadding none({required Widget child, Key? key}) =>
      _tokenPadding(Spacing.none, child: child, key: key);
  CustomPadding xxs({required Widget child, Key? key}) =>
      _tokenPadding(Spacing.xxs, child: child, key: key);
  CustomPadding xs({required Widget child, Key? key}) =>
      _tokenPadding(Spacing.xs, child: child, key: key);
  CustomPadding sm({required Widget child, Key? key}) =>
      _tokenPadding(Spacing.sm, child: child, key: key);
  CustomPadding md({required Widget child, Key? key}) =>
      _tokenPadding(Spacing.md, child: child, key: key);
  CustomPadding lg({required Widget child, Key? key}) =>
      _tokenPadding(Spacing.lg, child: child, key: key);
  CustomPadding xl({required Widget child, Key? key}) =>
      _tokenPadding(Spacing.xl, child: child, key: key);
  CustomPadding custom(double size, {required Widget child, Key? key}) =>
      _padding(size, child: child, key: key);
}
