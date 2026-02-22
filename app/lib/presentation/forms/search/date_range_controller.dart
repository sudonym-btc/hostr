import 'package:flutter/material.dart';

import 'search_form_state.dart';

/// A reusable controller for a check-in / check-out date range field.
///
/// Follows the same pattern as [LocationController] so it can be shared
/// between the search filters form and the reservation widget.
class DateRangeController extends ChangeNotifier {
  DateTimeRange? _dateRange;

  DateRangeController({DateTimeRange? initialDateRange})
    : _dateRange = initialDateRange;

  /// The currently selected date range, or `null` if none.
  DateTimeRange? get dateRange => _dateRange;

  /// Whether a date range has been selected.
  bool get hasValue => _dateRange != null;

  /// Update the selected range (normalises start < end).
  void update(DateTimeRange? range) {
    _dateRange = ensureStartDateIsBeforeEndDate(range);
    notifyListeners();
  }

  /// Clear the selection.
  void clear() {
    if (_dateRange == null) return;
    _dateRange = null;
    notifyListeners();
  }

  /// Show the platform date-range picker and update the value.
  ///
  /// Accepts optional [selectableDayPredicate] for availability filtering
  /// (used by the reserve widget with reservation data).
  Future<void> pick(
    BuildContext context, {
    bool Function(DateTime day, DateTime? start, DateTime? end)?
    selectableDayPredicate,
  }) async {
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: _dateRange,
      selectableDayPredicate:
          selectableDayPredicate ??
          (day, start, end) => day.isAfter(DateTime.now()),
    );
    if (picked != null) {
      update(picked);
    }
  }
}
