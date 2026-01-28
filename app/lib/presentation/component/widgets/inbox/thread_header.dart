import 'package:flutter/material.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:ndk/ndk.dart';

class ThreadHeaderWidget extends StatelessWidget {
  final Metadata? metadata;
  final Widget? trailing;
  const ThreadHeaderWidget({super.key, this.metadata, this.trailing});

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: metadata?.picture != null
            ? NetworkImage(metadata!.picture!)
            : null,
        child: metadata?.picture == null
            ? Text(metadata?.name?[0] ?? '')
            : null,
      ),
      title: Text(metadata?.name ?? AppLocalizations.of(context)!.loading),
      subtitle: Text(
        metadata?.cleanNip05 ??
            metadata?.lud06 ??
            metadata?.lud16 ??
            metadata?.pubKey ??
            '',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: trailing,
    );
  }
}
