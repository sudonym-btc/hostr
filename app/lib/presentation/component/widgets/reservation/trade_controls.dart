import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';

class TradeMetaRail extends StatelessWidget {
  final Widget amount;
  final Widget? actions;

  const TradeMetaRail({super.key, required this.amount, this.actions});

  @override
  Widget build(BuildContext context) {
    final actionWidgets = actions;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        amount,
        if (actionWidgets != null) ...[
          const SizedBox(width: kSpace2),
          Spacer(),
          actionWidgets,
        ],
      ],
    );
  }
}

class TradeActionBar extends StatelessWidget {
  static const double defaultItemWidth = 104;
  static const double minimumItemWidth = 104;

  final List<Widget> children;
  final MainAxisAlignment alignment;
  final double itemWidth;

  const TradeActionBar({
    super.key,
    required this.children,
    this.alignment = MainAxisAlignment.end,
    this.itemWidth = defaultItemWidth,
  });

  @override
  Widget build(BuildContext context) {
    if (children.isEmpty) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final gaps = kSpace2 * (children.length - 1);
        final availableItemWidth =
            (constraints.maxWidth - gaps) / children.length;
        final resolvedItemWidth = availableItemWidth >= itemWidth
            ? itemWidth
            : availableItemWidth.clamp(minimumItemWidth, itemWidth);

        return Row(
          mainAxisAlignment: alignment,
          mainAxisSize: MainAxisSize.max,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const SizedBox(width: kSpace2),
              SizedBox(width: resolvedItemWidth, child: children[i]),
            ],
          ],
        );
      },
    );
  }
}
