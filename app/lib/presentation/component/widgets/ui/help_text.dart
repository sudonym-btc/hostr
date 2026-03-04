import 'package:flutter/material.dart';

/// De-emphasised helper text that adapts to light/dark mode and any surface.
///
/// Uses [ColorScheme.onSurfaceVariant] which Material 3 defines as the
/// correct colour for secondary/supporting text on any surface.
class HelpText extends StatelessWidget {
  final String text;
  final TextOverflow? overflow;
  final int? maxLines;

  const HelpText(this.text, {super.key, this.overflow, this.maxLines});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      overflow: overflow,
      maxLines: maxLines,
      style: Theme.of(context).textTheme.bodySmall!.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}
