import 'package:flutter/material.dart';
import 'package:hostr/config/main.dart';

class CustomPadding extends StatelessWidget {
  final int top;
  final int bottom;
  final int left;
  final int right;
  final Widget child;

  const CustomPadding(
      {super.key,
      required this.child,
      this.top = 1,
      this.bottom = 1,
      this.left = 1,
      this.right = 1});

  factory CustomPadding.vertical({int multiplier = 1, required Widget child}) {
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
    return Container(
        padding: EdgeInsets.only(
          top: top * DEFAULT_PADDING.toDouble(),
          bottom: bottom * DEFAULT_PADDING.toDouble(),
          left: left * DEFAULT_PADDING.toDouble(),
          right: right * DEFAULT_PADDING.toDouble(),
        ),
        child: child);
  }
}
