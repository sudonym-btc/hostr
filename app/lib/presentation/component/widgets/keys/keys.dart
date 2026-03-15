import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:web3dart/web3dart.dart';

class KeysWidget extends StatefulWidget {
  const KeysWidget({super.key});

  @override
  KeysWidgetState createState() => KeysWidgetState();
}

class KeysWidgetState extends State<KeysWidget> {
  @override
  Widget build(BuildContext context) {
    return getIt<Hostr>().auth.activeKeyPair != null
        ? Column(
            children: [
              ListTile(
                title: Text(AppLocalizations.of(context)!.publicKey),
                subtitle: Text(getIt<Hostr>().auth.activeKeyPair!.publicKey),
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(
                      text: getIt<Hostr>().auth.activeKeyPair!.publicKey,
                    ),
                  );
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.privateKey),
                subtitle: Text(getIt<Hostr>().auth.activeKeyPair!.privateKey!),
                onTap: () {
                  Clipboard.setData(
                    ClipboardData(
                      text: getIt<Hostr>().auth.activeKeyPair!.privateKey!,
                    ),
                  );
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.evmAddress),
                subtitle: FutureBuilder<EthPrivateKey>(
                  future: getIt<Hostr>().auth.hd.getActiveEvmKey(),
                  builder: (context, snapshot) =>
                      Text(snapshot.data?.address.eip55With0x ?? '...'),
                ),
                onTap: () async {
                  final evmKey = await getIt<Hostr>().auth.hd.getActiveEvmKey();
                  Clipboard.setData(
                    ClipboardData(text: evmKey.address.eip55With0x),
                  );
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.evmPrivateKey),
                subtitle: FutureBuilder<EthPrivateKey>(
                  future: getIt<Hostr>().auth.hd.getActiveEvmKey(),
                  builder: (context, snapshot) => Text(
                    snapshot.data == null
                        ? '...'
                        : bytesToHex(snapshot.data!.privateKey),
                  ),
                ),
                onTap: () async {
                  final evmKey = await getIt<Hostr>().auth.hd.getActiveEvmKey();
                  Clipboard.setData(
                    ClipboardData(
                      text: bytesToHex(evmKey.privateKey, include0x: true),
                    ),
                  );
                },
              ),
              // ListTile(
              //   title: Text('Mnemonic'),
              //   subtitle: Text(entropyToMnemonic(key!.privateKey!)),
              //   onTap: () {
              //     Clipboard.setData(
              //         ClipboardData(text: entropyToMnemonic(key!.privateKey!)));
              //   },
              // ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.boltz),
                subtitle: Text(getIt<Config>().rootstock.boltz.apiUrl),
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.rootstock),
                subtitle: Text(getIt<Config>().rootstock.rpcUrl),
              ),
            ],
          )
        : Container();
  }
}
