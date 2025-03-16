import 'package:flutter/material.dart';
import 'package:hostr/injection.dart';
import 'package:ndk/ndk.dart';

class ProfileProvider extends StatelessWidget {
  final String pubkey;
  final Function(BuildContext context, AsyncSnapshot<Metadata?> profile)
      builder;
  final Function(Metadata? metadata)? onDone;
  const ProfileProvider(
      {super.key, required this.pubkey, required this.builder, this.onDone});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getIt<Ndk>().metadata.loadMetadata(pubkey).then((metadata) {
          if (onDone != null) {
            onDone!(metadata);
          }
          return metadata;
        }),
        builder: (context, snapshot) {
          return builder(context, snapshot);
        });
  }
}
