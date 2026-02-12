import 'package:flutter/material.dart';
import 'package:models/main.dart';

class ThreadHeaderWidget extends StatelessWidget {
  final List<ProfileMetadata> counterparties;
  final Widget? trailing;
  const ThreadHeaderWidget({
    super.key,
    required this.counterparties,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: ProfileAvatars(profiles: counterparties),
      title: Row(
        children: counterparties
            .map(
              (counterparty) => Text(counterparty.metadata.name ?? 'Unknown'),
            )
            .toList(),
      ),
      subtitle: Row(
        children: counterparties
            .map(
              (counterparty) => Text(
                counterparty.metadata.cleanNip05 ??
                    counterparty.metadata.lud06 ??
                    counterparty.metadata.lud16 ??
                    counterparty.metadata.pubKey,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            )
            .toList(),
      ),
      trailing: trailing,
    );
  }
}

class ProfileAvatars extends StatelessWidget {
  final List<ProfileMetadata> profiles;

  const ProfileAvatars({super.key, required this.profiles});
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40, // Adjust as needed for avatar size
      width: 40,
      child: Stack(
        children: profiles
            .map(
              (counterparty) => Positioned(
                left:
                    profiles.indexOf(counterparty) *
                    12.0, // 8 pixels offset for each
                child: CircleAvatar(
                  radius: 20,
                  backgroundImage: counterparty.metadata.picture != null
                      ? NetworkImage(counterparty.metadata.picture!)
                      : null,
                  child: counterparty.metadata.picture == null
                      ? Text(counterparty.metadata.name?[0] ?? '')
                      : null,
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}
