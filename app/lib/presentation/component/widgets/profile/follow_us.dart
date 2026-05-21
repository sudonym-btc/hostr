import 'package:flutter/material.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/config/env/base.config.dart';
import 'package:hostr/core/util/npub_formatter.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/nostr/follow_list_update.dart';
import 'package:hostr/presentation/component/providers/nostr/profile.provider.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr/route/auth_gated_action.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:ndk/ndk.dart' show ContactList, Filter, Nip01Event, Nip19;
import 'package:qr_flutter/qr_flutter.dart';

enum _FollowUsPlacement { sidebar, profile }

class FollowUsWidget extends StatelessWidget {
  final _FollowUsPlacement _placement;

  const FollowUsWidget.sidebar({super.key})
    : _placement = _FollowUsPlacement.sidebar;

  const FollowUsWidget.profile({super.key})
    : _placement = _FollowUsPlacement.profile;

  @override
  Widget build(BuildContext context) {
    final accounts = followUsAccounts(getIt<Config>());
    if (accounts.isEmpty) return const SizedBox.shrink();

    return switch (_placement) {
      _FollowUsPlacement.sidebar => _SidebarFollowUsButton(
        onPressed: () => _open(context, accounts),
      ),
      _FollowUsPlacement.profile => _ProfileFollowUsPanel(
        onPressed: () => _open(context, accounts),
      ),
    };
  }

  Future<void> _open(BuildContext context, List<FollowUsAccount> accounts) {
    return authGatedAction(
      context,
      pendingRoute: TabShellRoute(children: [ProfileRoute()]),
      action: () async {
        await showAppModal(
          context,
          builder: (_) => _FollowUsModal(accounts: accounts),
        );
      },
    );
  }
}

@visibleForTesting
class FollowUsAccount {
  final String title;
  final String subtitle;
  final String pubkey;
  final IconData icon;

  const FollowUsAccount({
    required this.title,
    required this.subtitle,
    required this.pubkey,
    required this.icon,
  });

  FollowListTarget toTarget(String relayHint) {
    return FollowListTarget(
      pubkey: pubkey,
      relayHint: relayHint,
      petname: title,
    );
  }
}

@visibleForTesting
List<FollowUsAccount> followUsAccounts(Config config) {
  final mainPubkey = decodeConfiguredPubkey(config.hostrSocialNpub);
  final escrowPubkey = config.bootstrapEscrowPubkeys
      .map(decodeConfiguredPubkey)
      .whereType<String>()
      .firstOrNull;

  final accounts = <FollowUsAccount>[
    if (mainPubkey != null)
      FollowUsAccount(
        title: 'Hostr',
        subtitle: 'Main account',
        pubkey: mainPubkey,
        icon: Icons.travel_explore,
      ),
    if (escrowPubkey != null)
      FollowUsAccount(
        title: 'Hostr escrow',
        subtitle: 'Escrow account',
        pubkey: escrowPubkey,
        icon: Icons.verified_user,
      ),
  ];

  final seen = <String>{};
  return [
    for (final account in accounts)
      if (seen.add(account.pubkey)) account,
  ];
}

@visibleForTesting
String? decodeConfiguredPubkey(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return null;

  final hex = normalizeFollowPubkey(trimmed);
  if (hex != null) return hex;

  if (!Nip19.isPubkey(trimmed)) return null;
  try {
    return normalizeFollowPubkey(Nip19.decode(trimmed));
  } catch (_) {
    return null;
  }
}

class _SidebarFollowUsButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _SidebarFollowUsButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return Padding(
      padding: const EdgeInsets.fromLTRB(kSpace4, kSpace1, kSpace4, kSpace1),
      child: TextButton.icon(
        onPressed: onPressed,
        style: TextButton.styleFrom(
          foregroundColor: color,
          alignment: Alignment.center,
          minimumSize: const Size.fromHeight(40),
          padding: const EdgeInsets.symmetric(horizontal: kSpace2),
        ),
        icon: const Icon(Icons.person_add_alt_1, size: kIconMd),
        label: const Text('Follow us'),
      ),
    );
  }
}

class _ProfileFollowUsPanel extends StatelessWidget {
  final VoidCallback onPressed;

  const _ProfileFollowUsPanel({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.onSurfaceVariant;
    return CustomPadding(
      child: Row(
        children: [
          const Expanded(
            child: HelpText(
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              'Follow Hostr and escrow updates on Nostr.',
            ),
          ),
          Gap.horizontal.md(),
          TextButton.icon(
            onPressed: onPressed,
            style: TextButton.styleFrom(foregroundColor: color),
            icon: const Icon(Icons.person_add_alt_1),
            label: const Text('Follow us'),
          ),
        ],
      ),
    );
  }
}

class _FollowUsModal extends StatefulWidget {
  final List<FollowUsAccount> accounts;

