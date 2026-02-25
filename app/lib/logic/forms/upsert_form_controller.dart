import 'package:flutter/material.dart';

abstract class UpsertFormController extends ChangeNotifier {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool _saving = false;
  bool _ready = true;

  bool get isSaving => _saving;
  bool get isReady => _ready;
  bool get canSubmit => !_saving && _ready;

  /// Whether the form has unsaved changes compared to its initial state.
  bool get isDirty;

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
}
