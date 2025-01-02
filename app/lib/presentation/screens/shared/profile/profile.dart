import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/presentation/widgets/main.dart';
import 'package:hostr/presentation/widgets/nostr_wallet_connect/nostr_wallet_connect.dart';

@RoutePage()
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: Column(
        children: [
          // ListTile(
          //   title: Text(
          //       'Switch to ${BlocProvider.of<SecureStorage>(context).state.mode ? 'guest' : 'host'} mode'),
          //   onTap: () {
          //     BlocProvider.of<SecureStorage>(context).set(
          //         'mode', !BlocProvider.of<SecureStorage>(context).state.mode);
          //   },
          // ),
          ListTile(
              title: Text('Nostr wallet connect'),
              subtitle: NostrWalletConnect()),
          ListTile(
            title: Text('Test'),
            subtitle: Column(
              children: [
                MaterialButton(
                  child: Text('Zap us'),
                  onPressed: () {
                    showModalBottomSheet(
                        context: context,
                        builder: (context) {
                          return ZapInput();
                        });
                  },
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
