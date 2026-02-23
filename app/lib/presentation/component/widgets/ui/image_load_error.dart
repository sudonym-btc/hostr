import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';

/// Standard fallback shown when an image fails to load.
class ImageLoadError extends StatelessWidget {
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final String? message;

  const ImageLoadError({
    super.key,
    this.width,
    this.height,
    this.borderRadius,
    this.message,
  });

  @override
  Widget build(BuildContext context) {
    final shape = borderRadius ?? BorderRadius.circular(8);
    final text = message ?? 'Image unavailable';

    return SizedBox(
      width: width,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHigh,
          borderRadius: shape,
        ),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.broken_image_outlined,
                size: kIconXl,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
              const SizedBox(height: kSpace2),
              Text(
                text,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
