import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/providers/nostr/profile.provider.dart';

class ProfileChipWidget extends StatelessWidget {
  final String id;

  const ProfileChipWidget({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return ProfileProvider(
        pubkey: id,
        builder: (context, state) {
          var name = state.name ?? id;
          return ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: 200), // Set your desired max width here
              child: Chip(
                  shape: StadiumBorder(),
                  avatar: state.picture != null
                      ? CircleAvatar(
                          backgroundImage: NetworkImage(state.picture!),
                        )
                      : CircleAvatar(
                          backgroundColor: Colors.grey,
                        ),
                  label: Text(
                    name,
                    overflow: TextOverflow.ellipsis,
                  )));
        });
  }
}
