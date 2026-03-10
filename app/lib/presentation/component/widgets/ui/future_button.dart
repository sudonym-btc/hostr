import 'package:flutter/material.dart';

import 'app_loading_indicator.dart';

/// A button that automatically shows a loading indicator while an async
/// [onPressed] callback is in flight, and displays a [SnackBar] on error.
///
/// Use the named constructors for different Material button styles:
/// - [FutureButton.filled]
/// - [FutureButton.tonal]
/// - [FutureButton.outlined]
class FutureButton extends StatefulWidget {
  final Future<void> Function()? onPressed;
  final Widget child;
  final ButtonStyle? style;
  final _FutureButtonVariant _variant;

  const FutureButton.filled({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
  }) : _variant = _FutureButtonVariant.filled;

  const FutureButton.tonal({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
  }) : _variant = _FutureButtonVariant.tonal;

  const FutureButton.outlined({
    super.key,
    required this.onPressed,
    required this.child,
    this.style,
  }) : _variant = _FutureButtonVariant.outlined;

  @override
  State<FutureButton> createState() => _FutureButtonState();
}

enum _FutureButtonVariant { filled, tonal, outlined }

class _FutureButtonState extends State<FutureButton> {
  bool _loading = false;

  Future<void> _handlePressed() async {
    if (_loading) return;
    final callback = widget.onPressed;
    if (callback == null) return;
    setState(() => _loading = true);
    try {
      await callback();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final child = _loading
        ? AppLoadingIndicator.small(
            color: Theme.of(context).colorScheme.onSurface,
          )
        : widget.child;

    final onPressed = widget.onPressed == null || _loading
        ? null
        : _handlePressed;

    return switch (widget._variant) {
      _FutureButtonVariant.filled => FilledButton(
        onPressed: onPressed,
        style: widget.style,
        child: child,
      ),
      _FutureButtonVariant.tonal => FilledButton.tonal(
        onPressed: onPressed,
        style: widget.style,
        child: child,
      ),
      _FutureButtonVariant.outlined => OutlinedButton(
        onPressed: onPressed,
        style: widget.style,
        child: child,
      ),
    };
  }
}