  const _FollowUsModal({required this.accounts});

  @override
  State<_FollowUsModal> createState() => _FollowUsModalState();
}

class _FollowUsModalState extends State<_FollowUsModal> {
  late final Future<_FollowUsPreview> _preview = _loadPreview();

  Future<_FollowUsPreview> _loadPreview() async {
    final hostr = getIt<Hostr>();
    final activePubkey = hostr.auth.activePubkey;
    if (activePubkey == null || activePubkey.isEmpty) {
      throw StateError('Sign in before following Hostr.');
    }

    final existing = await _loadExistingFollowList(hostr, activePubkey);
    final update = buildFollowListUpdate(
      ownerPubkey: activePubkey,
      existingEvent: existing,
      targets: widget.accounts.map(
        (account) => account.toTarget(hostr.config.hostrRelay),
      ),
    );

    return _FollowUsPreview(update: update);
  }

  Future<Nip01Event?> _loadExistingFollowList(
    Hostr hostr,
    String activePubkey,
  ) async {
    final events = await hostr.requests
        .query<Nip01Event>(
          filter: Filter(
            kinds: [ContactList.kKind],
            authors: [activePubkey],
            limit: 1,
          ),
          name: 'follow-us-contact-list',
          timeout: const Duration(seconds: 8),
        )
        .toList();

    Nip01Event? latest;
    for (final event in events) {
      if (latest == null || event.createdAt > latest.createdAt) {
        latest = event;
      }
    }
    return latest;
  }

  Future<void> _publish(_FollowUsPreview preview) async {
    if (!preview.update.changed) return;

    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final hostr = getIt<Hostr>();
    final result = await hostr.requests.broadcastEvent(
      event: preview.update.event,
    );
    await hostr.ndk.config.cache.saveContactList(
      ContactList.fromEvent(result.event),
    );

    if (!mounted) return;
    navigator.pop();
    messenger.showSnackBar(
      const SnackBar(content: Text('Follow list updated')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_FollowUsPreview>(
      future: _preview,
      builder: (context, snapshot) {
        final preview = snapshot.data;
        final loading =
            snapshot.connectionState != ConnectionState.done && preview == null;
        final error = snapshot.error;

        return ModalBottomSheet(
          title: 'Follow Hostr',
          subtitle: 'Add these accounts to your Nostr follow list.',
          content: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ...widget.accounts.map(
                (account) => _FollowUsAccountPreview(
                  account: account,
                  followed:
                      preview != null &&
                      !preview.update.addedPubkeys.contains(account.pubkey),
                ),
              ),
              if (loading) ...[
                Gap.vertical.md(),
                const Center(child: AppLoadingIndicator.medium()),
              ],
              if (error != null) ...[
                Gap.vertical.md(),
                _FollowUsError(error: error),
              ],
              if (preview?.update.createsNewList == true) ...[
                Gap.vertical.md(),
                const _NewFollowListWarning(),
              ],
            ],
          ),
          buttons: _FollowUsButtons(
            preview: preview,
            error: error,
            onFollow: preview == null ? null : () => _publish(preview),
          ),
        );
      },
    );
  }
}

class _FollowUsPreview {
  final FollowListUpdate update;

  const _FollowUsPreview({required this.update});
}

class _FollowUsAccountPreview extends StatelessWidget {
  final FollowUsAccount account;
  final bool followed;

  const _FollowUsAccountPreview({
    required this.account,
    required this.followed,
  });

