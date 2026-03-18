import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/presentation/component/providers/nostr/profile.provider.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/component/widgets/profile/verification/main.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
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
          content: ProfilePopupContent(profile: profile, pubkey: widget.pubkey),
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

  const ProfilePopupContent({
    super.key,
    required this.profile,
    required this.pubkey,
  });

  @override
  Widget build(BuildContext context) {
    final metadata = profile?.metadata;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Gap.vertical.sm(),
        VerifiedNip05Badge(
          nip05: metadata?.nip05,
          pubkey: profile!.pubKey,
          inline: false,
          hideWhenEmpty: false,
        ),
        Gap.vertical.sm(),
        VerifiedLud16Badge(
          lud16: metadata?.lud16,
          inline: false,
          hideWhenEmpty: false,
        ),
        Gap.vertical.sm(),
        _PubkeyRow(pubkey: pubkey),
      ],
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
                  fontFamily: 'monospace',
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
