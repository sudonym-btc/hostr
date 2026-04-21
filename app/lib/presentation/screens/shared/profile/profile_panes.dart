import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/widgets/escrow/escrow_services_modal.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/component/widgets/flow/payment/swap/out/swap_out.dart';
import 'package:hostr/presentation/component/widgets/profile/profile_popup.dart';
import 'package:hostr/presentation/layout/app_layout.dart';
import 'package:hostr/presentation/main.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;

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
                  style: AppButtonStyles.secondary(context),
                  icon: const Icon(Icons.edit),
                  label: Text(AppLocalizations.of(context)!.editProfile),
                ),
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  ProfileHeader(profile: profile!),
                  CustomPadding(child: const ModeToggleWidget()),
                ],
              ),
      ],
    );
  }
}

class ProfileHeader extends StatelessWidget {
  final ProfileMetadata profile;
  const ProfileHeader({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final name = profile.metadata.getName();
    final picture = profile.metadata.picture;
    final hasPicture = picture != null && picture.isNotEmpty;
    final about = profile.metadata.about ?? '';

    return CustomPadding(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Gap.vertical.lg(),
          AppAvatar.custom(
            radius: 48,
            image: hasPicture ? picture : null,
            pubkey: hasPicture ? profile.pubKey : null,
            label: name.isNotEmpty ? name : null,
            icon: Icons.person,
          ),
          Gap.vertical.lg(),
          Gap.vertical.lg(),
          if (about.isNotEmpty) ...[
            Text(
              about,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Gap.vertical.lg(),
          ],
          ProfilePopupContent(
            profile: profile,
            pubkey: profile.pubKey,
            showListingBadges: false,
            showNPub: false,
            centerContactItems: true,
          ),
        ],
      ),
    );
  }
}

/// The non-header scrollable body for the profile summary pane
/// (mode toggle, etc). Used as a [SliverToBoxAdapter] child when the
/// parallax sliver path is active.
class ProfileSummaryBody extends StatelessWidget {
  final ProfileMetadata profile;
  const ProfileSummaryBody({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    return CustomPadding(child: const ModeToggleWidget());
  }
}

class ProfileSettingsSection extends StatelessWidget {
  const ProfileSettingsSection({super.key});

  List<Widget> _buildSections(BuildContext context) {
    return [
      // TODO: Re-enable wallet section
      // Section(
      //   title: AppLocalizations.of(context)!.wallet,
      //   action: OutlinedButton(
      //     onPressed: () {
      //       showAppModal(context, builder: (_) => AddWalletWidget());
      //     },
      //     child: Text(AppLocalizations.of(context)!.connect),
      //   ),
      //   body: NostrWalletConnectContainerWidget(),
      // ),
      const Section(title: 'Relays', body: RelayListWidget()),
      // TODO: Re-enable escrows section
      // BlocProvider(
      //   create: (_) => TrustedEscrowsCubit(hostr: getIt<Hostr>())..load(),
      //   child: BlocBuilder<TrustedEscrowsCubit, TrustedEscrowsState>(
      //     builder: (context, state) {
      //       return Section(
      //         title: 'Escrows',
      //         body: _TrustedEscrowsBody(state: state),
      //       );
      //     },
      //   ),
      // ),
      Section(
        title: 'Balance',
        action: IconButton(
          icon: const Icon(Icons.key),
          tooltip: 'Copy EVM mnemonic',
          onPressed: () async {
            final mnemonic = (await getIt<Hostr>().auth.hd.getEvmMnemonic())
                .join(' ');
            if (!context.mounted) return;
            copyTextToClipboard(context, mnemonic);
          },
        ),
        body: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _BalanceSectionBody(),
            Gap.vertical.sm(),
            const _AutoWithdrawSectionBody(),
          ],
        ),
      ),
    ];
  }

  Widget _buildFooter() {
    return AppSurface(
      child: Column(
        children: [
          const ZapUsWidget(),
          if (const bool.fromEnvironment('dart.vm.product') == false)
            const DevWidget(),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final sections = _buildSections(context);
        final footer = _buildFooter();

        // Expanded viewport: height is bounded → use CustomScrollView so the
        // pane scrolls independently and SliverFillRemaining pushes the footer
        // to the bottom when there is spare space.
        if (constraints.hasBoundedHeight) {
          return CustomScrollView(
            slivers: [
              SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: sections,
                ),
              ),
              SliverFillRemaining(
                hasScrollBody: false,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [Gap.vertical.md(), footer],
                ),
              ),
            ],
          );
        }

        // Compact/stacked viewport: height is unbounded (sits inside an outer
        // SingleChildScrollView).  Use a plain Column — no inner scroll view.
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [...sections, Gap.vertical.md(), footer],
        );
      },
    );
  }
}

