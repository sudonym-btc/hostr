import 'package:flutter/material.dart';

import 'date_range_controller.dart';
import 'location_controller.dart';
import 'search_form_state.dart';

class SearchFormController extends ChangeNotifier {
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();
  final LocationController locationController;
  final DateRangeController dateRangeController;

  SearchFormState _state = const SearchFormState();

  SearchFormController({
    LocationController? locationController,
    DateRangeController? dateRangeController,
  }) : locationController = locationController ?? LocationController(),
       dateRangeController = dateRangeController ?? DateRangeController() {
    this.locationController.addListener(_onChildChanged);
    this.dateRangeController.addListener(_onDateRangeChanged);
  }

  SearchFormState get state => _state;

  bool get canSubmit =>
      locationController.canSubmit || dateRangeController.hasValue;

  SearchFormState buildSubmitState() {
    return _state.copyWith(
      location: locationController.text,
      h3Tags: locationController.h3Tags,
      availabilityRange: dateRangeController.dateRange,
    );
  }

  bool validate() {
    return formKey.currentState?.validate() ?? false;
  }

  void updateAvailabilityRange(DateTimeRange? range) {
    dateRangeController.update(range);
  }

  void _onDateRangeChanged() {
    _state = _state.copyWith(availabilityRange: dateRangeController.dateRange);
    notifyListeners();
  }

  void _onChildChanged() {
    notifyListeners();
  }

  /// Clear all fields.
  void clearAll() {
    locationController.clearAll();
    dateRangeController.clear();
  }

  @override
  void dispose() {
    locationController.removeListener(_onChildChanged);
    dateRangeController.removeListener(_onDateRangeChanged);
    locationController.dispose();
    dateRangeController.dispose();
    super.dispose();
  }
}
