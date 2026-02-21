import 'package:flutter/material.dart';
import 'package:hostr/config/main.dart';

import 'connection.dart';

class NostrWalletConnectWidget extends StatelessWidget {
  final Widget connectionList;

  const NostrWalletConnectWidget({super.key, required this.connectionList});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: kDefaultPadding.toDouble() / 2),
            connectionList,
          ],
        ),
      ],
    );
  }
}

class NostrWalletConnectContainerWidget extends StatelessWidget {
  const NostrWalletConnectContainerWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const NostrWalletConnectWidget(
      connectionList: NostrWalletConnectConnectionWidget(canClose: true),
    );
  }
}
