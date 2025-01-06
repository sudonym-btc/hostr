import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/presentation/widgets/main.dart';
import 'package:hostr/presentation/widgets/nostr_wallet_connect/nostr_wallet_connect.dart';
import 'package:hostr/presentation/widgets/zap/zap_list.dart';

@RoutePage()
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text('Profile'),
        ),
        body: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ListTile(
              //   title: Text(
              //       'Switch to ${BlocProvider.of<SecureStorage>(context).state.mode ? 'guest' : 'host'} mode'),
              //   onTap: () {
              //     BlocProvider.of<SecureStorage>(context).set(
              //         'mode', !BlocProvider.of<SecureStorage>(context).state.mode);
              //   },
              // ),
              Section(
                  title: 'Nostr wallet connect', body: NostrWalletConnect()),
              Section(title: 'Money in flight', body: MoneyInFlight()),
              Section(
                title: "relays",
                body: RelayList(),
              ),
              Section(
                body: Column(
                  children: [
                    FilledButton(
                      child: Text('Zap us'),
                      onPressed: () {
                        showModalBottomSheet(
                            context: context,
                            builder: (context) {
                              return ZapInput();
                            });
                      },
                    ),
                    ZapList(
                        pubkey:
                            'npub1qny3tkh0acurzla8x3zy4nhrjz5zd8l9sy9jys09umwng00manysew95gx')
                  ],
                ),
              )
            ],
          ),
        ));
  }
}
