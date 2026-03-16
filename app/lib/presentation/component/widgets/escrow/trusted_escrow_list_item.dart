import 'package:flutter/material.dart';
import 'package:hostr/presentation/screens/shared/listing/blossom_image.dart';
import 'package:models/main.dart';

class TrustedEscrowListItemWidget extends StatelessWidget {
  final ProfileMetadata? profile;
  final VoidCallback? onTap;
  final VoidCallback? onRemove;

  const TrustedEscrowListItemWidget({
    super.key,
    required this.profile,
    this.onTap,
    this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final metadata = profile?.metadata;
    final title = metadata?.getName() ?? 'Unnamed';
    final subtitle = metadata?.nip05 ?? '';

    return ListTile(
      contentPadding: EdgeInsets.all(0),
      onTap: onTap,
      leading: CircleAvatar(
        radius: 20,
        backgroundColor: Theme.of(context).colorScheme.surfaceContainerHighest,
        child: metadata?.picture != null
            ? ClipOval(
                child: BlossomImage(
                  image: metadata!.picture!,
                  pubkey: profile!.pubKey,
                  width: 40,
                  height: 40,
                  fit: BoxFit.cover,
                ),
              )
            : Icon(Icons.security),
      ),

      title: Text(title),
      subtitle: Text(
        subtitle,
        style: Theme.of(context).textTheme.bodySmall?.copyWith(
          color: Theme.of(context).colorScheme.onSurfaceVariant,
        ),
      ),
      // trailing: onRemove == null
      //     ? null
      //     : IconButton(icon: const Icon(Icons.close), onPressed: onRemove),
    );
  }
}
