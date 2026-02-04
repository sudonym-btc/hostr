import 'package:flutter/material.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/injection.dart';

import 'connection.dart';

class NostrWalletConnectWidget extends StatefulWidget {
  final CustomLogger logger = CustomLogger();

  NostrWalletConnectWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _NostrWalletConnectWidgetState();
  }
}

class _NostrWalletConnectWidgetState extends State<NostrWalletConnectWidget> {
  Config config = getIt<Config>();

  @override
  initState() {
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: kDefaultPadding.toDouble() / 2),
            NostrWalletConnectConnectionWidget(canClose: true),
          ],
        ),
      ],
    );
  }
}
