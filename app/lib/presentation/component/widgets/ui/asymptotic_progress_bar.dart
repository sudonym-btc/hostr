import 'dart:async';

import 'package:flutter/material.dart';

/// A progress bar that asymptotically approaches 100% but never reaches it.
///
/// Uses the formula `progress = t / (t + k)` where `t` is elapsed seconds
/// and `k` controls how quickly the bar approaches full. With `k = 6`:
///   - 5s  → 45%
///   - 10s → 63%
///   - 15s → 71%
///   - 20s → 77%
///   - 30s → 83%
///   - 60s → 91%
class AsymptoticProgressBar extends StatefulWidget {
  /// Controls the rate of approach. Lower = faster initial fill.
  /// Default is 6.0 (roughly 83% at 30s).
  final double k;

  /// Height of the progress bar. Defaults to 4.0.
  final double height;

  /// Border radius of the progress bar. Defaults to 8.0.
  final double borderRadius;

  const AsymptoticProgressBar({
    super.key,
    this.k = 6.0,
    this.height = 4.0,
    this.borderRadius = 8.0,
  });

  @override
  State<AsymptoticProgressBar> createState() => _AsymptoticProgressBarState();
}

class _AsymptoticProgressBarState extends State<AsymptoticProgressBar> {
  late final Stopwatch _stopwatch;
  late final Timer _timer;
  double _progress = 0.0;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch()..start();
    _timer = Timer.periodic(const Duration(milliseconds: 50), _tick);
  }

  void _tick(Timer _) {
    final t = _stopwatch.elapsedMilliseconds / 1000.0;
    setState(() {
      _progress = t / (t + widget.k);
    });
  }

  @override
  void dispose() {
    _timer.cancel();
    _stopwatch.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return ClipRRect(
      borderRadius: BorderRadius.circular(widget.borderRadius),
      child: LinearProgressIndicator(
        value: _progress,
        minHeight: widget.height,
        backgroundColor: colorScheme.surfaceContainerHighest,
        valueColor: AlwaysStoppedAnimation<Color>(colorScheme.primary),
      ),
    );
  }
}
