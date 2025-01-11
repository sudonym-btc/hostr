import 'package:flutter/material.dart';
import 'package:hostr/data/models/price.dart';

class PriceTag extends StatelessWidget {
  final Price price;

  const PriceTag({
    super.key,
    required this.price,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      '19k sats',
      style: Theme.of(context)
          .textTheme
          .bodyMedium!
          .copyWith(fontWeight: FontWeight.bold),
    );
  }
}
