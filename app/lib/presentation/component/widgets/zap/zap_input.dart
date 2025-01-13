import 'package:flutter/material.dart';

import '../ui/padding.dart';

class ZapInputWidget extends StatefulWidget {
  const ZapInputWidget({super.key});

  @override
  State<StatefulWidget> createState() => ZapInputWidgetState();
}

class ZapInputWidgetState extends State<ZapInputWidget> {
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
