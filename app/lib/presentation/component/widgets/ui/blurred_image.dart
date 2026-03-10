import 'dart:ui' as ui;

import 'package:flutter/material.dart';

/// Applies a grayscale colour filter and gaussian blur to its [child].
///
/// Useful as a placeholder background behind "add image" buttons in forms.
class BlurredImage extends StatelessWidget {
  final Widget child;

  const BlurredImage({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return ColorFiltered(
      colorFilter: const ColorFilter.matrix(<double>[
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0.2126,
        0.7152,
        0.0722,
        0,
        0,
        0,
        0,
        0,
        1,
        0,
      ]),
      child: ImageFiltered(
        imageFilter: ui.ImageFilter.blur(
          sigmaX: 10,
          sigmaY: 10,
          tileMode: TileMode.mirror,
        ),
        child: child,
      ),
    );
  }
}
