import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/main.dart';
import 'package:hostr/presentation/screens/shared/inbox/inbox.dart';
import 'package:hostr/router.dart';

class DrawerWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      // Important: Remove any padding from the ListView.
      padding: EdgeInsets.zero,
      children: [
        DrawerHeader(
          decoration: BoxDecoration(
            color: Theme.of(context).primaryColor,
          ),
          child: Text('Drawer Header'),
        ),
        ListTile(
            title: Text('Conversations'),
            onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (BuildContext context) {
                      return const InboxScreen();
                    },
                    fullscreenDialog: true,
                  ),
                )),
        ListTile(
            title: Text('Nostr wallet connect'),
            onTap: () => showModalBottomSheet(
                context: context,
                builder: (context) => NostrWalletConnectWidget())),
        ListTile(
          title: Text('Money in flight'),
          onTap: () => showModalBottomSheet(
              context: context, builder: (context) => MoneyInFlightWidget()),
        ),
        ListTile(
          title: Text("Relays"),
          onTap: () => showModalBottomSheet(
              context: context, builder: (context) => RelayListWidget()),
        ),
        // Section(
        //     body: Column(
        //   children: [
        //     FilledButton(
        //       child: Text('Zap us'),
        //       onPressed: () {
        //         context.read<PaymentsManager>().create();
        //       },
        //     ),
        //     // ZapList(
        //     //     pubkey:
        //     //         'npub1qny3tkh0acurzla8x3zy4nhrjz5zd8l9sy9jys09umwng00manysew95gx')
        //   ],
        // )),
        // Section(
        //     title: 'Swap',
        //     body: Column(children: [
        //       FilledButton(
        //         child: Text('Swap in'),
        //         onPressed: () {
        //           getIt<SwapService>().swapIn(10000);
        //         },
        //       ),
        //       FilledButton(
        //         child: Text('Swap out'),
        //         onPressed: () {
        //           getIt<SwapService>().swapOutAll();
        //         },
        //       ),
        //     ])),
        ListTile(
          title: Text('Logout'),
          onTap: () => showModalBottomSheet(
              context: context,
              builder: (context) => FilledButton(
                    child: Text('Logout'),
                    onPressed: () {
                      BlocProvider.of<AuthCubit>(context).logout();
                      AutoRouter.of(context).pushAndPopUntil(
                        HomeRoute(),
                        predicate: (route) => false,
                      );
                    },
                  )),
        ),
        Section(
            title: 'Info',
            body: Column(
              children: [
                BlocBuilder<GlobalGiftWrapCubit, ListCubitState<GiftWrap>>(
                    builder: (context, state) {
                  return Text('Giftwraps: ${state.results.length}');
                }),
                KeysWidget()
              ],
            ))
      ],
    );
  }
}
