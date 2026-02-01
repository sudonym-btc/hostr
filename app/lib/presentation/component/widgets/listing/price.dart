import 'package:flutter/material.dart';

class PriceText extends StatelessWidget {
  final String price;

  const PriceText(this.price, {super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      price,
      style: Theme.of(
        context,
      ).textTheme.bodyMedium!.copyWith(fontWeight: FontWeight.bold),
    );
  }
}
