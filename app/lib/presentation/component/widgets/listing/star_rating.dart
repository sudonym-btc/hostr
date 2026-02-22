import 'package:flutter/material.dart';

class StarRating extends StatelessWidget {
  final int rating;
  final double size;

  const StarRating({super.key, required this.rating, this.size = 16});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(5, (index) {
        final star = index + 1;
        final selected = star <= rating;
        return Icon(
          selected ? Icons.star : Icons.star_border,
          size: size,
          color: selected
              ? Theme.of(context).colorScheme.primary
              : Theme.of(context).colorScheme.onSurfaceVariant,
        );
      }),
    );
  }
}
