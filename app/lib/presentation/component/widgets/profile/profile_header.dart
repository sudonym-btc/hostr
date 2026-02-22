import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/widgets/profile/profile_popup.dart';
import 'package:hostr/presentation/component/widgets/ui/padding.dart';
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
      return const Center(child: CircularProgressIndicator());
    }

    if (profile == null) {
      return CustomPadding(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(radius: 40, child: Icon(Icons.person, size: 40)),
            const SizedBox(height: 16),
            Text(
              'No profile set up yet',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            if (onEditProfile != null)
              FilledButton.icon(
                onPressed: onEditProfile,
                icon: const Icon(Icons.edit),
                label: const Text('Edit Profile'),
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
          children: [
            CircleAvatar(
              radius: 40,
              backgroundImage: metadata?.picture != null
                  ? NetworkImage(metadata!.picture!)
                  : null,
              child: metadata?.picture == null
                  ? Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : '?',
                    )
                  : null,
            ),
            const SizedBox(height: 16),
            Text(
              displayName,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(nip05, style: const TextStyle(fontSize: 14)),
            const SizedBox(height: 4),
            Text(
              about,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
