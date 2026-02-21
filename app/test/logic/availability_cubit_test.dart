import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hostr/logic/cubit/availability.cubit.dart';
import 'package:hostr/logic/cubit/date_range.cubit.dart';
import 'package:models/main.dart';

Reservation _reservation({required DateTime start, required DateTime end}) {
  return Reservation(
    pubKey: 'host-pubkey',
    tags: ReservationTags([
      [kListingRefTag, 'listing-anchor'],
    ]),
    content: ReservationContent(start: start, end: end),
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
          reservations: [
            _reservation(
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
          reservations: [
            _reservation(
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
  });
}
