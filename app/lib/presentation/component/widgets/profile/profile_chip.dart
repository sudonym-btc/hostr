import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/providers/nostr/profile.provider.dart';

class ProfileChip extends StatelessWidget {
  final String id;

  const ProfileChip({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return ProfileProvider(
        e: id,
        builder: (context, state) {
          var name = state.data?.parsedContent.name ?? id;
          return ConstrainedBox(
              constraints: BoxConstraints(
                  maxWidth: 200), // Set your desired max width here
              child: Chip(
                  shape: StadiumBorder(),
                  avatar: state.data?.parsedContent.picture != null
                      ? CircleAvatar(
                          backgroundImage:
                              NetworkImage(state.data!.parsedContent.picture!),
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
