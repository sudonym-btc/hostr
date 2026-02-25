import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/config/constants.dart';
import 'package:hostr/presentation/component/widgets/profile/profile_popup.dart';
import 'package:hostr/presentation/component/widgets/ui/main.dart';
import 'package:hostr/presentation/screens/shared/listing/blossom_image.dart';
import 'package:models/main.dart';

class ProfileHeaderWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: AppLoadingIndicator.large());
    }

    if (profile == null) {
      return CustomPadding(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(radius: 40, child: Icon(Icons.person, size: kIconXl)),
            Gap.vertical.md(),
            Text(
              AppLocalizations.of(context)!.noProfileSetUpYet,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            Gap.vertical.custom(kSpace3),
            if (onEditProfile != null)
              FilledButton.icon(
                onPressed: onEditProfile,
                icon: const Icon(Icons.edit),
                label: Text(AppLocalizations.of(context)!.editProfile),
              ),
          ],
        ),
      );
    }

    final metadata = profile?.metadata;
    final displayName = metadata?.name ?? metadata?.displayName ?? 'Username';
    final nip05 = metadata?.nip05 ?? 'nip05_address@example.com';
    final about = metadata?.about ?? '';

    return GestureDetector(
      onTap: () => ProfilePopup.show(context, profile!.pubKey),
      child: CustomPadding(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: Theme.of(
                context,
              ).colorScheme.surfaceContainerHighest,
              child: metadata?.picture != null
                  ? ClipOval(
                      child: BlossomImage(
                        image: metadata!.picture!,
                        pubkey: profile!.pubKey,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      ),
                    )
                  : Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : '?',
                    ),
            ),

            Gap.vertical.md(),
            Text(
              displayName,
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            Gap.vertical.sm(),
            Text(nip05, style: Theme.of(context).textTheme.bodyMedium),
            Gap.vertical.xs(),
            Text(
              about,
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: Colors.grey[600]),
            ),
          ],
        ),
      ),
    );
  }
}
