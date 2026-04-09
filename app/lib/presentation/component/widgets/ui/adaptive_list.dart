import 'package:flutter/material.dart';

/// A list of [children] that scrolls independently when given bounded height
/// (e.g. inside an [Expanded] pane on wide layouts) and lays out like a
/// [Column] when height is unbounded (e.g. inside a [SliverList] on stacked
/// mobile layouts).
///
/// Use this anywhere you'd write a [ListView] whose children are already
/// fully materialised — it adapts automatically so you never need a manual
/// layout check at the call site.
class AdaptiveList extends StatelessWidget {
  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  const AdaptiveList({super.key, required this.children, this.padding});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.hasBoundedHeight) {
          return ListView(
            padding: padding ?? EdgeInsets.zero,
            children: children,
          );
        }
        return Padding(
          padding: padding ?? EdgeInsets.zero,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: children,
          ),
        );
      },
    );
  }
}
