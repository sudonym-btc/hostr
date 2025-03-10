import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/logic/services/swap.dart';
import 'package:hostr/presentation/component/widgets/main.dart';
import 'package:hostr/router.dart';
import 'package:models/main.dart';

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
              ProfileChipWidget(
                  id: getIt<KeyStorage>().getActiveKeyPairSync()!.publicKey),
              BlocBuilder<ModeCubit, ModeCubitState>(builder: (context, state) {
                return ListTile(
                  title: Text(
                      'Switch to ${state is HostMode ? 'guest' : 'host'} mode'),
                  onTap: () {
                    BlocProvider.of<ModeCubit>(context).toggle();
                  },
                );
              }),
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
                              to: 'jasmine@lnbits2.hostr.development',
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
                            to: 'lnbcrt1m1pnuh2h0sp53d22pxeg0wy5ugcaxkxqylph7xxgpur7x4yvr8ehmeljplr8mj8qpp5rjfq96tmtwwe2vdxmpltue5rl8y45ch3cnkd9rygcpr4u37tucdqdpq2djkuepqw3hjq5jz23pjqctyv3ex2umnxqyp2xqcqz959qyysgqdfhvjvfdve0jhfsjj90ta34449h5zqr8genctuc5ek09g0274gp39pa8lg2pt2dgz0pt7y3lcxh8k24tp345kv8sf2frkdc0zvp8npsqayww8f',
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
                        getIt<SwapService>().swapIn(100000);
                      },
                    ),
                    // FilledButton(
                    //   child: Text('Escrow'),
                    //   onPressed: () {
                    //     getIt<SwapService>().escrow();
                    //   },
                    // ),
                    FilledButton(
                      child: Text('ListEvents'),
                      onPressed: () {
                        getIt<SwapService>().listEvents();
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
