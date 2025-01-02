import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hostr/core/main.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class NostrWalletConnect extends StatefulWidget {
  final CustomLogger logger = CustomLogger();

  NostrWalletConnect({super.key});

  @override
  State<StatefulWidget> createState() {
    return _NostrWalletConnectState();
  }
}

class _NostrWalletConnectState extends State<NostrWalletConnect> {
  @override
  Widget build(BuildContext context) {
    NostrKeyPairs keyPair = NostrKeyPairs.generate();
    String uri = NostrWalletAuth().generateUri(
        keyPair: keyPair,
        budget: 10000,
        budgetPeriod: BudgetPeriod.daily,
        relay: 'https://relay.nostr.org',
        secret: 'secret');
    return Column(
      children: [
        Column(
          children: [
            Text('Connect app to wallet'),
            QrImageView(
              data: uri,
              version: QrVersions.auto,
              size: 200.0,
            ),
            Row(children: [
              MaterialButton(
                  onPressed: () async {
                    print('pre');
                    print(await canLaunchUrl(Uri.parse(uri)));
                    await launchUrl(Uri.parse(uri));
                    print('postclick');
                  },
                  child: Text('Connect')),
              MaterialButton(
                  onPressed: () async {
                    await Clipboard.setData(ClipboardData(text: uri));
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('URI copied to clipboard'),
                        duration: Duration(seconds: 2),
                      ),
                    );
                  },
                  child: Text('Copy'))
            ])
          ],
        ),
        Column(
          children: [Text('Connect wallet to app')],
        )
      ],
    );
  }
}
