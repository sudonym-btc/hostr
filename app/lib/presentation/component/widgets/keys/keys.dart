import 'package:bip39/bip39.dart';
import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';

class KeysWidget extends StatefulWidget {
  const KeysWidget({super.key});

  @override
  KeysWidgetState createState() => KeysWidgetState();
}

class KeysWidgetState extends State<KeysWidget> {
  NostrKeyPairs? key;
  KeyStorage keyStorage = getIt<KeyStorage>();
  @override
  void initState() {
    keyStorage.getActiveKeyPair().then((value) {
      setState(() {
        key = value;
      });
    });
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return key != null
        ? Column(
            children: [
              ListTile(
                title: Text('Public key'),
                subtitle: Text(key!.public),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: key!.public));
                },
              ),
              ListTile(
                title: Text('Private key'),
                subtitle: Text(key!.private),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: key!.private));
                },
              ),
              ListTile(
                title: Text('Public eth address'),
                subtitle: Text(getEthCredentials(key!.private).address.hex),
                onTap: () {
                  Clipboard.setData(ClipboardData(
                      text: getEthCredentials(key!.private).address.hex));
                },
              ),
              ListTile(
                title: Text('Public eth address from pubkey'),
                subtitle: Text(getEthAddressFromPublicKey(key!.public).hex),
                onTap: () {
                  Clipboard.setData(ClipboardData(
                      text: getEthCredentials(key!.private).address.hex));
                },
              ),
              ListTile(
                title: Text('Private eth key'),
                subtitle: Text(
                    (getEthCredentials(key!.private).privateKeyInt.toString())),
                onTap: () {
                  Clipboard.setData(ClipboardData(
                      text: String.fromCharCodes(
                          getEthCredentials(key!.private).privateKey)));
                },
              ),
              ListTile(
                title: Text('Mnemonic'),
                subtitle: Text(entropyToMnemonic(key!.private)),
                onTap: () {
                  Clipboard.setData(
                      ClipboardData(text: entropyToMnemonic(key!.private)));
                },
              ),
              ListTile(
                title: Text('Boltz'),
                subtitle: Text(getIt<Config>().boltzUrl),
              ),
              ListTile(
                title: Text('Rootstock'),
                subtitle: Text(getIt<Config>().rootstockRpcUrl),
              ),
            ],
          )
        : Container();
  }
}
