import 'package:hostr/logic/forms/form_field_controller.dart';

/// A [FormFieldController] for a single boolean toggle (switch).
class BoolFieldController extends FormFieldController {
  bool _value;
  bool _original;

  BoolFieldController({bool initial = false})
    : _value = initial,
      _original = initial;

  bool get value => _value;

  @override
  bool get isDirty => _value != _original;

  void setValue(bool v) {
    if (_value == v) return;
    _value = v;
    notifyListeners();
  }

  void setState(bool v) {
    _value = v;
    _original = v;
    notifyListeners();
  }
}
