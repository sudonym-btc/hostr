import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class SignInScreen extends StatelessWidget {
  const SignInScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Profile'),
      ),
      body: ListView(
        children: [
          // ListTile(
          //   title: Text(
          //       'Switch to ${BlocProvider.of<SecureStorage>(context).state.mode ? 'guest' : 'host'} mode'),
          //   onTap: () {
          //     BlocProvider.of<SecureStorage>(context).set(
          //         'mode', !BlocProvider.of<SecureStorage>(context).state.mode);
          //   },
          // ),
          // ListTile(
          //   title: Text('Nostr wallet connect'),
          //   onTap: () {
          //     BlocProvider.of<SecureStorage>(context).set(
          //         'mode', !BlocProvider.of<SecureStorage>(context).state.mode);
          //   },
          // )
        ],
      ),
    );
  }
}
