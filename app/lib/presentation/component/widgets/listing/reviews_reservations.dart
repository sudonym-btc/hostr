import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/listing/star_rating.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';

class ReviewsReservationsWidget extends StatelessWidget {
  /// Optional externally-provided review count stream.
  /// When supplied the widget skips creating its own [CountCubit] for reviews.
  final Stream<int> reviewCount;

  /// Average rating across all reviews.
  final Stream<double> averageReviewRating;

  /// Optional externally-provided reservation/stays count stream.
  /// When supplied the widget skips creating its own [CountCubit] for stays.
  final Stream<int> reservationCount;

  const ReviewsReservationsWidget({
    super.key,
    required this.reviewCount,
    required this.averageReviewRating,
    required this.reservationCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ExternalReviewSegment(
          countStream: reviewCount,
          averageRatingStream: averageReviewRating,
          loadingLabel: l10n.reviewsLabel,
          countLabelBuilder: l10n.reviewCount,
          segmentKey: 'reviews',
        ),
        Text(
          ' · ',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        _ExternalCountSegment(
          countStream: reservationCount,
          loadingLabel: l10n.staysLabel,
          countLabelBuilder: l10n.stayCount,
          segmentKey: 'stays',
        ),
      ],
    );
  }
}

class _ExternalReviewSegment extends StatefulWidget {
  final Stream<int> countStream;
  final Stream<double> averageRatingStream;
  final String loadingLabel;
  final String Function(int count) countLabelBuilder;
  final String segmentKey;

  const _ExternalReviewSegment({
    required this.countStream,
    required this.averageRatingStream,
    required this.loadingLabel,
    required this.countLabelBuilder,
    required this.segmentKey,
  });

  @override
  State<_ExternalReviewSegment> createState() => _ExternalReviewSegmentState();
}

class _ExternalReviewSegmentState extends State<_ExternalReviewSegment> {
  late final StreamSubscription<int> _sub;
  late final StreamSubscription<double> _averageSub;
  int? _count;
  double? _averageRating;

  @override
  void initState() {
    super.initState();
    _sub = widget.countStream.listen((c) {
      if (mounted) setState(() => _count = c);
    });
    _averageSub = widget.averageRatingStream.listen((rating) {
      if (mounted) setState(() => _averageRating = rating);
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    _averageSub.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _ReviewSegment(
      count: _count ?? 0,
      averageRating: _averageRating ?? 0,
      loading: _count == null || _averageRating == null,
      loadingLabel: widget.loadingLabel,
      countLabelBuilder: widget.countLabelBuilder,
      segmentKey: widget.segmentKey,
    );
  }
}

/// Renders a count segment driven by an externally-provided [Stream<int>].
class _ExternalCountSegment extends StatefulWidget {
  final Stream<int> countStream;
  final String loadingLabel;
  final String Function(int count) countLabelBuilder;
  final String segmentKey;

  const _ExternalCountSegment({
    required this.countStream,
    required this.loadingLabel,
    required this.countLabelBuilder,
    required this.segmentKey,
  });

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
      count: _count ?? 0,
      loading: _count == null,
      loadingLabel: widget.loadingLabel,
      countLabelBuilder: widget.countLabelBuilder,
      segmentKey: widget.segmentKey,
    );
  }
}

class _ReviewSegment extends StatelessWidget {
  final int count;
  final double averageRating;
  final bool loading;
  final String loadingLabel;
  final String Function(int count) countLabelBuilder;
  final String segmentKey;

  const _ReviewSegment({
    required this.count,
    required this.averageRating,
    required this.loading,
    required this.loadingLabel,
    required this.countLabelBuilder,
    required this.segmentKey,
  });

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(
      color: Theme.of(context).colorScheme.onSurfaceVariant,
    );

    return AnimatedSwitcher(
      duration: kAnimationDuration,
      switchInCurve: kAnimationCurve,
      switchOutCurve: kAnimationCurve,
      child: loading
          ? Row(
              key: ValueKey('loading-$segmentKey'),
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLoadingIndicator.small(),
                Gap.horizontal.custom(6),
                Text(loadingLabel, style: textStyle),
              ],
            )
          : Row(
              key: ValueKey(
                'loaded-$segmentKey-$count-${averageRating.toStringAsFixed(2)}',
              ),
              mainAxisSize: MainAxisSize.min,
              children: [
                StarRating(rating: averageRating, size: 14),
                Gap.horizontal.custom(6),
                Text(
                  countLabelBuilder(count),
                  overflow: TextOverflow.ellipsis,
                  style: textStyle,
                ),
              ],
            ),
    );
  }
}

class _CountSegment extends StatelessWidget {
  final int count;
  final bool loading;
  final String loadingLabel;
  final String Function(int count) countLabelBuilder;
  final String segmentKey;

  const _CountSegment({
    required this.count,
    required this.loading,
    required this.loadingLabel,
    required this.countLabelBuilder,
    required this.segmentKey,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: kAnimationDuration,
      switchInCurve: kAnimationCurve,
      switchOutCurve: kAnimationCurve,
      child: loading
          ? Row(
              key: ValueKey('loading-$segmentKey'),
              mainAxisSize: MainAxisSize.min,
              children: [
                const AppLoadingIndicator.small(),
                Gap.horizontal.custom(6),
                Text(
                  loadingLabel,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            )
          : Text(
              countLabelBuilder(count),
              key: ValueKey('loaded-$segmentKey-$count'),
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
    );
  }
}