// ── Balance section: individual FundsItem list ─────────────────────────────

class _BalanceSectionBody extends StatefulWidget {
  const _BalanceSectionBody();

  @override
  State<_BalanceSectionBody> createState() => _BalanceSectionBodyState();
}

class _BalanceSectionBodyState extends State<_BalanceSectionBody> {
  late final Stream<List<FundsItem>> _fundsStream;
  late final TokenDisplayResolver _resolver;

  @override
  void initState() {
    super.initState();
    final hostr = getIt<Hostr>();
    _fundsStream = hostr.fundsMonitor.fundsStream$;
    _resolver = TokenDisplayResolver(
      hostr.evm.configuredChains.map((c) => c.config),
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<FundsItem>>(
      stream: _fundsStream,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const AppLoadingIndicator.medium();
        }

        final items = snapshot.data!;
        if (items.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Text(
              'No funds on-chain',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          );
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            for (final item in items)
              _FundsItemTile(item: item, resolver: _resolver),
          ],
        );
      },
    );
  }
}

class _FundsItemTile extends StatelessWidget {
  final FundsItem item;
  final TokenDisplayResolver resolver;

  const _FundsItemTile({required this.item, required this.resolver});

  String _shortAddress(String address) {
    if (address.length <= 12) return address;
    return '${address.substring(0, 6)}…${address.substring(address.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final info = resolver.resolve(item.token);
    final tokenName = info.denomination.isNotEmpty
        ? info.denomination
        : item.token.tagId;
    final formattedAmount = formatAmount(
      item.balance.toDenominated(denomination: info.denomination),
      exact: false,
    );
    final address = item.address.eip55With0x;
    final addressType = item.isSmartAddress ? 'Smart' : 'EOA';
    final subtitleParts = [
      _shortAddress(address),
      addressType,
      if (item.isEscrowLocked) 'Escrow',
      if (item.dust) 'Unsweepable below swap limit',
    ];
    final subtitle = subtitleParts.join(' · ');
    final title = '$formattedAmount  $tokenName';

    return ListTile(
      dense: true,
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        item.dust
            ? Icons.grain
            : item.isEscrowLocked
            ? Icons.lock_outline
            : Icons.account_balance_wallet_outlined,
        size: 20,
      ),
      title: Text(
        title,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w600,
          color: item.dust
              ? Theme.of(context).colorScheme.onSurfaceVariant
              : null,
        ),
      ),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      trailing: item.dust
          ? AppChip.warning.xs(label: const Text('Dust'))
          : OutlinedButton(
              onPressed: () => _initiateWithdraw(context),
              child: const Text('Withdraw'),
            ),
    );
  }

  Future<void> _initiateWithdraw(BuildContext context) async {
    // Build swap-out params the same way as FundsMonitorService._swapOutParams
    Map<String, Call>? preLockCalls;
    if (item.isEscrowLocked) {
      final destination = await item.chain.getAccountAddress(item.keypair);
      final tokenAddress = EthereumAddress.fromHex(item.token.address);
      preLockCalls = {
        'withdraw': item.contract!.withdraw(
          WithdrawArgs(
            token: tokenAddress,
            ethKey: item.keypair,
            beneficiary: item.keypair.address,
            destination: destination,
          ),
        ),
      };
    }

    final params = SwapOutParams(
      evmKey: item.keypair,
      accountIndex: item.accountIndex,
      amountSpec: item.isEscrowLocked ? AmountSpec.input(item.balance) : null,
      preLockCalls: preLockCalls,
    );

    final swapOp = item.chain.swapOut(params: params);

    if (!context.mounted) return;
    showAppModal(context, builder: (_) => SwapOutFlowWidget(cubit: swapOp));
  }
}

// ── Auto-withdraw section: swap tracker list ───────────────────────────────

class _AutoWithdrawSectionBody extends StatefulWidget {
  const _AutoWithdrawSectionBody();

  @override
  State<_AutoWithdrawSectionBody> createState() =>
      _AutoWithdrawSectionBodyState();
}

