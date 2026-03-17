import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/logic/forms/upsert_form_controller.dart';
import 'package:hostr/presentation/component/widgets/ui/app_loading_indicator.dart';
import 'package:hostr/presentation/component/widgets/ui/padding.dart';

/// A standardised save button for forms backed by [UpsertFormController].
///
/// Renders as a bottom action bar with a right-aligned [FilledButton] that is
/// disabled when the form cannot submit or has no changes.
class SaveBottomBar extends StatelessWidget {
  final UpsertFormController controller;
  final VoidCallback onSave;

  const SaveBottomBar({
    super.key,
    required this.controller,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Material(
      color:
          theme.bottomAppBarTheme.color ?? theme.colorScheme.surfaceContainer,
      child: SafeArea(
        top: false,
        child: CustomPadding(
          top: 0,
          bottom: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ListenableBuilder(
                listenable: controller.submitListenable,
                builder: (context, _) {
                  return FilledButton(
                    onPressed: controller.canSubmit && controller.isDirty
                        ? onSave
                        : null,
                    child: controller.isSaving
                        ? const AppLoadingIndicator.small()
                        : Text(AppLocalizations.of(context)!.save),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
