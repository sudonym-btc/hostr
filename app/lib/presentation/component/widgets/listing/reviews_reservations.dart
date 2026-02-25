import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

class ReviewsReservationsWidget extends StatelessWidget {
  final Listing listing;

  /// Optional externally-provided review count stream.
  /// When supplied the widget skips creating its own [CountCubit] for reviews.
  final Stream<int>? reviewCount;

  /// Optional externally-provided reservation/stays count stream.
  /// When supplied the widget skips creating its own [CountCubit] for stays.
  final Stream<int>? reservationCount;

  const ReviewsReservationsWidget({
    super.key,
    required this.listing,
    this.reviewCount,
    this.reservationCount,
  });

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
          if (reviewCount != null)
            _ExternalCountSegment(noun: 'reviews', countStream: reviewCount!)
          else
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
          if (reservationCount != null)
            _ExternalCountSegment(noun: 'stays', countStream: reservationCount!)
          else
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

/// Renders a count segment driven by an externally-provided [Stream<int>].
class _ExternalCountSegment extends StatefulWidget {
  final String noun;
  final Stream<int> countStream;

  const _ExternalCountSegment({required this.noun, required this.countStream});

  @override
  State<_ExternalCountSegment> createState() => _ExternalCountSegmentState();
}

class _ExternalCountSegmentState extends State<_ExternalCountSegment> {
  late final StreamSubscription<int> _sub;
  int? _count;

  @override
  void initState() {
    super.initState();
    _sub = widget.countStream.listen((c) {
      if (mounted) setState(() => _count = c);
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _CountSegment(
      noun: widget.noun,
      count: _count ?? 0,
      loading: _count == null,
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
      duration: kAnimationDuration,
      switchInCurve: kAnimationCurve,
      switchOutCurve: kAnimationCurve,
      child: loading
          ? Row(
              key: ValueKey('loading-$noun'),
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLoadingIndicator.small(),
                Gap.horizontal.custom(6),
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
