import 'package:flutter/material.dart';
import 'package:hostr/data/main.dart';

class PriceTagWidget extends StatelessWidget {
  final Price price;

  const PriceTagWidget({
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
