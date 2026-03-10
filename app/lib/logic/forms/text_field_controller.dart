import 'package:flutter/material.dart';
import 'package:hostr/logic/forms/form_field_controller.dart';

/// A [FormFieldController] wrapping a single [TextEditingController].
///
/// Tracks dirty state by comparing the current text to the initial value
/// set via [setState].
class TextFieldController extends FormFieldController {
  final TextEditingController textController = TextEditingController();
  final String? Function(String?)? validator;
  String _original = '';

  TextFieldController({this.validator}) {
    textController.addListener(notifyListeners);
  }

  String get text => textController.text;
  set text(String value) => textController.text = value;

  @override
  bool get isDirty => textController.text != _original;

  @override
  bool get isValid =>
      validator == null || validator!(textController.text) == null;

  void setState(String value) {
    textController.text = value;
    _original = value;
    notifyListeners();
  }

  String? validate(String? value) => validator?.call(value);

  @override
  void dispose() {
    textController.removeListener(notifyListeners);
    textController.dispose();
    super.dispose();
  }
}
