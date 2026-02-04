import 'package:flutter/material.dart';

import 'padding.dart';

class Section extends StatelessWidget {
  final String? title;
  final Widget body;
  final Widget? action;

  const Section({super.key, this.title, required this.body, this.action});

  @override
  Widget build(BuildContext context) {
    return CustomPadding(
        bottom: 0,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
              if (title != null)
                Text(
                  title!,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ?action
            ]),
            body
          ],
        ));
  }
}
