import 'package:flutter/material.dart';
import 'package:hostr/main.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

@widgetbook.UseCase(name: 'Default', type: NostrWalletConnectWidget)
Widget nwc(BuildContext context) {
  return Scaffold(
    body: Align(
      alignment: Alignment.bottomCenter,
      child: NostrWalletConnectWidget(
        connectionList: Column(
          children: const [
            NostrWalletConnectConnectionTileView(
              state: NostrWalletConnectConnectionUiState.connected,
              canClose: true,
              alias: 'Alby Wallet',
              subtitle: 'Connected',
              avatarColor: Colors.orange,
            ),
            NostrWalletConnectConnectionTileView(
              state: NostrWalletConnectConnectionUiState.failure,
              canClose: true,
              alias: 'wss://relay.example.com',
              errorText: 'Connection refused',
            ),
          ],
        ),
      ),
    ),
  );
}

@widgetbook.UseCase(
  name: 'No active connection',
  type: NostrWalletConnectWidget,
)
Widget nwcNoActiveConnection(BuildContext context) {
  return Scaffold(
    body: Align(
      alignment: Alignment.bottomCenter,
      child: NostrWalletConnectWidget(
        connectionList: const NostrWalletConnectConnectionTileView(
          state: NostrWalletConnectConnectionUiState.loading,
          canClose: false,
        ),
      ),
    ),
  );
}
