import 'package:flutter/material.dart';

class ShimmerPlaceholder extends StatefulWidget {
  final bool loading;
  final Widget child;
  final Duration duration;
  final BorderRadiusGeometry? borderRadius;

  const ShimmerPlaceholder({
    super.key,
    required this.loading,
    required this.child,
    this.duration = const Duration(milliseconds: 1500),
    this.borderRadius,
  });

  @override
  State<ShimmerPlaceholder> createState() => _ShimmerPlaceholderState();
}

class _ShimmerPlaceholderState extends State<ShimmerPlaceholder>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: widget.duration);
    if (widget.loading) _controller.repeat();
  }

  @override
  void didUpdateWidget(covariant ShimmerPlaceholder oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.loading && !_controller.isAnimating) {
      _controller.repeat();
    } else if (!widget.loading && _controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    if (!widget.loading) {
      return Container(color: surface, child: widget.child);
    }

    final highlight = Color.lerp(
      surface,
      Theme.of(context).colorScheme.surfaceContainerHigh,
      0.4,
    )!;

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // Map [0, 1] → [-1.5, 1.5] so the highlight enters from fully
        // off the left edge and exits fully off the right edge before
        // looping, eliminating the visible jump.
        final t = _controller.value * 3.0 - 1.5;
        return Container(
          decoration: BoxDecoration(
            borderRadius: widget.borderRadius,
            gradient: LinearGradient(
              begin: Alignment(t - 0.6, -1),
              end: Alignment(t + 0.6, 1),
              colors: [surface, highlight, surface],
              stops: const [0.0, 0.5, 1.0],
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

class ShimmerCard extends StatelessWidget {
  final double height;
  final BorderRadiusGeometry borderRadius;

  const ShimmerCard({
    super.key,
    this.height = 120,
    this.borderRadius = const BorderRadius.all(Radius.circular(12)),
  });

  @override
  Widget build(BuildContext context) {
    return ShimmerPlaceholder(
      loading: true,
      borderRadius: borderRadius,
      child: SizedBox(height: height, width: double.infinity),
    );
  }
}

class ShimmerListItem extends StatelessWidget {
  final double height;

  const ShimmerListItem({super.key, this.height = 72});

  @override
  Widget build(BuildContext context) {
    return ShimmerPlaceholder(
      loading: true,
      borderRadius: const BorderRadius.all(Radius.circular(12)),
      child: SizedBox(height: height, width: double.infinity),
    );
  }
}
