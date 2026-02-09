import 'package:flutter/material.dart';
import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/nostr/main.dart';

class ProfileProvider extends StatelessWidget {
  final String pubkey;
  final Function(BuildContext context, AsyncSnapshot<ProfileMetadata?> profile)
  builder;
  final Function(ProfileMetadata? metadata)? onDone;
  const ProfileProvider({
    super.key,
    required this.pubkey,
    required this.builder,
    this.onDone,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: getIt<Hostr>().metadata.loadMetadata(pubkey).then((metadata) {
        if (onDone != null) {
          onDone!(metadata);
        }
        return metadata;
      }),
      builder: (context, snapshot) {
        return builder(context, snapshot);
      },
    );
  }
}
