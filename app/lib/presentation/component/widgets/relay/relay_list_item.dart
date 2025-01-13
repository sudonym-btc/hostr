import 'package:flutter/material.dart';

// final relayDoc = await Nostr.instance.relaysService.relayInformationsDocumentNip11(
//   relayUrl: "wss://relay.damus.io",
// );
class RelayListItemWidget extends StatelessWidget {
  final String relay;
  const RelayListItemWidget({super.key, required this.relay});

  @override
  Widget build(BuildContext context) {
    return Text(relay);
  }
}
