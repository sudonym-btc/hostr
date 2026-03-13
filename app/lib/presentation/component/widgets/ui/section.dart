import 'package:flutter/material.dart';

import 'padding.dart';

class Section extends StatelessWidget {
  final String? title;
  final Widget body;
  final Widget? action;
  final bool horizontalPadding;

  const Section({
    super.key,
    this.title,
    required this.body,
    this.action,
    this.horizontalPadding = true,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPadding(
      left: horizontalPadding ? 1 : 0,
      right: horizontalPadding ? 1 : 0,
      bottom: 0,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              if (title != null)
                Text(
                  title!,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ?action,
            ],
          ),
          body,
        ],
      ),
    );
  }
}
