import 'package:flutter/material.dart';

import 'gap.dart';
import 'padding.dart';

class EmtyResultsWidget extends StatelessWidget {
  final Widget? leading;
  final String title;
  final String? subtitle;
  final Widget? action;

  const EmtyResultsWidget({
    super.key,
    this.leading,
    required this.title,
    this.subtitle,
    this.action,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: CustomPadding(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                if (leading != null) ...[leading!, Gap.vertical.lg()],
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: Theme.of(
                    context,
                  ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                if (subtitle != null) ...[
                  Gap.vertical.xs(),
                  Text(
                    subtitle!,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
                if (action != null) ...[Gap.vertical.lg(), action!],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
