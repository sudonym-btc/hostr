import 'package:bip39/bip39.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/main.dart';
import 'package:models/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:web3dart/crypto.dart';

class KeysWidget extends StatefulWidget {
  const KeysWidget({super.key});

  @override
  KeysWidgetState createState() => KeysWidgetState();
}

class KeysWidgetState extends State<KeysWidget> {
  KeyPair? key;
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
                title: Text(AppLocalizations.of(context)!.publicKey),
                subtitle: Text(key!.publicKey),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: key!.publicKey));
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.privateKey),
                subtitle: Text(key!.privateKey!),
                onTap: () {
                  Clipboard.setData(ClipboardData(text: key!.privateKey!));
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.evmAddress),
                subtitle: Text(getEthCredentials(key!.privateKey!).address.hex),
                onTap: () {
                  Clipboard.setData(ClipboardData(
                      text: getEthCredentials(key!.privateKey!).address.hex));
                },
              ),
              ListTile(
                title: Text(
                    '${AppLocalizations.of(context)!.evmAddress} from pubkey'),
                subtitle: Text(getEthAddressFromPublicKey(key!.publicKey).hex),
                onTap: () {
                  Clipboard.setData(ClipboardData(
                      text: getEthCredentials(key!.privateKey!).address.hex));
                },
              ),
              ListTile(
                title: Text(AppLocalizations.of(context)!.evmPrivateKey),
                subtitle: Text(bytesToHex(
                    (getEthCredentials(key!.privateKey!).privateKey))),
                onTap: () {
                  Clipboard.setData(ClipboardData(
                      text: bytesToHex(
                          getEthCredentials(key!.privateKey!).privateKey,
                          include0x: true)));
                },
              ),
              ListTile(
                title: Text('Mnemonic'),
                subtitle: Text(entropyToMnemonic(key!.privateKey!)),
                onTap: () {
                  Clipboard.setData(
                      ClipboardData(text: entropyToMnemonic(key!.privateKey!)));
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
              Row(children: [
                FilledButton(
                    onPressed: () async {
                      await Future.wait([
                        context.read<ModeCubit>().setHost(),
                        context
                            .read<AuthCubit>()
                            .signin(MockKeys.hoster.privateKey!)
                      ] as Iterable<Future>);
                    },
                    child: Text('Log in host')),
                FilledButton(
                    onPressed: () async {
                      await context.read<AuthCubit>().logout();
                      await context.read<ModeCubit>().setGuest();
                      await context
                          .read<AuthCubit>()
                          .signin(MockKeys.guest.privateKey!);
                    },
                    child: Text('Log in guest'))
              ])
            ],
          )
        : Container();
  }
}
