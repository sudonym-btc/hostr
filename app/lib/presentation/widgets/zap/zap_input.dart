import 'package:flutter/material.dart';

import '../ui/padding.dart';

class ZapInput extends StatefulWidget {
  const ZapInput({super.key});

  @override
  State<StatefulWidget> createState() => ZapInputState();
}

class ZapInputState extends State<ZapInput> {
  @override
  Widget build(BuildContext context) {
    return CustomPadding(
        child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text('Zap us'),
        FilledButton(
          child: Text('Zap'),
          onPressed: () {},
        )
      ],
    ));
  }
}
