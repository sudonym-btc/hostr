import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hostr/export.dart';
import 'package:hostr/injection.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

class NostrWalletAuthWidget extends StatefulWidget {
  final CustomLogger logger = CustomLogger();

  NostrWalletAuthWidget({super.key});

  @override
  State<StatefulWidget> createState() {
    return _NostrWalletAuthWidgetState();
  }
}

class _NostrWalletAuthWidgetState extends State<NostrWalletAuthWidget> {
  Config config = getIt<Config>();
  Uri? nostrWalletAuth;
  bool canLaunch = false;

  @override
  initState() {
    super.initState();
    NostrKeyPairs keyPair = NostrKeyPairs.generate();

    nostrWalletAuth = NostrWalletAuth().generateUri(
        keyPair: NostrKeyPairs.generate(),
        budget: config.defaultBudgetMonthly,
        budgetPeriod: BudgetPeriod.monthly,
        relay: config.hostrRelay,
        secret: keyPair.private);
    canLaunchUrl(nostrWalletAuth!).then((value) {
      setState(() {
        canLaunch = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return canLaunch
        ? Column(children: [
            Text('Connect app to wallet'),
            QrImageView(
              data: nostrWalletAuth.toString(),
              version: QrVersions.auto,
              size: 200.0,
            ),
            Row(
              children: [
                MaterialButton(
                    onPressed: () async {
                      await launchUrl(nostrWalletAuth!);
                    },
                    child: Text('Connect')),
                MaterialButton(
                    onPressed: () async {
                      await Clipboard.setData(
                          ClipboardData(text: nostrWalletAuth.toString()));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('URI copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    child: Text('Copy'))
              ],
            )
          ])
        : Container();
  }
}
