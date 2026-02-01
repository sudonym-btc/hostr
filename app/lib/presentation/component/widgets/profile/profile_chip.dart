import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/providers/nostr/profile.provider.dart';

class ProfileChipWidget extends StatelessWidget {
  final String id;

  const ProfileChipWidget({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return ProfileProvider(
      pubkey: id,
      builder: (context, snapshot) {
        var name = snapshot.data?.metadata.name ?? id;
        return ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: 200,
          ), // Set your desired max width here
          child: Chip(
            shape: StadiumBorder(),
            avatar: snapshot.data?.metadata.picture != null
                ? CircleAvatar(
                    backgroundImage: NetworkImage(
                      snapshot.data!.metadata.picture!,
                    ),
                  )
                : CircleAvatar(backgroundColor: Colors.grey),
            label: Text(name, overflow: TextOverflow.ellipsis, softWrap: false),
          ),
        );
      },
    );
  }
}
