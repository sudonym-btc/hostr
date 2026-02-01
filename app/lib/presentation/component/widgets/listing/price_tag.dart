import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/widgets/listing/price.dart';
import 'package:hostr/presentation/main.dart';
import 'package:models/main.dart';

class PriceTagWidget extends StatelessWidget {
  final Price price;

  const PriceTagWidget({super.key, required this.price});

  @override
  Widget build(BuildContext context) {
    return PriceText(formatAmount(price.amount, exact: false));
  }
}
