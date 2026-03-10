import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/main.dart';

DateTimeRange? _normalizeDateRange(DateTimeRange? range) {
  if (range == null) return null;
  final normalized = normalizeOrderedDateBounds(range.start, range.end);
  return DateTimeRange(start: normalized.start, end: normalized.end);
}

class DateRangeCubit extends Cubit<DateRangeState> {
  DateRangeCubit() : super(DateRangeState());

  void updateDateRange(DateTimeRange? dateRange) {
    emit(DateRangeState(_normalizeDateRange(dateRange)));
  }
}

class DateRangeState {
  final DateTimeRange? dateRange;

  DateRangeState([this.dateRange]);
}
