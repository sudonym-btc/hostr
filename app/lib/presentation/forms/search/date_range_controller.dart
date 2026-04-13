import 'package:flutter/material.dart';
import 'package:hostr/logic/forms/form_field_controller.dart';
import 'package:hostr/presentation/layout/app_layout.dart';
import 'package:models/main.dart';

DateTimeRange? _normalizeDateRange(DateTimeRange? range) {
  if (range == null) return null;
  final normalized = normalizeOrderedDateBounds(range.start, range.end);
  return DateTimeRange(start: normalized.start, end: normalized.end);
}

Future<DateTimeRange?> showResponsiveDateRangePicker({
  required BuildContext context,
  required DateTime firstDate,
  required DateTime lastDate,
  DateTimeRange? initialDateRange,
  bool Function(DateTime day, DateTime? start, DateTime? end)?
  selectableDayPredicate,
}) {
  return showDateRangePicker(
    context: context,
    builder: (context, child) {
      final mediaQuery = MediaQuery.of(context);
      final normalizedChild = MediaQuery(
        data: mediaQuery.copyWith(
          padding: mediaQuery.padding.copyWith(bottom: 0),
        ),
        child: child!,
      );

      if (!AppLayoutSpec.of(context).showsSidebarNavigation) {
        return normalizedChild;
      }

      return Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360, maxHeight: 720),
          child: normalizedChild,
        ),
      );
    },
    firstDate: firstDate,
    lastDate: lastDate,
    initialDateRange: initialDateRange,
    selectableDayPredicate: selectableDayPredicate,
  );
}

/// A reusable controller for a check-in / check-out date range field.
///
/// Extends [FormFieldController] so it can participate in aggregate
/// dirty / valid / canSubmit tracking via [UpsertFormController].
class DateRangeController extends FormFieldController {
  DateTimeRange? _dateRange;
  DateTimeRange? _original;

  DateRangeController({DateTimeRange? initialDateRange})
    : _dateRange = _normalizeDateRange(initialDateRange),
      _original = _normalizeDateRange(initialDateRange);

  /// The currently selected date range, or `null` if none.
  DateTimeRange? get dateRange => _dateRange;

  /// Whether a date range has been selected.
  bool get hasValue => _dateRange != null;

  @override
  bool get isDirty => _dateRange != _original;

  /// Update the selected range (normalises start < end).
  void update(DateTimeRange? range) {
    _dateRange = _normalizeDateRange(range);
    notifyListeners();
  }

  /// Set initial/reset state. After this call [isDirty] is `false`.
  void setState(DateTimeRange? range) {
    _dateRange = _normalizeDateRange(range);
    _original = _dateRange;
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
    final picked = await showResponsiveDateRangePicker(
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
