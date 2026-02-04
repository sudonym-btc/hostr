import 'package:flutter/material.dart';
import 'package:hostr/config/main.dart';

class CustomPadding extends StatelessWidget {
  final double top;
  final double bottom;
  final double left;
  final double right;
  final Widget? child;

  const CustomPadding({
    super.key,
    this.child,
    this.top = 1,
    this.bottom = 1,
    this.left = 1,
    this.right = 1,
  });

  factory CustomPadding.vertical({
    double multiplier = 1,
    required Widget child,
  }) {
    return CustomPadding(
      top: multiplier,
      bottom: multiplier,
      left: 0,
      right: 0,
      child: child,
    );
  }
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
