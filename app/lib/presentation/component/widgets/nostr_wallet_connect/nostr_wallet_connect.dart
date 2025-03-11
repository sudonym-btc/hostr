import 'package:flutter/material.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/injection.dart';

import 'add_wallet.dart';
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
    return IntrinsicHeight(
        child: Column(
      children: [
        Column(
          children: [
            NostrWalletConnectConnectionWidget(),
            SizedBox(height: DEFAULT_PADDING.toDouble()),
            FilledButton(
                onPressed: () {
                  showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return AddWalletWidget();
                      });
                },
                child: Text('Connect Wallet'))
          ],
        )
      ],
    ));
  }
}
