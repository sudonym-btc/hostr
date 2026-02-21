import 'package:flutter/material.dart';
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
    final title = metadata?.name ?? metadata?.displayName ?? 'Username';
    final subtitle = metadata?.nip05 ?? '';

    return ListTile(
      contentPadding: EdgeInsets.all(0),
      onTap: onTap,
      leading: CircleAvatar(
        backgroundImage: metadata?.picture != null
            ? NetworkImage(metadata!.picture!)
            : null,
        child: metadata?.picture == null
            ? Text((title.isNotEmpty ? title[0] : '?').toUpperCase())
            : null,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: onRemove == null
          ? null
          : IconButton(icon: const Icon(Icons.close), onPressed: onRemove),
    );
  }
}
