import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/logic/services/swap.dart';
import 'package:hostr/presentation/component/widgets/main.dart';
import 'package:hostr/router.dart';

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
                  title: 'Nostr wallet connect',
                  body: NostrWalletConnectWidget()),
              Section(title: 'Money in flight', body: MoneyInFlightWidget()),
              Section(
                title: "Relays",
                body: RelayListWidget(),
              ),
              Section(
                  body: Column(
                children: [
                  FilledButton(
                    child: Text('Zap us'),
                    onPressed: () {
                      context.read<PaymentsManager>().create();
                    },
                  ),
                  // ZapList(
                  //     pubkey:
                  //         'npub1qny3tkh0acurzla8x3zy4nhrjz5zd8l9sy9jys09umwng00manysew95gx')
                ],
              )),
              Section(
                  title: 'Swap',
                  body: Column(children: [
                    FilledButton(
                      child: Text('Swap in'),
                      onPressed: () {
                        getIt<SwapService>().swapIn(10000);
                      },
                    ),
                    FilledButton(
                      child: Text('Swap out'),
                      onPressed: () {
                        getIt<SwapService>().swapOutAll();
                      },
                    ),
                  ])),
              Section(
                  title: 'Logout',
                  body: Column(
                    children: [
                      FilledButton(
                        child: Text('Logout'),
                        onPressed: () {
                          BlocProvider.of<AuthCubit>(context).logout();
                          AutoRouter.of(context).pushAndPopUntil(
                            HomeRoute(),
                            predicate: (route) => false,
                          );
                        },
                      )
                    ],
                  )),
              Section(
                  title: 'Info',
                  body: Column(
                    children: [KeysWidget()],
                  ))
            ],
          ),
        ));
  }
}
