import 'package:flutter/material.dart';

import 'location_controller.dart';
import 'search_form_state.dart';

class SearchFormController extends ChangeNotifier {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final LocationController locationController;

  SearchFormState _state = const SearchFormState();

  SearchFormController({LocationController? locationController})
    : locationController = locationController ?? LocationController() {
    this.locationController.addListener(_onLocationChanged);
  }

  SearchFormState get state => _state;

  bool get canSubmit => locationController.canSubmit;

  SearchFormState buildSubmitState() {
    return _state.copyWith(
      location: locationController.text,
      h3Tags: locationController.h3Tags,
    );
  }

  bool validate() {
    return formKey.currentState?.validate() ?? false;
  }

  void updateAvailabilityRange(DateTimeRange? range) {
    _state = _state.copyWith(
      availabilityRange: ensureStartDateIsBeforeEndDate(range),
    );
    notifyListeners();
  }

  void _onLocationChanged() {
    notifyListeners();
  }

  @override
  void dispose() {
    locationController.removeListener(_onLocationChanged);
    locationController.dispose();
    super.dispose();
  }
}
