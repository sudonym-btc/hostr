import 'package:flutter/material.dart';
import 'package:hostr/data/main.dart';

class ReviewListItem extends StatelessWidget {
  final Review review;

  const ReviewListItem({super.key, required this.review});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      title: Text(review.content),
      subtitle: Text(review.nip01Event.pubKey),
    );
  }
}
