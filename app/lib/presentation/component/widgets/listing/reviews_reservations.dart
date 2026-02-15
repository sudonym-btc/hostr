import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

class ReviewsReservationsWidget extends StatelessWidget {
  final Listing listing;
  const ReviewsReservationsWidget({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => FilterCubit()
        ..updateFilter(
          Filter(
            tags: {
              kListingRefTag: [listing.anchor!],
            },
          ),
        ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          BlocProvider(
            create: (context) => CountCubit(
              kinds: Review.kinds,
              nostrService: getIt(),
              filterCubit: context.read<FilterCubit>(),
            )..count(),
            child: BlocBuilder<CountCubit, CountCubitState>(
              builder: (context, state) {
                return _CountSegment(
                  noun: 'reviews',
                  count: state.count ?? 0,
                  loading: state is CountCubitStateLoading,
                );
              },
            ),
          ),
          const Text(' · '),
          BlocProvider(
            create: (context) => CountCubit(
              kinds: Reservation.kinds,
              nostrService: getIt(),
              filterCubit: context.read<FilterCubit>(),
            )..count(),
            child: BlocBuilder<CountCubit, CountCubitState>(
              builder: (context, state) {
                return _CountSegment(
                  noun: 'stays',
                  count: state.count ?? 0,
                  loading: state is CountCubitStateLoading,
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _CountSegment extends StatelessWidget {
  final String noun;
  final int count;
  final bool loading;

  const _CountSegment({
    required this.noun,
    required this.count,
    required this.loading,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: loading
          ? Row(
              key: ValueKey('loading-$noun'),
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(
                  width: 10,
                  height: 10,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                const SizedBox(width: 6),
                Text(noun),
              ],
            )
          : Text(
              '$count $noun',
              key: ValueKey('loaded-$noun-$count'),
              overflow: TextOverflow.ellipsis,
            ),
    );
  }
}
