import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/models/amount.dart';
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
                      context.read<PaymentsManager>().create(
                          LnUrlPaymentParameters(
                              to: 'paco@walletofsatoshi.com',
                              amount: Amount(
                                  currency: Currency.BTC, value: 0.00001)));
                    },
                  ),
                  FilledButton(
                    child: Text('Bolt11'),
                    onPressed: () {
                      context
                          .read<PaymentsManager>()
                          .create(Bolt11PaymentParameters(
                            to: 'lnbc1220n1pnc5srtsp5mpgyd5w2rf2qw6aqzyj579dw09waxc9ks0z3dtyurgsccwmx5ccspp5ppdgqnagc6nyxrhdu0sq6n59jdyh9tehmwe20625czltfyu2anxshp5uwcvgs5clswpfxhm7nyfjmaeysn6us0yvjdexn9yjkv3k7zjhp2sxq9z0rgqcqpnrzjq0euzzxv65mts5ngg8c2t3vzz2aeuevy5845jvyqulqucd8c9kkhzrtp55qq63qqqqqqqqqqqqqzwyqqyg9qxpqysgqter3unp07hkfxz6qqydv7nlmhvcfrke4s72adhq48h082qvzxvgre9aj3mxnkx4uph9yfj67egzmfqtvgzupe6ag5kjmlvh8g6fxjzcp3sp90a',
                          ));
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
                        onPressed: () async {
                          final router = AutoRouter.of(
                              context); // Store the router instance

                          await BlocProvider.of<AuthCubit>(context).logout();
                          print('Routing');
                          await router.replaceAll(
                            [SignInRoute()],
                            onFailure: (failure) => print(failure),
                          );
                          print('Routed');
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
