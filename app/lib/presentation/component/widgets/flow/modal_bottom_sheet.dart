import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/presentation/component/main.dart';

enum ModalBottomSheetType { error, normal, success }

Future<T?> showAppModal<T>(
  BuildContext context, {
  required Widget child,
  bool isScrollControlled = true,
  bool useSafeArea = true,
  bool isDismissible = true,
}) => showModalBottomSheet<T>(
  context: context,
  isScrollControlled: isScrollControlled,
  useSafeArea: useSafeArea,
  isDismissible: isDismissible,
  builder: (_) => child,
);

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
                    Gap.vertical.custom(kSpace3),
                  ],
                  if (title != null)
                    Text(title!, style: Theme.of(context).textTheme.titleLarge),
                  if (subtitle != null) ...[
                    Gap.vertical.sm(),
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium,
                      textAlign: TextAlign.start,
                    ),
                  ],
                  Gap.vertical.md(),
                  content,
                  if (buttons != null) ...[
                    Gap.vertical.custom(kSpace5),
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
