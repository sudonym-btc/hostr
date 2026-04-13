import 'package:hostr/logic/forms/form_field_controller.dart';

/// A [FormFieldController] for an optional enum value (e.g. listing type).
class EnumFieldController<T extends Enum> extends FormFieldController {
  T? _value;
  T? _original;

  EnumFieldController({T? initial}) : _value = initial, _original = initial;

  T? get value => _value;

  @override
  bool get isDirty => _value != _original;

  void setValue(T? v) {
    if (_value == v) return;
    _value = v;
    notifyListeners();
  }

  void setState(T? v) {
    _value = v;
    _original = v;
    notifyListeners();
  }
}
