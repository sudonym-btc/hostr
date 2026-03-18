import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/escrow/escrow_services_modal.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/component/widgets/nostr_wallet_connect/add_wallet.dart'
    show AddWalletWidget;
import 'package:hostr/presentation/component/widgets/profile/profile_popup.dart';
import 'package:hostr/presentation/main.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

import 'dev.dart';
import 'mode_toggle.dart';
import 'zap_us.dart';

class ProfileSummarySection extends StatelessWidget {
  final ProfileMetadata? profile;
  const ProfileSummarySection({super.key, this.profile});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        profile == null
            ? EmtyResultsWidget(
                title: AppLocalizations.of(context)!.setupYourProfile,
                subtitle:
                    'Add your name, photo, and bio so others can get to know you.',
                action: FilledButton.icon(
                  onPressed: () {
                    AutoRouter.of(context).navigate(EditProfileRoute());
                  },
                  icon: const Icon(Icons.edit),
                  label: Text(AppLocalizations.of(context)!.editProfile),
                ),
              )
            : CustomPadding(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const ModeToggleWidget(),

                    if ((profile!.metadata.about ?? '').isNotEmpty) ...[
                      Gap.vertical.xs(),
                      Text(
                        profile!.metadata.about!,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],

                    ProfilePopupContent(
                      profile: profile,
                      pubkey: profile!.pubKey,
                    ),
                  ],
                ),
              ),
      ],
    );
  }
}

class ProfileSettingsSection extends StatelessWidget {
  const ProfileSettingsSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
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
        const Section(title: 'Relays', body: RelayListWidget()),
        BlocProvider(
          create: (_) => TrustedEscrowsCubit(hostr: getIt<Hostr>())..load(),
          child: BlocBuilder<TrustedEscrowsCubit, TrustedEscrowsState>(
            builder: (context, state) {
              return Section(
                title: 'Escrows',
                body: _TrustedEscrowsBody(state: state),
              );
            },
          ),
        ),
        Section(
          title: 'Balance',
          action: IconButton(
            icon: const Icon(Icons.key),
            tooltip: 'Copy mnemonic',
            onPressed: () async {
              final mnemonic = (await getIt<Hostr>().auth.hd.getEvmMnemonic())
                  .join(' ');
              Clipboard.setData(ClipboardData(text: mnemonic));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Mnemonic copied to clipboard')),
              );
            },
          ),
          body: MoneyInFlightWidget(),
        ),
        Section(
          body: StreamBuilder<HostrUserConfig>(
            stream: getIt<Hostr>().userConfig.stream,
            builder: (context, snapshot) {
              final enabled = snapshot.data?.autoWithdrawEnabled ?? true;
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
          const DevWidget(),
      ],
    );
  }
}

class _TrustedEscrowsBody extends StatelessWidget {
  final TrustedEscrowsState state;

  const _TrustedEscrowsBody({required this.state});

  @override
  Widget build(BuildContext context) {
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
}
