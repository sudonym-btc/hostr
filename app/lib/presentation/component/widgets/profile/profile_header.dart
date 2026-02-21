import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/widgets/ui/padding.dart';
import 'package:models/main.dart';

class ProfileHeaderWidget extends StatelessWidget {
  final ProfileMetadata? profile;
  final bool isLoading;

  const ProfileHeaderWidget({
    super.key,
    required this.profile,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final metadata = profile?.metadata;
    final displayName = metadata?.name ?? metadata?.displayName ?? 'Username';
    final nip05 = metadata?.nip05 ?? 'nip05_address@example.com';
    final about = metadata?.about ?? '';

    return CustomPadding(
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
                    displayName.isNotEmpty ? displayName[0].toUpperCase() : '?',
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
    );
  }
}
