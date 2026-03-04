import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/presentation/component/providers/nostr/profile.provider.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/component/widgets/profile/verification/main.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr/presentation/screens/shared/listing/blossom_image.dart';
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
    return showAppModal(context, child: ProfilePopup(pubkey: pubkey));
  }

  @override
  State<ProfilePopup> createState() => _ProfilePopupState();
}

class _ProfilePopupState extends State<ProfilePopup> {
  final _verification = ProfileVerificationController();
  ProfileMetadata? _profile;

  @override
  void initState() {
    super.initState();
    _verification.addListener(_onChanged);
  }

  @override
  void dispose() {
    _verification
      ..removeListener(_onChanged)
      ..dispose();
    super.dispose();
  }

  void _onChanged() {
    if (mounted) setState(() {});
  }

  void _onProfileLoaded(ProfileMetadata? profile) {
    if (profile == null || _profile != null) return;
    _profile = profile;
    _verification.verify(profile);
  }

  @override
  Widget build(BuildContext context) {
    return ProfileProvider(
      pubkey: widget.pubkey,
      onDone: _onProfileLoaded,
      builder: (context, snapshot) {
        final profile = snapshot.data;
        final metadata = profile?.metadata;

        return ModalBottomSheet(
          leading: CircleAvatar(
            radius: 36,
            backgroundColor: Theme.of(
              context,
            ).colorScheme.surfaceContainerHighest,
            child: metadata?.picture != null
                ? ClipOval(
                    child: BlossomImage(
                      image: metadata!.picture!,
                      pubkey: widget.pubkey,
                      width: 72,
                      height: 72,
                      fit: BoxFit.cover,
                    ),
                  )
                : Text(
                    (metadata?.name ?? '?').characters.first.toUpperCase(),
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
          ),
          title: metadata?.name ?? metadata?.displayName ?? 'Unknown',
          subtitle: metadata?.about,
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // const Divider(height: 1),
              Gap.vertical.custom(kSpace3),

              // NIP-05 verification
              Nip05Badge(
                nip05: metadata?.nip05,
                result: _verification.nip05Result,
                loading: _verification.nip05Loading,
              ),

              Gap.vertical.sm(),

              // LUD-16 verification
              Lud16Badge(
                lud16: metadata?.lud16,
                result: _verification.lud16Result,
                loading: _verification.lud16Loading,
              ),

              Gap.vertical.md(),

              // Pubkey (truncated, copyable)
              _PubkeyRow(pubkey: widget.pubkey),
            ],
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
