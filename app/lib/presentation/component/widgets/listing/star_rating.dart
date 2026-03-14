import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final num rating;
  final double size;

  const StarRating({super.key, required this.rating, this.size = 16});

  @override
  Widget build(BuildContext context) {
    final clampedRating = rating.toDouble().clamp(0, 5);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final fill = (clampedRating - index).clamp(0, 1).toDouble();

        return Stack(
          children: [
            Icon(
              Icons.star_border,
              size: size,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            if (fill > 0)
              ClipRect(
                clipper: _PartialStarClipper(fillFraction: fill),
                child: Icon(
                  Icons.star,
                  size: size,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
          ],
        );
      }),
    );
  }
}

class _PartialStarClipper extends CustomClipper<Rect> {
  final double fillFraction;

  const _PartialStarClipper({required this.fillFraction});

  @override
  Rect getClip(Size size) {
    return Rect.fromLTWH(0, 0, size.width * fillFraction, size.height);
  }

  @override
  bool shouldReclip(covariant _PartialStarClipper oldClipper) {
    return oldClipper.fillFraction != fillFraction;
  }
}
