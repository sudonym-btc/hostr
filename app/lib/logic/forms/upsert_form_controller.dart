import 'package:flutter/material.dart';

abstract class UpsertFormController {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  bool _saving = false;

  @protected
  Future<void> preValidate() async {}

  @protected
  Future<void> upsert();

  Future<bool> save() async {
    if (_saving) return false;
    _saving = true;
    try {
      await preValidate();
      final formState = formKey.currentState;
      if (formState == null) return false;
      if (!formState.validate()) return false;
      await upsert();
      return true;
    } finally {
      _saving = false;
    }
  }
}
