import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostr/logic/cubit/availability.cubit.dart';
import 'package:hostr/logic/cubit/date_range.cubit.dart';
import 'package:models/main.dart';

ReservationGroup _reservationGroup({
  required DateTime start,
  required DateTime end,
  ReservationStage stage = ReservationStage.commit,
}) {
  final hostKey = 'host-pubkey';
  return ReservationGroup(
    reservations: [
      Reservation.create(
        pubKey: hostKey,
        dTag: 'test-reservation',
        listingAnchor: '30402:$hostKey:test-listing',
        start: start,
        end: end,
        stage: stage,
      ),
    ],
  );
}

void main() {
  group('AvailabilityCubit', () {
    late DateRangeCubit dateRangeCubit;

    setUp(() {
      dateRangeCubit = DateRangeCubit();
    });

    tearDown(() async {
      await dateRangeCubit.close();
    });

    blocTest<AvailabilityCubit, AvailabilityCubitState>(
      'emits Loading -> Unavailable when no date range selected',
      build: () => AvailabilityCubit(dateRangeCubit: dateRangeCubit),
      act: (cubit) => cubit.refresh(),
      expect: () => [
        isA<AvailabilityLoading>(),
        isA<AvailabilityUnavailable>(),
      ],
    );

    blocTest<AvailabilityCubit, AvailabilityCubitState>(
      'emits Loading -> Available when selected range has no overlap',
      build: () {
        dateRangeCubit.updateDateRange(
          DateTimeRange(start: DateTime(2026, 2, 1), end: DateTime(2026, 2, 3)),
        );
        return AvailabilityCubit(
          dateRangeCubit: dateRangeCubit,
          reservationGroups: [
            _reservationGroup(
              start: DateTime(2026, 2, 10),
              end: DateTime(2026, 2, 12),
            ),
          ],
        );
      },
      act: (cubit) => cubit.refresh(),
      expect: () => [isA<AvailabilityLoading>(), isA<AvailabilityAvailable>()],
    );

    blocTest<AvailabilityCubit, AvailabilityCubitState>(
      'emits Loading -> Unavailable when selected range overlaps reservation',
      build: () {
        dateRangeCubit.updateDateRange(
          DateTimeRange(start: DateTime(2026, 2, 1), end: DateTime(2026, 2, 3)),
        );
        return AvailabilityCubit(
          dateRangeCubit: dateRangeCubit,
          reservationGroups: [
            _reservationGroup(
              start: DateTime(2026, 2, 2),
              end: DateTime(2026, 2, 4),
            ),
          ],
        );
      },
      act: (cubit) => cubit.refresh(),
      expect: () => [
        isA<AvailabilityLoading>(),
        isA<AvailabilityUnavailable>(),
      ],
    );

    blocTest<AvailabilityCubit, AvailabilityCubitState>(
      'emits Loading -> Available when selected range only overlaps negotiation',
      build: () {
        dateRangeCubit.updateDateRange(
          DateTimeRange(start: DateTime(2026, 2, 1), end: DateTime(2026, 2, 3)),
        );
        return AvailabilityCubit(
          dateRangeCubit: dateRangeCubit,
          reservationGroups: [
            _reservationGroup(
              start: DateTime(2026, 2, 2),
              end: DateTime(2026, 2, 4),
              stage: ReservationStage.negotiate,
            ),
          ],
        );
      },
      act: (cubit) => cubit.refresh(),
      expect: () => [isA<AvailabilityLoading>(), isA<AvailabilityAvailable>()],
    );
  });
}
