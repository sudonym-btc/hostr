import 'package:hostr/logic/forms/form_field_controller.dart';

/// A [FormFieldController] for an optional integer value (e.g. guest count).
class NullableIntFieldController extends FormFieldController {
  int? _value;
  int? _original;

  NullableIntFieldController({int? initial})
    : _value = initial,
      _original = initial;

  int? get value => _value;

  @override
  bool get isDirty => _value != _original;

  void setValue(int? v) {
    if (_value == v) return;
    _value = v;
    notifyListeners();
  }

  void setState(int? v) {
    _value = v;
    _original = v;
    notifyListeners();
  }
}
