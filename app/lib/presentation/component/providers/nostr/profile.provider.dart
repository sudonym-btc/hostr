import 'package:flutter/material.dart';
import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:provider/single_child_widget.dart';

class ProfileProvider extends SingleChildStatelessWidget {
  final String pubkey;
  final Function(BuildContext context, AsyncSnapshot<ProfileMetadata?> profile)?
  builder;
  final Function(ProfileMetadata? metadata)? onDone;
  const ProfileProvider({
    super.key,
    required this.pubkey,
    this.builder,
    this.onDone,
  });
  @override
  Widget buildWithChild(BuildContext context, Widget? child) {
    return FutureBuilder(
      future: getIt<Hostr>().metadata.loadMetadata(pubkey).then((metadata) {
        if (onDone != null) {
          onDone!(metadata);
        }
        return metadata;
      }),
      builder: (context, snapshot) {
        return builder != null ? builder!(context, snapshot) : child;
      },
    );
  }
}
