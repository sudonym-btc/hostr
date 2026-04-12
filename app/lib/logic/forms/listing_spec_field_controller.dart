import 'package:hostr/logic/forms/form_field_controller.dart';
import 'package:models/main.dart';

/// Manages the specifications selection state for a listing form.
///
/// Handles both boolean specs (pool, wifi…) and valued specs
/// (bedrooms, beds, bathrooms…).
class ListingSpecFieldController extends FormFieldController {
  Specifications _specifications = Specifications();
  Set<String> _selectedBoolKeys = {};
  Set<String> _originalBoolKeys = {};
  Map<String, int> _valuedSpecs = {};
  Map<String, int> _originalValuedSpecs = {};

  Specifications get specifications => _specifications;
  Set<String> get selectedBoolKeys => _selectedBoolKeys;
  Map<String, int> get valuedSpecs => Map.unmodifiable(_valuedSpecs);

  @override
  bool get isDirty {
    if (_selectedBoolKeys.length != _originalBoolKeys.length) return true;
    if (!_selectedBoolKeys.containsAll(_originalBoolKeys)) return true;
    if (_valuedSpecs.length != _originalValuedSpecs.length) return true;
    for (final entry in _valuedSpecs.entries) {
      if (_originalValuedSpecs[entry.key] != entry.value) return true;
    }
    return false;
  }

  /// Returns the list of known boolean spec keys, sorted.
  static List<String> booleanSpecKeys() {
    final map = Specifications().toMap();
    final keys = map.entries
        .where((entry) => entry.value is bool)
        .map((entry) => entry.key)
        .toList();
    keys.sort();
    return keys;
  }

  /// Returns the list of known valued spec keys, sorted.
  static List<String> valuedSpecKeys() {
    final map = Specifications().toMap();
    final keys = map.entries
        .where((entry) => entry.value is int)
        .map((entry) => entry.key)
        .toList();
    keys.sort();
    return keys;
  }

  void setState(Specifications specs) {
    _specifications = specs;
    _selectedBoolKeys = _boolKeysFromSpecs(specs);
    _originalBoolKeys = Set<String>.from(_selectedBoolKeys);
    _valuedSpecs = _valuedFromSpecs(specs);
    _originalValuedSpecs = Map<String, int>.from(_valuedSpecs);
    notifyListeners();
  }

  void updateSelectedBool(Set<String> keys) {
    _selectedBoolKeys = keys;
    _specifications = _buildSpecifications();
    notifyListeners();
  }

  void updateValuedSpec(String key, int value) {
    if (value <= 0) {
      _valuedSpecs.remove(key);
    } else {
      _valuedSpecs[key] = value;
    }
    _specifications = _buildSpecifications();
    notifyListeners();
  }

  Set<String> _boolKeysFromSpecs(Specifications value) {
    final map = value.toMap();
    return map.entries
        .where((entry) => entry.value is bool && entry.value == true)
        .map((entry) => entry.key)
        .toSet();
  }

  Map<String, int> _valuedFromSpecs(Specifications value) {
    final map = value.toMap();
    final result = <String, int>{};
    for (final entry in map.entries) {
      if (entry.value is int && (entry.value as int) > 0) {
        result[entry.key] = entry.value as int;
      }
    }
    return result;
  }

  Specifications _buildSpecifications() {
    final map = Specifications().toMap();
    // Apply boolean selections
    for (final entry in map.entries) {
      if (entry.value is bool) {
        map[entry.key] = _selectedBoolKeys.contains(entry.key);
      }
    }
    // Apply valued specs
    for (final entry in _valuedSpecs.entries) {
      map[entry.key] = entry.value;
    }
    return Specifications.fromJSON(map);
  }
}
