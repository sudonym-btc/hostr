import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/widgets/ui/app_avatar.dart';
import 'package:hostr/presentation/component/widgets/ui/app_list_item.dart';
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

    return AppListItem(
      onTap: onTap,
      leading: AppAvatar.md(
        image: metadata?.picture,
        pubkey: profile?.pubKey,
        label: title,
        icon: Icons.security,
      ),
      title: Text(title),
      subtitle: Text(subtitle),
    );
  }
}