  @override
  Widget build(BuildContext context) {
    return ProfileProvider(
      pubkey: account.pubkey,
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final name = profile?.metadata.getName().trim() ?? '';
        final picture = profile?.metadata.picture;
        final title = name.isNotEmpty ? name : account.title;
        final npub = formatNpub(account.pubkey);

        return Padding(
          padding: const EdgeInsets.only(bottom: kSpace3),
          child: DecoratedBox(
            decoration: BoxDecoration(
              border: Border.all(
                color: Theme.of(context).colorScheme.outlineVariant,
              ),
              borderRadius: AppBorderRadii.sm,
            ),
            child: Padding(
              padding: const EdgeInsets.all(kSpace3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  AppListItem(
                    contentPadding: EdgeInsets.zero,
                    leading: _FollowPreviewLeading(
                      title: title,
                      npub: npub,
                      avatar: AppAvatar.md(
                        image: picture,
                        pubkey: account.pubkey,
                        label: title,
                        icon: account.icon,
                      ),
                    ),
                    title: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    subtitle: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(account.subtitle),
                        Text(
                          formatNpubPreview(account.pubkey, length: 18),
                          style: Theme.of(context).textTheme.labelSmall
                              ?.copyWith(
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                        ),
                      ],
                    ),
                    trailing: followed
                        ? Icon(
                            Icons.check_circle,
                            color: Theme.of(context).colorScheme.primary,
                          )
                        : null,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _FollowPreviewLeading extends StatelessWidget {
  final String title;
  final String npub;
  final Widget avatar;

  const _FollowPreviewLeading({
    required this.title,
    required this.npub,
    required this.avatar,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        _NpubQrThumbnail(title: title, npub: npub),
        Gap.horizontal.sm(),
        avatar,
      ],
    );
  }
}

class _NpubQrThumbnail extends StatelessWidget {
  final String title;
  final String npub;

  const _NpubQrThumbnail({required this.title, required this.npub});

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: 'Show QR',
      child: _QrFrame(
        data: 'nostr:$npub',
        size: 32,
        padding: const EdgeInsets.all(4),
        onTap: () => showAppModal(
          context,
          builder: (_) => _NpubQrModal(title: title, npub: npub),
        ),
      ),
    );
  }
}

class _NpubQrModal extends StatelessWidget {
  final String title;
  final String npub;

  const _NpubQrModal({required this.title, required this.npub});

  @override
  Widget build(BuildContext context) {
    final qrSize = (MediaQuery.sizeOf(context).width - kSpace8)
        .clamp(180.0, 280.0)
        .toDouble();

    return ModalBottomSheet(
      title: title,
      content: Center(
        child: _QrFrame(
          data: 'nostr:$npub',
          size: qrSize,
          padding: const EdgeInsets.all(kSpace4),
        ),
      ),
    );
  }
}

class _QrFrame extends StatelessWidget {
  final String data;
  final double size;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const _QrFrame({
    required this.data,
    required this.size,
    required this.padding,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final borderRadius = AppBorderRadii.xs;
    final qr = Padding(
      padding: padding,
      child: QrImageView(
        data: data,
        version: QrVersions.auto,
        size: size,
        padding: EdgeInsets.zero,
        backgroundColor: Colors.white,
        dataModuleStyle: const QrDataModuleStyle(
          dataModuleShape: QrDataModuleShape.square,
          color: Colors.black,
        ),
        eyeStyle: const QrEyeStyle(
          eyeShape: QrEyeShape.square,
          color: Colors.black,
        ),
      ),
    );

    return Material(
      color: Colors.white,
      borderRadius: borderRadius,
      child: InkWell(borderRadius: borderRadius, onTap: onTap, child: qr),
    );
  }
}

class _NewFollowListWarning extends StatelessWidget {
  const _NewFollowListWarning();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: AppBorderRadii.sm,
      ),
      child: Padding(
        padding: const EdgeInsets.all(kSpace3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.warning_amber, color: scheme.onErrorContainer),
            Gap.horizontal.sm(),
            Expanded(
              child: Text(
                'No existing follow list was found. Publishing a new one can replace what other clients see if your real list was not discovered.',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: scheme.onErrorContainer,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _FollowUsError extends StatelessWidget {
  final Object error;

  const _FollowUsError({required this.error});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Text(
      'Could not check your follow list: $error',
      style: Theme.of(
        context,
      ).textTheme.bodyMedium?.copyWith(color: scheme.error),
    );
  }
}

class _FollowUsButtons extends StatelessWidget {
  final _FollowUsPreview? preview;
  final Object? error;
  final Future<void> Function()? onFollow;

  const _FollowUsButtons({
    required this.preview,
    required this.error,
    required this.onFollow,
  });

  @override
  Widget build(BuildContext context) {
    final update = preview?.update;
    final canFollow = error == null && update?.changed == true;
    final label = error != null
        ? 'Check failed'
        : update == null
        ? 'Checking follow list...'
        : update.changed
        ? update.createsNewList
              ? 'Create follow list'
              : 'Follow accounts'
        : 'Already following';

    return SizedBox(
      width: double.infinity,
      child: FutureButton.filled(
        onPressed: canFollow ? onFollow : null,
        child: Text(label),
      ),
    );
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull {
    final iterator = this.iterator;
    if (!iterator.moveNext()) return null;
    return iterator.current;
  }
}
