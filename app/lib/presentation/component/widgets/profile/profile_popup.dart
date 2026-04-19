import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/providers/nostr/profile.provider.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/component/widgets/listing_badges_widget.dart';
import 'package:hostr/presentation/component/widgets/profile/verification/main.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';

/// A popup card that displays profile information with verification badges.
///
/// Shows:
/// - Avatar, display name, about text
/// - NIP-05 verification badge (verified/unverified/pending)
/// - LUD-16 (Lightning Address) reachability + nostr pubkey match
class ProfilePopup extends StatefulWidget {
  final String pubkey;

  const ProfilePopup({super.key, required this.pubkey});

  /// Show the profile popup as a modal bottom sheet.
  static Future<void> show(BuildContext context, String pubkey) {
    return showAppModal(context, builder: (_) => ProfilePopup(pubkey: pubkey));
  }

  @override
  State<ProfilePopup> createState() => _ProfilePopupState();
}

class _ProfilePopupState extends State<ProfilePopup> {
  late final Future<ReceivedHeartbeat?> _lastSeenFuture;

  @override
  void initState() {
    super.initState();
    _lastSeenFuture = getIt<Hostr>().heartbeats.latestForUser(widget.pubkey);
  }

  @override
  Widget build(BuildContext context) {
    return ProfileProvider(
      pubkey: widget.pubkey,
      builder: (context, snapshot) {
        final profile = snapshot.data;

        return ModalBottomSheet(
          leading: ProfilePopupAvatar(profile: profile),
          title: ProfilePopupTitle(profile),
          subtitle: profile?.metadata.about,
          content: ProfilePopupContent(
            profile: profile,
            pubkey: widget.pubkey,
            lastSeenFuture: _lastSeenFuture,
          ),
          buttons: Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(AppLocalizations.of(context)!.close),
            ),
          ),
        );
      },
    );
  }
}

class ProfilePopupAvatar extends StatelessWidget {
  final ProfileMetadata? profile;

  const ProfilePopupAvatar({super.key, required this.profile});

  @override
  Widget build(BuildContext context) {
    final metadata = profile?.metadata;
    return AppAvatar.lg(
      image: metadata?.picture,
      pubkey: profile?.pubKey,
      label: metadata?.getName() ?? '?',
    );
  }
}

String ProfilePopupTitle(ProfileMetadata? profile) {
  final metadata = profile?.metadata;
  return metadata?.getName() ?? 'Unknown';
}

class ProfilePopupContent extends StatelessWidget {
  final ProfileMetadata? profile;
  final String pubkey;
  final Future<ReceivedHeartbeat?>? lastSeenFuture;
  final bool showListingBadges;
  final bool showNPub;

  const ProfilePopupContent({
    super.key,
    required this.profile,
    required this.pubkey,
    this.lastSeenFuture,
    this.showListingBadges = true,
    this.showNPub = true,
  });

  @override
  Widget build(BuildContext context) {
    final metadata = profile?.metadata;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showListingBadges) ...[BadgesWidget(pubKey: pubkey)],
        if (lastSeenFuture != null) _LastSeenRow(future: lastSeenFuture!),
        if (metadata?.nip05 != null && metadata?.nip05?.isNotEmpty == true) ...[
          Gap.vertical.sm(),
          VerifiedNip05Badge(
            nip05: metadata?.nip05,
            pubkey: profile?.pubKey ?? pubkey,
          ),
        ],
        if (metadata?.lud16 != null && metadata?.lud16?.isNotEmpty == true) ...[
          Gap.vertical.sm(),

          VerifiedLud16Badge(lud16: metadata?.lud16),
        ],
        if (metadata?.website != null &&
            metadata?.website?.isNotEmpty == true) ...[
          Gap.vertical.sm(),

          Row(
            children: [
              Icon(
                Icons.link,
                size: kIconSm,
                color: Theme.of(context).colorScheme.outline,
              ),
              Gap.horizontal.xs(),
              Expanded(
                child: Text(
                  metadata!.website!,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ],
          ),
        ],
        if (showNPub) _PubkeyRow(pubkey: pubkey),
      ],
    );
  }
}

// ─── Last seen row ───────────────────────────────────────────────────────────

class _LastSeenRow extends StatelessWidget {
  final Future<ReceivedHeartbeat?> future;

  const _LastSeenRow({required this.future});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return FutureBuilder<ReceivedHeartbeat?>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Padding(
            padding: const EdgeInsets.only(top: 8),
            child: ShimmerPlaceholder(
              loading: true,
              borderRadius: BorderRadius.circular(4),
              child: const SizedBox(height: 13, width: 90),
            ),
          );
        }
        final heartbeat = snapshot.data;
        if (heartbeat == null) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Row(
            children: [
              Icon(
                Icons.access_time_outlined,
                size: kIconSm,
                color: theme.colorScheme.outline,
              ),
              Gap.horizontal.sm(),
              RelativeTimeText(
                dateTime: heartbeat.receivedAt,
                locale: Localizations.localeOf(context).languageCode,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
                builder: (context, text) => Text(
                  'Last seen $text',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.outline,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ─── Pubkey row ────────────────────────────────────────────────

class _PubkeyRow extends StatelessWidget {
  final String pubkey;

  const _PubkeyRow({required this.pubkey});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final npub = Helpers.encodeBech32(pubkey, 'npub');
    final truncated =
        '${npub.substring(0, 10)}…${npub.substring(npub.length - 8)}';

    return InkWell(
      borderRadius: BorderRadius.circular(8),
      onTap: () {
        Clipboard.setData(ClipboardData(text: npub));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(AppLocalizations.of(context)!.publicKeyCopied),
            duration: Duration(seconds: 1),
          ),
        );
      },
      child: CustomPadding.vertical.sm(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.key, size: kIconMd, color: theme.colorScheme.outline),
            Gap.horizontal.sm(),
            Expanded(
              child: Text(
                truncated,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.outline,
                ),
              ),
            ),
            Icon(Icons.copy, size: kIconSm, color: theme.colorScheme.outline),
          ],
        ),
      ),
    );
  }
}