class _AutoWithdrawSectionBodyState extends State<_AutoWithdrawSectionBody> {
  late Future<AutomaticInvoiceDestination> _destinationFuture;
  StreamSubscription? _nwcSub;
  StreamSubscription? _profileSub;

  @override
  void initState() {
    super.initState();
    _destinationFuture = _loadDestination();
    final hostr = getIt<Hostr>();
    _nwcSub = hostr.nwc.connectionsStream.listen((_) => _refreshDestination());
    _profileSub = hostr.metadata.updates.listen((profile) {
      if (profile.pubKey == hostr.auth.activeKeyPair?.publicKey) {
        _refreshDestination();
      }
    });
  }

  @override
  void dispose() {
    unawaited(_nwcSub?.cancel());
    unawaited(_profileSub?.cancel());
    super.dispose();
  }

  Future<AutomaticInvoiceDestination> _loadDestination() {
    return getIt<Hostr>().payments.resolveAutomaticInvoiceDestination();
  }

  void _refreshDestination() {
    if (!mounted) return;
    setState(() {
      _destinationFuture = _loadDestination();
    });
  }

  String _subtitleFor(AutomaticInvoiceDestination destination) {
    return switch (destination.type) {
      AutomaticInvoiceDestinationType.nwc =>
        'Automatically sweep funds to ${destination.label}',
      AutomaticInvoiceDestinationType.profileLightningAddress =>
        'Automatically sweep funds into ${destination.label}',
      AutomaticInvoiceDestinationType.missingProfileLightningAddress =>
        destination.error ?? 'Cannot sweep without a profile lightning address',
      AutomaticInvoiceDestinationType.invalidProfileLightningAddress =>
        destination.error ??
            'Cannot run with invalid profile lightning address',
    };
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Auto-withdraw toggle
        FutureBuilder<AutomaticInvoiceDestination>(
          future: _destinationFuture,
          builder: (context, destinationSnapshot) {
            final destination = destinationSnapshot.data;
            return StreamBuilder<HostrUserConfig>(
              stream: getIt<Hostr>().userConfig.stream,
              builder: (context, snapshot) {
                final enabled = snapshot.data?.autoWithdrawEnabled ?? true;
                return SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Auto-withdraw'),
                  subtitle: Text(
                    destination == null
                        ? 'Checking withdrawal destination'
                        : _subtitleFor(destination),
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
            );
          },
        ),
        Gap.vertical.sm(),
        // Swap-In operations
        _SwapTrackerSection<SwapInOperation>(
          title: 'Swap-In',
          stream: getIt<Hostr>().swapInTracker.stream,
          tileBuilder: (id, op) => _SwapInTile(id: id, operation: op),
        ),
        // Swap-Out operations
        _SwapTrackerSection<SwapOutOperation>(
          title: 'Swap-Out',
          stream: getIt<Hostr>().swapOutTracker.stream,
          tileBuilder: (id, op) => _SwapOutTile(id: id, operation: op),
        ),
      ],
    );
  }
}

class _SwapTrackerSection<T> extends StatelessWidget {
  final String title;
  final Stream<Map<String, T>> stream;
  final Widget Function(String id, T op) tileBuilder;

  const _SwapTrackerSection({
    required this.title,
    required this.stream,
    required this.tileBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, T>>(
      stream: stream,
      builder: (context, snapshot) {
        final ops = snapshot.data ?? {};
        if (ops.isEmpty) return const SizedBox.shrink();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.only(top: 8, bottom: 4),
              child: Text(
                title,
                style: Theme.of(
                  context,
                ).textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
            for (final entry in ops.entries)
              tileBuilder(entry.key, entry.value),
          ],
        );
      },
    );
  }
}

class _SwapInTile extends StatelessWidget {
  final String id;
  final SwapInOperation operation;

