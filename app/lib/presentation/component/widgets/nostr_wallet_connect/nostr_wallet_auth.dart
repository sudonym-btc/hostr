import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/export.dart';
import 'package:hostr/injection.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
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
    KeyPair keyPair = Bip340.generatePrivateKey();

    nostrWalletAuth = NostrWalletAuth().generateUri(
        keyPair: keyPair,
        budget: config.defaultBudgetMonthly,
        budgetPeriod: BudgetPeriod.monthly,
        relay: config.hostrRelay,
        secret: keyPair.privateKey!);
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
                    child: Text(AppLocalizations.of(context)!.connect)),
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
                    child: Text(AppLocalizations.of(context)!.copy))
              ],
            )
          ])
        : Container();
  }
}
