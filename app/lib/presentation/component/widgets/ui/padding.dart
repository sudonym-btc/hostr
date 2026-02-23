import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';

class CustomPadding extends StatelessWidget {
  final double top;
  final double bottom;
  final double left;
  final double right;
  final Widget? child;

  /// Directional fluent API:
  /// - `CustomPadding.horizontal.md(child: ...)`
  /// - `CustomPadding.vertical.sm(child: ...)`
  static const horizontal = CustomPaddingAxisFactory._(Axis.horizontal);
  static const vertical = CustomPaddingAxisFactory._(Axis.vertical);

  static CustomPadding none({required Widget child, Key? key}) =>
      custom(kSpace0, child: child, key: key);
  static CustomPadding xs({required Widget child, Key? key}) =>
      custom(kSpace1, child: child, key: key);
  static CustomPadding sm({required Widget child, Key? key}) =>
      custom(kSpace2, child: child, key: key);
  static CustomPadding md({required Widget child, Key? key}) =>
      custom(kSpace4, child: child, key: key);
  static CustomPadding lg({required Widget child, Key? key}) =>
      custom(kSpace6, child: child, key: key);
  static CustomPadding xl({required Widget child, Key? key}) =>
      custom(kSpace7, child: child, key: key);
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
    double top = kSpace0,
    double bottom = kSpace0,
    double left = kSpace0,
    double right = kSpace0,
  }) {
    return CustomPadding(
      key: key,
      top: top / kDefaultPadding,
      bottom: bottom / kDefaultPadding,
      left: left / kDefaultPadding,
      right: right / kDefaultPadding,
      child: child,
    );
  }

  const CustomPadding({
    super.key,
    this.child,
    this.top = 1,
    this.bottom = 1,
    this.left = 1,
    this.right = 1,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        top: top * kDefaultPadding.toDouble(),
        bottom: bottom * kDefaultPadding.toDouble(),
        left: left * kDefaultPadding.toDouble(),
        right: right * kDefaultPadding.toDouble(),
      ),
      child: child ?? Container(),
    );
  }
}

class CustomPaddingAxisFactory {
  final Axis _axis;

  const CustomPaddingAxisFactory._(this._axis);

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
      _padding(kSpace0, child: child, key: key);
  CustomPadding xs({required Widget child, Key? key}) =>
      _padding(kSpace1, child: child, key: key);
  CustomPadding sm({required Widget child, Key? key}) =>
      _padding(kSpace2, child: child, key: key);
  CustomPadding md({required Widget child, Key? key}) =>
      _padding(kSpace4, child: child, key: key);
  CustomPadding lg({required Widget child, Key? key}) =>
      _padding(kSpace6, child: child, key: key);
  CustomPadding xl({required Widget child, Key? key}) =>
      _padding(kSpace7, child: child, key: key);
  CustomPadding custom(double size, {required Widget child, Key? key}) =>
      _padding(size, child: child, key: key);
}
