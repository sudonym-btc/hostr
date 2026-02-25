import 'package:flutter/material.dart';

/// De-emphasised helper text that adapts to light/dark mode and any surface.
///
/// Uses [ColorScheme.onSurfaceVariant] which Material 3 defines as the
/// correct colour for secondary/supporting text on any surface.
class HelpText extends StatelessWidget {
  final String text;

  const HelpText(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: Theme.of(context).textTheme.bodySmall!.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
