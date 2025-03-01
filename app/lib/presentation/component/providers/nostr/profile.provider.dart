import 'package:flutter/material.dart';
import 'package:hostr/injection.dart';
import 'package:ndk/ndk.dart';

class ProfileProvider extends StatelessWidget {
  final String pubkey;
  final Function(BuildContext context, Metadata? profile) builder;
  const ProfileProvider(
      {super.key, required this.pubkey, required this.builder});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getIt<Ndk>().metadata.loadMetadata(pubkey),
        builder: (context, snapshot) {
          return builder(context, snapshot.data);
        });
  }
}
