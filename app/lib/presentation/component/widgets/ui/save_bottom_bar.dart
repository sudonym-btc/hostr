import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/logic/forms/upsert_form_controller.dart';
import 'package:hostr/presentation/component/widgets/ui/app_loading_indicator.dart';
import 'package:hostr/presentation/component/widgets/ui/future_button.dart';
import 'package:hostr/presentation/component/widgets/ui/padding.dart';
import 'package:hostr/presentation/layout/app_layout.dart';

/// A standardised save button for forms backed by [UpsertFormController].
///
/// Renders as a bottom action bar with a right-aligned [FilledButton] that is
/// disabled when the form cannot submit or has no changes.
class SaveBottomBar extends StatelessWidget {
  final UpsertFormController controller;
  final Future<void> Function() onSave;
  final Key? saveButtonKey;

  const SaveBottomBar({
    super.key,
    required this.controller,
    required this.onSave,
    this.saveButtonKey,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppSurface.of(context),
      child: SafeArea(
        top: false,
        child: CustomPadding(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ListenableBuilder(
                listenable: controller.submitListenable,
                builder: (context, _) {
                  return FutureButton.filled(
                    key: saveButtonKey,
                    onPressed: controller.canSubmit && controller.isDirty
                        ? onSave
                        : null,
                    child: controller.isSaving
                        ? AppLoadingIndicator.small(
                            color: Theme.of(context).colorScheme.onPrimary,
                          )
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
