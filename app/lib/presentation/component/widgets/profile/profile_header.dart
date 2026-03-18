import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/presentation/component/widgets/profile/profile_popup.dart';
import 'package:hostr/presentation/component/widgets/profile/verification/main.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:models/main.dart';

class ProfileHeaderWidget extends StatefulWidget {
  final ProfileMetadata? profile;
  final bool isLoading;
  final VoidCallback? onEditProfile;

  const ProfileHeaderWidget({
    super.key,
    required this.profile,
    this.isLoading = false,
    this.onEditProfile,
  });

  @override
  State<ProfileHeaderWidget> createState() => _ProfileHeaderWidgetState();
}

class _ProfileHeaderWidgetState extends State<ProfileHeaderWidget> {
  final _verification = ProfileVerificationController();
  String? _lastVerifiedPubkey;

  @override
  void initState() {
    super.initState();
    _verification.addListener(_onVerificationChanged);
  }

  @override
  void dispose() {
    _verification
      ..removeListener(_onVerificationChanged)
      ..dispose();
    super.dispose();
  }

  void _onVerificationChanged() {
    if (mounted) setState(() {});
  }

  @override
  void didUpdateWidget(covariant ProfileHeaderWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.profile != null &&
        widget.profile!.pubKey != _lastVerifiedPubkey) {
      _lastVerifiedPubkey = widget.profile!.pubKey;
      _verification.verify(widget.profile!);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.isLoading) {
      return const Center(child: AppLoadingIndicator.large());
    }

    if (widget.profile == null) {
      return EmtyResultsWidget(
        leading: AppAvatar.xl(icon: Icons.person_outline),
        title: AppLocalizations.of(context)!.setupYourProfile,
        subtitle:
            'Add your name, photo, and bio so others can get to know you.',
        action: widget.onEditProfile == null
            ? null
            : FilledButton.icon(
                onPressed: widget.onEditProfile,
                icon: const Icon(Icons.edit),
                label: Text(AppLocalizations.of(context)!.editProfile),
              ),
      );
    }

    // Trigger verification on first build with a non-null profile.
    if (_lastVerifiedPubkey == null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _lastVerifiedPubkey = widget.profile!.pubKey;
        _verification.verify(widget.profile!);
      });
    }

    final metadata = widget.profile?.metadata;
    final displayName = metadata?.name ?? metadata?.displayName ?? 'Username';
    final about = metadata?.about ?? '';

    return GestureDetector(
      onTap: () => ProfilePopup.show(context, widget.profile!.pubKey),
      child: CustomPadding(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AppAvatar.xl(
              image: metadata?.picture,
              pubkey: widget.profile?.pubKey,
              label: displayName,
            ),

            Gap.vertical.md(),
            Text(
              displayName,
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            if (metadata?.nip05 != null && metadata!.nip05!.isNotEmpty) ...[
              Gap.vertical.sm(),
              Nip05Badge(
                nip05: metadata.nip05,
                result: _verification.nip05Result,
                loading: _verification.nip05Loading,
                inline: true,
                hideWhenEmpty: true,
              ),
            ],
            if (metadata?.lud16 != null && metadata!.lud16!.isNotEmpty) ...[
              Gap.vertical.xs(),
              Lud16Badge(
                lud16: metadata.lud16,
                result: _verification.lud16Result,
                loading: _verification.lud16Loading,
                inline: true,
                hideWhenEmpty: true,
              ),
            ],
            if (about.isNotEmpty) Gap.vertical.xs(),
            if (about.isNotEmpty)
              Text(
                about,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
