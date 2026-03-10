import 'package:hostr/logic/forms/form_field_controller.dart';
import 'package:models/main.dart';

/// Manages the amenities selection state for a listing form.
class ListingAmenityFieldController extends FormFieldController {
  Amenities _amenities = Amenities();
  Set<String> _selectedKeys = {};
  Set<String> _originalKeys = {};

  Amenities get amenities => _amenities;
  Set<String> get selectedKeys => _selectedKeys;

  @override
  bool get isDirty {
    if (_selectedKeys.length != _originalKeys.length) return true;
    return !_selectedKeys.containsAll(_originalKeys);
  }

  /// Returns the list of known boolean amenity keys, sorted.
  static List<String> amenityKeys() {
    final map = Amenities().toMap();
    final keys = map.entries
        .where((entry) => entry.value is bool)
        .map((entry) => entry.key)
        .toList();
    keys.sort();
    return keys;
  }

  void setState(Amenities amenities) {
    _amenities = amenities;
    _selectedKeys = _selectedKeysFromAmenities(amenities);
    _originalKeys = Set<String>.from(_selectedKeys);
    notifyListeners();
  }

  void updateSelected(Set<String> keys) {
    _selectedKeys = keys;
    _amenities = _amenitiesFromKeys(_amenities, keys);
    notifyListeners();
  }

  Set<String> _selectedKeysFromAmenities(Amenities value) {
    final map = value.toMap();
    return map.entries
        .where((entry) => entry.value is bool && entry.value == true)
        .map((entry) => entry.key)
        .toSet();
  }

  Amenities _amenitiesFromKeys(Amenities base, Set<String> keys) {
    final map = base.toMap();
    for (final entry in map.entries) {
      if (entry.value is bool) {
        map[entry.key] = keys.contains(entry.key);
      }
    }
    return Amenities.fromJSON(map);
  }
}
