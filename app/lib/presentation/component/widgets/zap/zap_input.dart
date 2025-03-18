import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';

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
        Text(AppLocalizations.of(context)!.zapUs),
        FilledButton(
          child: Text(AppLocalizations.of(context)!.zap),
          onPressed: () {},
        )
      ],
    ));
  }
}
