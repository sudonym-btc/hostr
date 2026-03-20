import 'package:flutter/material.dart';

/// A reusable wrapper that triggers [onLoadNext] when the user scrolls near
/// the bottom of any scrollable child.
///
/// Wrap any scrollable widget (e.g. `ListView`, `GridView`, `CustomScrollView`)
/// and provide the loading/hasMore state so the callback is only fired when
/// appropriate.
///
/// ```dart
/// LoadNextOnScroll(
///   onLoadNext: () => cubit.next(),
///   isLoading: state.fetching,
///   hasMore: state.hasMore ?? true,
///   child: GridView.builder(…),
/// )
/// ```
class LoadNextOnScroll extends StatelessWidget {
  /// Called when the user scrolls within [threshold] pixels of the bottom.
  final VoidCallback onLoadNext;

  /// When `true` the callback is suppressed (a page is already in-flight).
  final bool isLoading;

  /// When `false` the callback is suppressed (no more data to fetch).
  final bool hasMore;

  /// Distance from the bottom (in logical pixels) at which [onLoadNext] fires.
  final double threshold;

  final Widget child;

  const LoadNextOnScroll({
    super.key,
    required this.onLoadNext,
    required this.isLoading,
    required this.hasMore,
    required this.child,
    this.threshold = 200,
  });

  @override
  Widget build(BuildContext context) {
    return NotificationListener<ScrollNotification>(
      onNotification: (notification) {
        if (isLoading || !hasMore) return false;

        final metrics = notification.metrics;
        if (metrics.pixels >= metrics.maxScrollExtent - threshold) {
          onLoadNext();
        }
        return false;
      },
      child: child,
    );
  }
}
