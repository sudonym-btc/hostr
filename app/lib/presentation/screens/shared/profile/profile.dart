import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/flow/nwc/nwc_flow.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/payment_flow.dart';
import 'package:hostr/presentation/component/widgets/flow/relay/relay_flow.dart';
import 'package:hostr/presentation/component/widgets/nostr_wallet_connect/add_wallet.dart'
    show AddWalletWidget;
import 'package:hostr/presentation/component/widgets/zap/zap_list.dart';
import 'package:hostr/presentation/main.dart';
import 'package:hostr/router.dart';
import 'package:models/main.dart';

import 'mode_toggle.dart';

@RoutePage()
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            pinned: true,
            expandedHeight: 300.0,
            flexibleSpace: FlexibleSpaceBar(
              background: SafeArea(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: ProfileProvider(
                    pubkey: getIt<Hostr>().auth.activeKeyPair!.publicKey,
                    builder: (context, snapshot) => snapshot.data == null
                        ? Center(child: CircularProgressIndicator())
                        : Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              CircleAvatar(
                                radius: 40,
                                backgroundImage:
                                    snapshot.data!.metadata.picture != null
                                    ? NetworkImage(
                                        snapshot.data!.metadata.picture!,
                                      )
                                    : null, // Replace with actual profile photo URL
                              ),
                              SizedBox(height: 16), // Increased padding
                              Text(
                                snapshot.data!.metadata.name ??
                                    snapshot.data!.metadata.displayName ??
                                    'Username', // Replace with actual username
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              SizedBox(height: 8), // Added padding
                              Text(
                                snapshot.data!.metadata.nip05 ??
                                    'nip05_address@example.com', // Replace with actual nip05 address
                                style: TextStyle(fontSize: 14),
                              ),
                              SizedBox(height: 4), // Added padding
                              Text(
                                snapshot.data!.metadata.about ??
                                    '', // Replace with actual about section text
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                  ),
                ),
              ),
            ),
            title: Text(AppLocalizations.of(context)!.profile),
            actions: [
              IconButton(
                icon: Icon(Icons.edit),
                onPressed: () {
                  AutoRouter.of(context).navigate(EditProfileRoute());
                },
              ),
            ],
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              ModeToggleWidget(),
              Section(
                title: AppLocalizations.of(context)!.wallet,
                action: FilledButton.tonal(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return NwcFlowWidget(
                          onClose: () {
                            // Navigator.pop(context);
                          },
                        );
                      },
                    );
                  },
                  child: Text(AppLocalizations.of(context)!.connect),
                ),
                body: NostrWalletConnectWidget(),
              ),
              Section(
                title: "Relays",
                action: FilledButton.tonal(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (BuildContext modalContext) {
                        return RelayFlowWidget(
                          onClose: () {
                            Navigator.of(modalContext).pop();
                          },
                        );
                      },
                    );
                  },
                  child: Text(AppLocalizations.of(context)!.connect),
                ),
                body: RelayListWidget(),
              ),
              Section(
                title: "Trusted Escrows",
                action: FilledButton.tonal(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      builder: (BuildContext context) {
                        return AddWalletWidget();
                      },
                    );
                  },
                  child: Text(AppLocalizations.of(context)!.add),
                ),
                body: FutureBuilder(
                  future: getIt<Hostr>().escrowTrusts.myTrusted(),
                  builder:
                      (
                        BuildContext context,
                        AsyncSnapshot<EscrowTrust?> snapshot,
                      ) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          if (snapshot.hasData) {
                            return Column(
                              children: [
                                SizedBox(
                                  height: DEFAULT_PADDING.toDouble() / 2,
                                ),
                                ...snapshot.data!.tags
                                    .where((el) => el[0] == 'p')
                                    .map((el) {
                                      return ProfileProvider(
                                        pubkey: el[1],
                                        builder: (context, profileSnapshot) {
                                          return ListTile(
                                            contentPadding: EdgeInsets.all(0),
                                            leading: CircleAvatar(
                                              backgroundImage:
                                                  profileSnapshot
                                                          .data
                                                          ?.metadata
                                                          .picture !=
                                                      null
                                                  ? NetworkImage(
                                                      profileSnapshot
                                                          .data!
                                                          .metadata
                                                          .picture!,
                                                    )
                                                  : null,
                                            ),
                                            title: Text(
                                              profileSnapshot
                                                      .data
                                                      ?.metadata
                                                      .name ??
                                                  profileSnapshot
                                                      .data
                                                      ?.metadata
                                                      .displayName ??
                                                  'Username',
                                            ),
                                            subtitle: Text(
                                              profileSnapshot
                                                      .data
                                                      ?.metadata
                                                      .nip05 ??
                                                  '',
                                            ),
                                          );
                                        },
                                      );
                                    }),
                              ],
                            );
                          } else {
                            return Text("No escrows trusted yet");
                          }
                        } else {
                          return CircularProgressIndicator();
                        }
                      },
                ),
              ),
              Section(title: 'Money in flight', body: MoneyInFlightWidget()),

              Section(
                body: Column(
                  children: [
                    FilledButton(
                      child: Text(AppLocalizations.of(context)!.logout),
                      onPressed: () async {
                        final router = AutoRouter.of(
                          context,
                        ); // Store the router instance
                        await BlocProvider.of<AuthCubit>(context).logout();
                        await router.replaceAll([
                          SignInRoute(),
                        ], onFailure: (failure) => throw failure);
                      },
                    ),
                  ],
                ),
              ),
              Section(
                body: Column(
                  children: [
                    CustomPadding(
                      child: Text(
                        'Hostr is open source software maintained by the community with ❤️.',
                      ),
                    ),
                    Row(
                      children: [
                        FilledButton(
                          child: Text(AppLocalizations.of(context)!.zapUs),
                          onPressed: () {
                            final params = LnUrlPaymentParameters(
                              to: 'tips@lnbits1.hostr.development',
                              amount: Amount(
                                currency: Currency.BTC,
                                value: 0.00001,
                              ),
                            );
                            final paymentCubit = getIt<Hostr>().payments.pay(
                              params,
                            )..resolve();
                            showModalBottomSheet(
                              context: context,
                              builder: (BuildContext context) {
                                return PaymentFlowWidget(
                                  paymentCubit: paymentCubit,
                                  onClose: () {
                                    print('closing modal');
                                    // Navigator.pop(context);
                                  },
                                );
                              },
                            );
                          },
                        ),
                        ZapListWidget(
                          pubkey: MockKeys.hoster.publicKey,
                          builder: (p0) => Text(p0.pubKey!),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Info section as an expandable list item
              if (const bool.fromEnvironment('dart.vm.product') == false)
                ExpansionTile(
                  title: Text('Dev'),
                  children: [
                    Section(
                      title: 'bolt11',
                      body: FilledButton(
                        child: Text('Bolt11'),
                        onPressed: () {
                          final params = Bolt11PaymentParameters(
                            to: 'lnbcrt1m1pnuh2h0sp53d22pxeg0wy5ugcaxkxqylph7xxgpur7x4yvr8ehmeljplr8mj8qpp5rjfq96tmtwwe2vdxmpltue5rl8y45ch3cnkd9rygcpr4u37tucdqdpq2djkuepqw3hjq5jz23pjqctyv3ex2umnxqyp2xqcqz959qyysgqdfhvjvfdve0jhfsjj90ta34449h5zqr8genctuc5ek09g0274gp39pa8lg2pt2dgz0pt7y3lcxh8k24tp345kv8sf2frkdc0zvp8npsqayww8f',
                          );
                          final paymentCubit = getIt<Bolt11PaymentCubit>(
                            param1: params,
                          );
                          showModalBottomSheet(
                            context: context,
                            builder: (BuildContext context) {
                              return PaymentFlowWidget(
                                paymentCubit: paymentCubit,
                                onClose: () {
                                  Navigator.pop(context);
                                },
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Section(
                      title: 'Swap',
                      body: Column(
                        children: [
                          // FilledButton(
                          //   child: Text('Swap in'),
                          //   onPressed: () {
                          //     context.read<SwapManager>().swapIn(100000);
                          //   },
                          // ),
                          // // FilledButton(
                          // //   child: Text('Escrow'),
                          // //   onPressed: () {
                          // //     getIt<SwapService>().escrow();
                          // //   },
                          // // ),
                          // FilledButton(
                          //   child: Text('ListEvents'),
                          //   onPressed: () {
                          //     context.read<SwapManager>().listEvents();
                          //   },
                          // ),
                          // FilledButton(
                          //   child: Text('Swap out'),
                          //   onPressed: () {
                          //     context.read<SwapManager>().swapOutAll();
                          //   },
                          // ),
                        ],
                      ),
                    ),
                    KeysWidget(),
                  ],
                ),
            ]),
          ),
        ],
      ),
    );
  }
}
