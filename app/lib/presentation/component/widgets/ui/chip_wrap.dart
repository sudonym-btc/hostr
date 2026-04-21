import 'package:flutter/material.dart';
import 'package:hostr/presentation/app_spacing_theme.dart';

class ChipWrap extends StatelessWidget {
  final List<Widget> children;
  final double? spacing;
  final double? runSpacing;
  final WrapAlignment alignment;
  final WrapAlignment runAlignment;
  final WrapCrossAlignment crossAxisAlignment;
  final Axis direction;
  final VerticalDirection verticalDirection;
  final TextDirection? textDirection;
  final Clip clipBehavior;

  const ChipWrap({
    super.key,
    required this.children,
    this.spacing,
    this.runSpacing,
    this.alignment = WrapAlignment.start,
    this.runAlignment = WrapAlignment.start,
    this.crossAxisAlignment = WrapCrossAlignment.start,
    this.direction = Axis.horizontal,
    this.verticalDirection = VerticalDirection.down,
    this.textDirection,
    this.clipBehavior = Clip.none,
  });

  @override
  Widget build(BuildContext context) {
    final appSpacing = AppSpacing.of(context);

    return Wrap(
      spacing: spacing ?? appSpacing.chipSpacing,
      runSpacing: runSpacing ?? appSpacing.chipRunSpacing,
      alignment: alignment,
      runAlignment: runAlignment,
      crossAxisAlignment: crossAxisAlignment,
      direction: direction,
      verticalDirection: verticalDirection,
      textDirection: textDirection,
      clipBehavior: clipBehavior,
      children: children,
    );
  }
}
