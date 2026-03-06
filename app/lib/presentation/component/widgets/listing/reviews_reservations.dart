import 'dart:async';

import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';

class ReviewsReservationsWidget extends StatelessWidget {
  /// Optional externally-provided review count stream.
  /// When supplied the widget skips creating its own [CountCubit] for reviews.
  final Stream<int> reviewCount;

  /// Optional externally-provided reservation/stays count stream.
  /// When supplied the widget skips creating its own [CountCubit] for stays.
  final Stream<int> reservationCount;

  const ReviewsReservationsWidget({
    super.key,
    required this.reviewCount,
    required this.reservationCount,
  });

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _ExternalCountSegment(
          countStream: reviewCount,
          loadingLabel: l10n.reviewsLabel,
          countLabelBuilder: l10n.reviewCount,
          segmentKey: 'reviews',
        ),
        const Text(' · '),
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
                Text(loadingLabel),
              ],
            )
          : Text(
              countLabelBuilder(count),
              key: ValueKey('loaded-$segmentKey-$count'),
              overflow: TextOverflow.ellipsis,
            ),
    );
  }
}
