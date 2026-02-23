import 'package:flutter/material.dart';

class AppLoadingIndicator extends StatelessWidget {
  final double size;
  final double strokeWidth;
  final double? value;
  final Color? color;

  const AppLoadingIndicator.small({super.key, this.color})
    : size = 16,
      strokeWidth = 2,
      value = null;

  const AppLoadingIndicator.medium({super.key, this.color})
    : size = 24,
      strokeWidth = 3,
      value = null;

  const AppLoadingIndicator.large({super.key, this.color})
    : size = 48,
      strokeWidth = 4,
      value = null;

  const AppLoadingIndicator.progress({
    super.key,
    required this.value,
    this.size = 48,
    this.strokeWidth = 4,
    this.color,
  }) : assert(value != null && value >= 0 && value <= 1);

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CircularProgressIndicator.adaptive(
        value: value,
        strokeWidth: strokeWidth,
        valueColor: color == null ? null : AlwaysStoppedAnimation(color),
      ),
    );
  }
}
