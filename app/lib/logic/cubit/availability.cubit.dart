import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:models/main.dart';

import 'date_range.cubit.dart';

sealed class AvailabilityCubitState {}

class AvailabilityLoading extends AvailabilityCubitState {}

class AvailabilityAvailable extends AvailabilityCubitState {}

class AvailabilityUnavailable extends AvailabilityCubitState {
  final String reason;

  AvailabilityUnavailable(this.reason);
}

class AvailabilityCubit extends Cubit<AvailabilityCubitState> {
  final DateRangeCubit dateRangeCubit;
  late final StreamSubscription<DateRangeState> _dateRangeSubscription;

  List<ReservationPairStatus> _reservationPairs;

  AvailabilityCubit({
    required this.dateRangeCubit,
    List<ReservationPairStatus> reservationPairs = const [],
  }) : _reservationPairs = List<ReservationPairStatus>.from(reservationPairs),
       super(AvailabilityLoading()) {
    _dateRangeSubscription = dateRangeCubit.stream.listen((_) => refresh());
    refresh();
  }

  void updateReservationPairs(List<ReservationPairStatus> reservationPairs) {
    _reservationPairs = List<ReservationPairStatus>.from(reservationPairs);
    refresh();
  }

  void refresh() {
    emit(AvailabilityLoading());

    final selectedRange = dateRangeCubit.state.dateRange;
    if (selectedRange == null) {
      emit(AvailabilityUnavailable('Please select check-in and check-out'));
      return;
    }

    final available = Listing.isAvailable(
      selectedRange.start,
      selectedRange.end,
      _reservationPairs,
    );

    emit(
      available
          ? AvailabilityAvailable()
          : AvailabilityUnavailable('Selected dates are unavailable'),
    );
  }

  @override
  Future<void> close() async {
    await _dateRangeSubscription.cancel();
    return super.close();
  }
}
