import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/models/nostr_kind/profile.dart';
import 'package:hostr/logic/main.dart';

class ProfileChip extends StatelessWidget {
  final String id;

  const ProfileChip({super.key, required this.id});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EntityCubit<Profile>>(
        create: (context) => EntityCubit<Profile>(
            filter: NostrFilter(kinds: Profile.kinds, p: [id]))
          ..get(),
        child: BlocBuilder<EntityCubit<Profile>, EntityCubitState<Profile>>(
            builder: (context, state) {
          print('profile state ${state}');
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
        }));
  }
}
