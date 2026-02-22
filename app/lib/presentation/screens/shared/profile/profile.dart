import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/payment.dart';
import 'package:hostr/presentation/component/widgets/flow/relay/relay_flow.dart';
import 'package:hostr/presentation/component/widgets/keys/backup_key.dart';
import 'package:hostr/presentation/component/widgets/nostr_wallet_connect/add_wallet.dart'
    show AddWalletWidget;
import 'package:hostr/presentation/component/widgets/zap/zap_list.dart';
import 'package:hostr/presentation/main.dart';
import 'package:hostr/presentation/screens/shared/profile/dev.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/usecase/payments/operations/pay_models.dart';
import 'package:models/stubs/keypairs.dart';

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
                    builder: (context, snapshot) => ProfileHeaderWidget(
                      profile: snapshot.data,
                      isLoading:
                          snapshot.connectionState != ConnectionState.done,
                      onEditProfile: () {
                        AutoRouter.of(context).navigate(EditProfileRoute());
                      },
                    ),
                  ),
                ),
              ),
            ),
            title: Text(AppLocalizations.of(context)!.profile),
            actions: [
              IconButton(
                icon: const Icon(Icons.key),
                tooltip: 'Back up keys',
                onPressed: () {
                  final keyPair = getIt<Hostr>().auth.activeKeyPair!;
                  showModalBottomSheet(
                    context: context,
                    isScrollControlled: true,
                    builder: (_) => BackupKeyWidget(
                      publicKeyHex: keyPair.publicKey,
                      privateKeyHex: keyPair.privateKey!,
                    ),
                  );
                },
              ),
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
                        return AddWalletWidget();
                      },
                    );
                  },
                  child: Text(AppLocalizations.of(context)!.connect),
                ),
                body: NostrWalletConnectContainerWidget(),
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
              BlocProvider(
                create: (_) =>
                    TrustedEscrowsCubit(hostr: getIt<Hostr>())..load(),
                child: BlocBuilder<TrustedEscrowsCubit, TrustedEscrowsState>(
                  builder: (context, state) {
                    return Section(
                      title: "Trusted Escrows",
                      action: FilledButton.tonal(
                        onPressed: () {
                          // TODO: implement add trusted escrow flow
                        },
                        child: Text(AppLocalizations.of(context)!.add),
                      ),
                      body: _buildTrustedEscrowsBody(context, state),
                    );
                  },
                ),
              ),
              Section(title: 'Balance', body: MoneyInFlightWidget()),

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
                            final params = ZapPayParameters(
                              to: 'tips@lnbits1.hostr.development',
                              amount: BitcoinAmount.fromInt(
                                BitcoinUnit.sat,
                                10000,
                              ),
                            );
                            showModalBottomSheet(
                              context: context,
                              builder: (context) {
                                return PaymentFlowWidget(
                                  cubit: getIt<Hostr>().payments.pay(params)
                                    ..resolve(),
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
                DevWidget(),
            ]),
          ),
        ],
      ),
    );
  }
}

Widget _buildTrustedEscrowsBody(
  BuildContext context,
  TrustedEscrowsState state,
) {
  if (state.loading && state.data == null) {
    return const CircularProgressIndicator();
  }
  final pubkeys = state.pubkeys;
  if (pubkeys.isEmpty) {
    return const Text("No escrows trusted yet");
  }
  return Column(
    children: [
      SizedBox(height: kDefaultPadding.toDouble() / 2),
      ...pubkeys.map((pubkey) {
        return ProfileProvider(
          pubkey: pubkey,
          builder: (context, profileSnapshot) {
            return TrustedEscrowListItemWidget(
              profile: profileSnapshot.data,
              onRemove: () {
                // TODO: implement remove and then refresh
                // context.read<TrustedEscrowsCubit>().refresh();
              },
            );
          },
        );
      }),
    ],
  );
}
