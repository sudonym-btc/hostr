import 'dart:async';

import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Displays a relative timestamp (e.g. "5m", "2h") that auto-refreshes
/// every 10 seconds. Uses the `en_short` timeago locale to match the
/// inbox-item style.
///
/// When [builder] is provided it receives the formatted string and returns
/// an arbitrary widget — useful when the caller needs custom styling or
/// wants to embed the time string inside a richer layout.
class RelativeTimeText extends StatefulWidget {
  final DateTime dateTime;
  final TextStyle? style;

  /// Optional builder. When non-null, [style] is ignored and the caller
  /// is responsible for rendering the supplied [text] string.
  final Widget Function(BuildContext context, String text)? builder;

  const RelativeTimeText({
    super.key,
    required this.dateTime,
    this.style,
    this.builder,
  });

  @override
  State<RelativeTimeText> createState() => _RelativeTimeTextState();
}

class _RelativeTimeTextState extends State<RelativeTimeText> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final text = timeago.format(widget.dateTime, locale: 'en_short');
    final b = widget.builder;
    if (b != null) return b(context, text);
    return Text(text, style: widget.style);
  }
}
