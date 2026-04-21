import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/presentation/component/main.dart';
import 'package:hostr/presentation/layout/app_layout.dart';

enum ModalBottomSheetType { error, normal, success }

class ModalBottomSheetPrimaryButton extends StatelessWidget {
  final VoidCallback? onPressed;
  final Widget child;
  final ButtonStyle? style;

  const ModalBottomSheetPrimaryButton({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    final baseStyle = style ?? AppButtonStyles.primary(context);

    return SizedBox(
      width: double.infinity,
      child: FilledButton(
        onPressed: onPressed,
        style: baseStyle.merge(
          FilledButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
        child: child,
      ),
    );
  }
}

Future<T?> showAppModal<T>(
  BuildContext context, {
  required WidgetBuilder builder,
  bool isScrollControlled = true,
  bool useSafeArea = true,
  bool isDismissible = true,
  bool useRootNavigator = true,
}) {
  final surfaceColor = _modalSurfaceColor(
    context,
    useRootNavigator: useRootNavigator,
  );

  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: isScrollControlled,
    useSafeArea: useSafeArea,
    isDismissible: isDismissible,
    useRootNavigator: useRootNavigator,
    backgroundColor: surfaceColor,
    shape: AppShapes.modalSheet,
    clipBehavior: Clip.antiAlias,
    builder: (sheetContext) {
      return AppSurface.inherit(
        color: surfaceColor,
        child: builder(sheetContext),
      );
    },
  );
}

Color _modalSurfaceColor(
  BuildContext context, {
  required bool useRootNavigator,
}) {
  if (!useRootNavigator) {
    final inheritedSurface = AppSurface.maybeOf(context);
    if (inheritedSurface != null) return inheritedSurface;
  }

  final theme = Theme.of(context);
  return theme.bottomSheetTheme.modalBackgroundColor ??
      theme.bottomSheetTheme.backgroundColor ??
      theme.scaffoldBackgroundColor;
}

class ModalBottomSheet extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? content;
  final Widget? buttons;
  final Widget? leading;
  final ModalBottomSheetType type;
  final bool expandToMaxHeight;
  const ModalBottomSheet({
    super.key,
    this.title,
    this.subtitle,
    this.content,
    this.type = ModalBottomSheetType.normal,
    this.buttons,
    this.leading,
    this.expandToMaxHeight = false,
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
      child: _ScrollableModalViewport(
        title: title,
        subtitle: subtitle,
        content: content,
        buttons: buttons,
        leading: leading,
        expandToMaxHeight: expandToMaxHeight,
      ),
    );
  }
}

class _ScrollableModalViewport extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? content;
  final Widget? buttons;
  final Widget? leading;
  final bool expandToMaxHeight;

  const _ScrollableModalViewport({
    this.title,
    this.subtitle,
    this.content,
    this.buttons,
    this.leading,
    required this.expandToMaxHeight,
  });

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final fallbackMaxHeight = MediaQuery.sizeOf(context).height * 0.9;
          final maxHeight = constraints.hasBoundedHeight
              ? constraints.maxHeight
              : fallbackMaxHeight;

          return SizedBox(
            width: double.infinity,
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxHeight),
              child: expandToMaxHeight
                  ? _FixedActionModalLayout(
                      title: title,
                      subtitle: subtitle,
                      content: content,
                      buttons: buttons,
                      leading: leading,
                    )
                  : _ScrollableModalLayout(
                      title: title,
                      subtitle: subtitle,
                      content: content,
                      buttons: buttons,
                      leading: leading,
                    ),
            ),
          );
        },
      ),
    );
  }
}

class _ScrollableModalLayout extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? content;
  final Widget? buttons;
  final Widget? leading;

  const _ScrollableModalLayout({
    this.title,
    this.subtitle,
    this.content,
    this.buttons,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
      child: CustomPadding(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (leading != null) ...[leading!, Gap.vertical.custom(kSpace3)],
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
            if (title != null && subtitle != null) Gap.vertical.md(),
            ?content,
            if (buttons != null) ...[Gap.vertical.custom(kSpace5), buttons!],
          ],
        ),
      ),
    );
  }
}

class _FixedActionModalLayout extends StatelessWidget {
  final String? title;
  final String? subtitle;
  final Widget? content;
  final Widget? buttons;
  final Widget? leading;

  const _FixedActionModalLayout({
    this.title,
    this.subtitle,
    this.content,
    this.buttons,
    this.leading,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[leading!, Gap.vertical.custom(kSpace3)],
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
          if (title != null && subtitle != null) Gap.vertical.md(),
          Expanded(
            child: SingleChildScrollView(
              keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
              child: content ?? const SizedBox.shrink(),
            ),
          ),
          if (buttons != null) ...[Gap.vertical.custom(kSpace5), buttons!],
        ],
      ),
    );
  }
}
