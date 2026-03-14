import 'package:flutter/material.dart';

import 'form_field_controller.dart';

export 'form_field_controller.dart';

/// Base class for form controllers that manage an upsert (create / update)
/// operation with one or more [FormFieldController] sub-controllers.
///
/// Register sub-controllers via [registerField]. The base class then
/// automatically computes [isDirty] and [canSubmit] by aggregating the
/// state of every registered field — no need to enumerate them manually.
///
/// A merged [Listenable] covering all registered fields is available as
/// [submitListenable], suitable for driving a save button's enabled state.
abstract class UpsertFormController extends ChangeNotifier {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _ready = true;

  final List<FormFieldController> _fields = [];
  final List<Listenable> _extraListenables = [];

  bool get isSaving => _saving;
  bool get isReady => _ready;

  void _handleDependencyChanged() {
    notifyListeners();
  }

  /// Whether at least one registered field has unsaved changes.
  bool get isDirty => _fields.any((f) => f.isDirty);

  /// Whether the form is ready to submit: not saving, all fields valid
  /// and ready, plus any subclass-specific conditions.
  bool get canSubmit =>
      !_saving && _ready && _fields.every((f) => f.isValid && f.canSubmit);

  /// A merged [Listenable] that fires whenever this controller, any
  /// registered field, or any extra listenable changes. Use this to
  /// rebuild a save button.
  late final Listenable submitListenable = Listenable.merge([
    this,
    ..._fields,
    ..._extraListenables,
  ]);

  /// Register a [FormFieldController] so its state is included in the
  /// aggregate [isDirty] / [canSubmit] checks.
  @protected
  void registerField(FormFieldController field) {
    _fields.add(field);
    field.addListener(_handleDependencyChanged);
  }

  /// Register an additional [Listenable] (e.g. a [ValueNotifier]) that
  /// should trigger [submitListenable] rebuilds but is not a full
  /// [FormFieldController].
  @protected
  void registerListenable(Listenable listenable) {
    _extraListenables.add(listenable);
    listenable.addListener(_handleDependencyChanged);
  }

  @protected
  void setReady(bool value) {
    if (_ready == value) return;
    _ready = value;
    notifyListeners();
  }

  @protected
  Future<void> preValidate() async {}

  @protected
  Future<void> upsert();

  Future<bool> save() async {
    if (!canSubmit) return false;
    _saving = true;
    notifyListeners();
    try {
      await preValidate();
      final formState = formKey.currentState;
      if (formState == null) return false;
      if (!formState.validate()) return false;
      await upsert();
      return true;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }

  @override
  void dispose() {
    for (final field in _fields) {
      field.removeListener(_handleDependencyChanged);
    }
    for (final listenable in _extraListenables) {
      listenable.removeListener(_handleDependencyChanged);
    }
    super.dispose();
  }
}
