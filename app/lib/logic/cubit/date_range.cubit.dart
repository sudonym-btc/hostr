import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class DateRangeCubit extends Cubit<DateRangeState> {
  DateRangeCubit() : super(DateRangeState());

  void updateDateRange(DateTimeRange dateRange) {
    emit(DateRangeState(dateRange));
  }
}

class DateRangeState {
  final DateTimeRange? dateRange;

  DateRangeState([this.dateRange]);
}
