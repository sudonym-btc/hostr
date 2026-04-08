import 'dart:async';

import 'package:flutter/material.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Displays a relative timestamp (e.g. "5m", "2h") that auto-refreshes
/// every 10 seconds. Uses the `en_short` timeago locale to match the
/// inbox-item style.
class RelativeTimeText extends StatefulWidget {
  final DateTime dateTime;
  final TextStyle? style;

  const RelativeTimeText({super.key, required this.dateTime, this.style});

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
    return Text(
      timeago.format(widget.dateTime, locale: 'en_short'),
      style: widget.style,
    );
  }
}
