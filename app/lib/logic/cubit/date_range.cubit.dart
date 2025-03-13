import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/presentation/forms/search/search.dart';

class DateRangeCubit extends Cubit<DateRangeState> {
  DateRangeCubit() : super(DateRangeState());

  void updateDateRange(DateTimeRange? dateRange) {
    emit(DateRangeState(ensureStartDateIsBeforeEndDate(dateRange)));
  }
}

class DateRangeState {
  final DateTimeRange? dateRange;

  DateRangeState([this.dateRange]);
}
