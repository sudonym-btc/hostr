import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/escrow/escrow_services_modal.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/component/widgets/keys/backup_key.dart';
import 'package:hostr/presentation/component/widgets/nostr_wallet_connect/add_wallet.dart'
    show AddWalletWidget;
import 'package:hostr/presentation/layout/app_layout.dart';
import 'package:hostr/presentation/main.dart';
import 'package:hostr/presentation/screens/shared/profile/dev.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

import 'mode_toggle.dart';
import 'zap_us.dart';

@RoutePage()
class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AppConstrainedBody(
        maxWidth: kAppProfileMaxWidth,
        padding: EdgeInsets.zero,
        child: CustomScrollView(
          slivers: [
            SliverAppBar(
              pinned: true,
              actions: [
                IconButton(
                  icon: const Icon(Icons.key),
                  tooltip: 'Back up keys',
                  onPressed: () {
                    final auth = getIt<Hostr>().auth;
                    final keyPair = auth.activeKeyPair!;
                    showAppModal(
                      context,
                      child: BackupKeyWidget(
                        publicKeyHex: keyPair.publicKey,
                        privateKeyHex: keyPair.privateKey!,
                        mnemonic: auth.activeMnemonic,
                      ),
                    );
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.edit),
                  onPressed: () {
                    AutoRouter.of(context).navigate(EditProfileRoute());
                  },
                ),
                IconButton(
                  icon: const Icon(Icons.logout),
                  tooltip: AppLocalizations.of(context)!.logout,
                  color: Theme.of(context).colorScheme.error,
                  onPressed: () {
                    final router = AutoRouter.of(context);
                    final authCubit = BlocProvider.of<AuthCubit>(context);
                    showAppModal(
                      context,
                      child: ModalBottomSheet(
                        title: AppLocalizations.of(context)!.logout,
                        subtitle: AppLocalizations.of(context)!.areYouSure,
                        content: const SizedBox.shrink(),
                        buttons: Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            FilledButton(
                              style: FilledButton.styleFrom(
                                backgroundColor: Theme.of(
                                  context,
                                ).colorScheme.error,
                                foregroundColor: Theme.of(
                                  context,
                                ).colorScheme.onError,
                              ),
                              onPressed: () async {
                                Navigator.of(context).pop();
                                await authCubit.logout();
                                await router.replaceAll([
                                  SignInRoute(),
                                ], onFailure: (failure) => throw failure);
                              },
                              child: Text(AppLocalizations.of(context)!.ok),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
            SliverToBoxAdapter(
              child: ProfileProvider(
                pubkey: getIt<Hostr>().auth.activeKeyPair!.publicKey,
                builder: (context, snapshot) => ProfileHeaderWidget(
                  profile: snapshot.data,
                  isLoading: snapshot.connectionState != ConnectionState.done,
                  onEditProfile: () {
                    AutoRouter.of(context).navigate(EditProfileRoute());
                  },
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                ModeToggleWidget(),
                Section(
                  title: AppLocalizations.of(context)!.wallet,
                  action: OutlinedButton(
                    onPressed: () {
                      showAppModal(context, child: AddWalletWidget());
                    },
                    child: Text(AppLocalizations.of(context)!.connect),
                  ),
                  body: NostrWalletConnectContainerWidget(),
                ),
                Section(
                  title: 'Relays',
                  // @todo: reenable
                  // action: OutlinedButton(
                  //   onPressed: () {
                  //     showAppModal(
                  //       context,
                  //       child: RelayFlowWidget(
                  //         onClose: () {
                  //           Navigator.of(context).pop();
                  //         },
                  //       ),
                  //     );
                  //   },
                  //   child: Text(AppLocalizations.of(context)!.connect),
                  // ),
                  body: RelayListWidget(),
                ),
                BlocProvider(
                  create: (_) =>
                      TrustedEscrowsCubit(hostr: getIt<Hostr>())..load(),
                  child: BlocBuilder<TrustedEscrowsCubit, TrustedEscrowsState>(
                    builder: (context, state) {
                      return Section(
                        title: 'Escrows',
                        // @todo: reenable
                        // action: OutlinedButton(
                        //   onPressed: () {
                        //     showTrustEscrowModal(
                        //       context,
                        //       trustedPubkeys: state.pubkeys,
                        //       onTrusted: () {
                        //         context.read<TrustedEscrowsCubit>().refresh();
                        //       },
                        //     );
                        //   },
                        //   child: Text(AppLocalizations.of(context)!.add),
                        // ),
                        body: _buildTrustedEscrowsBody(context, state),
                      );
                    },
                  ),
                ),
                Section(
                  title: 'Balance',
                  action: IconButton(
                    icon: const Icon(Icons.key),
                    tooltip: 'Copy mnemonic',
                    onPressed: () {
                      final mnemonic = getIt<Hostr>().auth
                          .getEvmMnemonic()
                          .join(' ');
                      Clipboard.setData(ClipboardData(text: mnemonic));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Mnemonic copied to clipboard'),
                        ),
                      );
                    },
                  ),
                  body: MoneyInFlightWidget(),
                ),
                Section(
                  body: StreamBuilder<HostrUserConfig>(
                    stream: getIt<Hostr>().userConfig.stream,
                    builder: (context, snapshot) {
                      final enabled =
                          snapshot.data?.autoWithdrawEnabled ?? true;
                      return SwitchListTile.adaptive(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Auto-withdraw'),
                        subtitle: const Text(
                          'Automatically sweep received funds into your Lightning wallet',
                        ),
                        value: enabled,
                        onChanged: (value) async {
                          final current = await getIt<Hostr>().userConfig.state;
                          await getIt<Hostr>().userConfig.update(
                            current.copyWith(autoWithdrawEnabled: value),
                          );
                        },
                      );
                    },
                  ),
                ),
                const ZapUsWidget(),
                if (const bool.fromEnvironment('dart.vm.product') == false)
                  DevWidget(),
              ]),
            ),
          ],
        ),
      ),
    );
  }
}

Widget _buildTrustedEscrowsBody(
  BuildContext context,
  TrustedEscrowsState state,
) {
  if (state.loading && state.data == null) {
    return const AppLoadingIndicator.large();
  }
  final pubkeys = state.pubkeys;
  if (pubkeys.isEmpty) {
    return Text(
      AppLocalizations.of(context)!.noEscrowsTrustedYet,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
  return Column(
    children: [
      Gap.vertical.md(),
      ...pubkeys.map((pubkey) {
        return ProfileProvider(
          pubkey: pubkey,
          builder: (context, profileSnapshot) {
            return TrustedEscrowListItemWidget(
              profile: profileSnapshot.data,
              onTap: () {
                showEscrowServicesModal(context, pubkey);
              },
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
