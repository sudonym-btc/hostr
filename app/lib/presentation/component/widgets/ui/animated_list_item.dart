import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';

/// A reusable widget that animates its child into view with a combined
/// fade + upward slide effect.
///
/// Use [index] to stagger items in a list — each successive item starts its
/// animation [kStaggerDelay] × index later, capped at [maxStaggerIndex] so
/// off-screen items don't wait forever.
///
/// ```dart
/// AnimatedListItem(
///   index: idx,
///   child: MyTile(data),
/// )
/// ```
class AnimatedListItem extends StatefulWidget {
  /// The child widget to animate in.
  final Widget child;

  /// Position in the list, used to compute a stagger delay.
  final int index;

  /// Maximum index considered for stagger delay (items beyond this animate
  /// as if they were at this index). Keeps late items from waiting too long.
  final int maxStaggerIndex;

  /// Total animation duration (defaults to [kAnimationDuration]).
  final Duration duration;

  /// Animation curve (defaults to [kAnimationCurve]).
  final Curve curve;

  const AnimatedListItem({
    super.key,
    required this.child,
    this.index = 0,
    this.maxStaggerIndex = 8,
    this.duration = kAnimationDuration,
    this.curve = kAnimationCurve,
  });

  @override
  State<AnimatedListItem> createState() => _AnimatedListItemState();
}

class _AnimatedListItemState extends State<AnimatedListItem>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _opacity;
  late final Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: widget.duration);

    final curved = CurvedAnimation(parent: _controller, curve: widget.curve);

    _opacity = Tween<double>(begin: 0, end: 1).animate(curved);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.15),
      end: Offset.zero,
    ).animate(curved);

    final staggerIndex = widget.index.clamp(0, widget.maxStaggerIndex);
    final delay = kStaggerDelay * staggerIndex;

    Future.delayed(delay, () {
      if (mounted) _controller.forward();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}
