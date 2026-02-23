import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/main.dart';

enum ModalBottomSheetType { error, normal, success }

class ModalBottomSheet extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget content;
  final Widget? buttons;
  final Widget? leading;
  final ModalBottomSheetType type;
  const ModalBottomSheet({
    super.key,
    this.title,
    this.subtitle,
    required this.content,
    this.type = ModalBottomSheetType.normal,
    this.buttons,
    this.leading,
  });

  ColorScheme _scheme(ColorScheme base) {
    switch (type) {
      case ModalBottomSheetType.normal:
        return base;
      case ModalBottomSheetType.success:
        return base.copyWith(
          surface: base.primaryContainer,
          onSurface: base.onPrimaryContainer,
        );
      case ModalBottomSheetType.error:
        return base.copyWith(
          surface: base.errorContainer,
          onSurface: base.onErrorContainer,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Theme(
      data: theme.copyWith(colorScheme: _scheme(theme.colorScheme)),
      child: Material(
        child: SizedBox(
          width: double.infinity,
          child: SafeArea(
            child: CustomPadding(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (leading != null) ...[
                    leading!,
                    const SizedBox(height: 12),
                  ],
                  if (title != null)
                    Text(title!, style: Theme.of(context).textTheme.titleLarge),
                  if (subtitle != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.start,
                    ),
                  ],
                  const SizedBox(height: 16),
                  content,
                  if (buttons != null) ...[
                    const SizedBox(height: 24),
                    buttons!,
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
