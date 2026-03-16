import 'package:flutter/material.dart';

class ListingReviewsSection extends StatelessWidget {
  final Widget reviewsListWidget;

  const ListingReviewsSection({super.key, required this.reviewsListWidget});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [reviewsListWidget],
    );
  }
}
