import 'package:flutter/material.dart';

import 'padding.dart';

class Section extends StatelessWidget {
  final String? title;
  final Widget body;
  const Section({super.key, this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return CustomPadding(
        child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (title != null)
          Text(
            title!,
            style: Theme.of(context).textTheme.titleMedium,
          ),
        body
      ],
    ));
  }
}