  const _SwapInTile({required this.id, required this.operation});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SwapInState>(
      stream: operation.stream,
      initialData: operation.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? operation.state;
        final data = state.data;
        final stateName = state.stateName;
        final errorMessage = state is SwapInFailed
            ? state.error.toString()
            : null;
        final amountSats = data?.onchainAmountSat;
        final postCalls = data?.postClaimCalls?.length ?? 0;
        final boltzId = data?.boltzId ?? id;
        final short = boltzId.length > 8
            ? '${boltzId.substring(0, 8)}…'
            : boltzId;

        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            errorMessage != null ? Icons.error_outline : Icons.arrow_downward,
            color: errorMessage != null
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.primary,
            size: 20,
          ),
          title: Text(
            '↓ $short${amountSats != null ? '  ₿ $amountSats sats' : ''}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            [
              stateName,
              if (postCalls > 0) '$postCalls post-claim call(s)',
              ?errorMessage,
            ].join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: errorMessage != null
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: _SwapTxMenu(
            items: [
              _SwapTxMenuItem(
                label: 'View Lock Tx',
                uri: _txExplorerUri(operation.chain.config, data?.lockupTxHash),
              ),
              _SwapTxMenuItem(
                label: 'View Claim Tx',
                uri: _txExplorerUri(operation.chain.config, data?.claimTxHash),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SwapOutTile extends StatelessWidget {
  final String id;
  final SwapOutOperation operation;

  const _SwapOutTile({required this.id, required this.operation});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<SwapOutState>(
      stream: operation.stream,
      initialData: operation.state,
      builder: (context, snapshot) {
        final state = snapshot.data ?? operation.state;
        final data = state.data;
        final stateName = state.stateName;
        final errorMessage = state is SwapOutFailed
            ? state.error.toString()
            : null;
        final preCalls = data?.preLockCalls?.length ?? 0;
        final boltzId = data?.boltzId ?? id;
        final short = boltzId.length > 8
            ? '${boltzId.substring(0, 8)}…'
            : boltzId;

        String? amountDisplay;
        if (data != null) {
          try {
            final weiHex = data.lockedAmountWeiHex;
            final wei = BigInt.parse(weiHex, radix: 16);
            if (wei > BigInt.zero) {
              amountDisplay = '${wei.toString()} wei';
            }
          } catch (_) {}
        }

        return ListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          leading: Icon(
            errorMessage != null ? Icons.error_outline : Icons.arrow_upward,
            color: errorMessage != null
                ? Theme.of(context).colorScheme.error
                : Theme.of(context).colorScheme.tertiary,
            size: 20,
          ),
          title: Text(
            '↑ $short${amountDisplay != null ? '  $amountDisplay' : ''}',
            style: Theme.of(
              context,
            ).textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          subtitle: Text(
            [
              stateName,
              if (state is SwapOutWaitingForTimelock)
                'refund available after block ${data?.timeoutBlockHeight}',
              if (preCalls > 0) '$preCalls pre-lock call(s)',
              ?data?.lastBoltzStatus,
              ?errorMessage,
            ].join(' · '),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: errorMessage != null
                  ? Theme.of(context).colorScheme.error
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          trailing: _SwapTxMenu(
            items: [
              _SwapTxMenuItem(
                label: 'View Lock Tx',
                uri: _txExplorerUri(operation.chain.config, data?.fundTxHash),
              ),
              _SwapTxMenuItem(
                label: 'View Refund Tx',
                uri: _txExplorerUri(operation.chain.config, data?.refundTxHash),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _SwapTxMenu extends StatelessWidget {
  final List<_SwapTxMenuItem> items;

  const _SwapTxMenu({required this.items});

  @override
  Widget build(BuildContext context) {
    final visibleItems = items.where((item) => item.uri != null).toList();
    if (visibleItems.isEmpty) return const SizedBox.shrink();

    return PopupMenuButton<Uri>(
      icon: const Icon(Icons.more_vert),
      tooltip: 'Swap transaction links',
      onSelected: (uri) =>
          unawaited(launchUrl(uri, mode: LaunchMode.externalApplication)),
      itemBuilder: (context) => [
        for (final item in visibleItems)
          PopupMenuItem<Uri>(
            value: item.uri!,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.open_in_new, size: 18),
                Gap.horizontal.sm(),
                Text(item.label),
              ],
            ),
          ),
      ],
    );
  }
}

class _SwapTxMenuItem {
  final String label;
  final Uri? uri;

  const _SwapTxMenuItem({required this.label, required this.uri});
}

Uri? _txExplorerUri(EvmChainConfig config, String? txHash) {
  final base = config.blockExplorerUrl;
  if (base == null || base.isEmpty || txHash == null || txHash.isEmpty) {
    return null;
  }

  final url = base.contains('{tx}')
      ? base.replaceAll('{tx}', txHash)
      : '${base.replaceFirst(RegExp(r'/*$'), '')}/tx/$txHash';
  return Uri.tryParse(url);
}

// ignore: unused_element
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
