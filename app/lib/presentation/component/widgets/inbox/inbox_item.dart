import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/cubit/profile.cubit.dart';
import 'package:hostr/presentation/component/main.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../providers/nostr/thread.provider.dart';

class InboxItem extends StatelessWidget {
  final Thread thread;

  const InboxItem({super.key, required this.thread});

  @override
  Widget build(BuildContext context) {
    final lastDateTime = thread.getLastDateTime();
    final subtitle = Text(thread.isLastMessageOurs() ? 'Sent' : 'Received');

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<ProfilesProvider>.value(
          value: ProfilesProvider(
            profiles: thread
                .counterpartyPubkeys()
                .map((pubkey) => ProfileProvider(pubkey: pubkey))
                .toList(),
          ),
        ),
      ],
      child: Builder(
        builder: (BuildContext context) {
          // Collect all profile states using context.select
          final profileStates = context
              .read<ProfilesProvider>()
              .profiles
              .map(
                (cubit) => context.select<ProfileCubit, ProfileCubitState>(
                  (_) => cubit.state,
                ),
              )
              .toList();
          return ListTile(
            leading: ProfileAvatars(
              profiles: context
                  .read<ProfilesProvider>()
                  .profiles
                  .where((c) => c.state.data != null)
                  .map((c) => c.state.data!)
                  .toList(),
            ),
            title: Text('profiles'),

            subtitle: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                subtitle,
                Text(timeago.format(lastDateTime, locale: 'en_short')),
              ],
            ),
            onTap: () {
              AutoRouter.of(context).push(ThreadRoute(anchor: thread.anchor));
            },
          );
        },
      ),
    );
  }
}
