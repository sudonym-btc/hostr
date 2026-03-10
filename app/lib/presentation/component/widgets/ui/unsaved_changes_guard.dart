import 'package:flutter/material.dart';

/// Shows a confirmation dialog when the user tries to navigate away from
/// a form with unsaved changes.
///
/// Returns `true` if the user chose to discard, `false` or `null` otherwise.
Future<bool> showUnsavedChangesDialog(BuildContext context) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: const Text('Unsaved changes'),
      content: const Text('You have unsaved changes. Discard them and leave?'),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(MaterialLocalizations.of(context).cancelButtonLabel),
        ),
        TextButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: const Text('Discard'),
        ),
      ],
    ),
  );
  return result ?? false;
}

/// A [PopScope] wrapper that guards navigation when a form has unsaved
/// changes. Uses [isDirty] (evaluated at pop-time) to decide whether to
/// show a confirmation dialog.
class UnsavedChangesGuard extends StatelessWidget {
  final bool Function() isDirty;
  final Widget child;

  const UnsavedChangesGuard({
    super.key,
    required this.isDirty,
    required this.child,
  });

  Future<void> _onPopInvoked(
    BuildContext context,
    bool didPop,
    dynamic result,
  ) async {
    if (didPop) return;
    if (!isDirty()) {
      if (context.mounted) Navigator.of(context).pop();
      return;
    }
    final shouldLeave = await showUnsavedChangesDialog(context);
    if (shouldLeave && context.mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) =>
          _onPopInvoked(context, didPop, result),
      child: child,
    );
  }
}
