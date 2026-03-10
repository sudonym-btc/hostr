import 'package:flutter/foundation.dart';

/// Base class for individual form field controllers that can be registered
/// with an [UpsertFormController].
///
/// Each field controller tracks its own [isDirty] and [isValid] state,
/// allowing the parent form to compute aggregate `isDirty` / `canSubmit`
/// automatically without enumerating fields manually.
abstract class FormFieldController extends ChangeNotifier {
  /// Whether this field has been modified from its initial/reset state.
  bool get isDirty;

  /// Whether this field's current value is valid for submission.
  /// Defaults to `true` — override for fields with validation.
  bool get isValid => true;

  /// Whether this field is ready for submission (e.g. not uploading).
  /// Defaults to `true` — override for async fields like image uploads.
  bool get canSubmit => true;
}
