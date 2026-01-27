import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/data/sources/local/key_storage.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/messaging/thread.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart' show EntityCubitStateError;
import 'package:hostr/presentation/component/providers/nostr/profile.provider.dart';
import 'package:hostr/router.dart';
import 'package:timeago/timeago.dart' as timeago;

class InboxItem extends StatelessWidget {
  final Thread thread;

  const InboxItem({super.key, required this.thread});

  String _getCounterpartyPubkey() {
    final ours = getIt<KeyStorage>().getActiveKeyPairSync()?.publicKey;
    if (ours == null) return 'unknown';

    final allPubkeys = thread.messages
        .expand(
          (e) => [
            e.pubKey,
            ...e.tags
                .where((t) => t.isNotEmpty && t[0] == 'p')
                .map((t) => t[1]),
          ],
        )
        .toSet()
        .where((pk) => pk != ours)
        .toList();

    return allPubkeys.isNotEmpty ? allPubkeys.first : 'unknown';
  }

  DateTime _getLastDateTime() {
    if (thread.messages.isEmpty) return DateTime.now();
    final latest = thread.messages.reduce(
      (a, b) => a.createdAt > b.createdAt ? a : b,
    );
    return DateTime.fromMillisecondsSinceEpoch(latest.createdAt * 1000);
  }

  bool _isLastMessageSent() {
    if (thread.messages.isEmpty) return false;
    final ours = getIt<KeyStorage>().getActiveKeyPairSync()?.publicKey;
    if (ours == null) return false;
    final latest = thread.messages.reduce(
      (a, b) => a.createdAt > b.createdAt ? a : b,
    );
    return latest.pubKey == ours;
  }

  @override
  Widget build(BuildContext context) {
    final counterpartyPubkey = _getCounterpartyPubkey();
    final lastDateTime = _getLastDateTime();
    final subtitle = Text(_isLastMessageSent() ? 'Sent' : 'Received');

    return ProfileProvider(
      pubkey: counterpartyPubkey,
      builder: (context, snapshot) {
        if (snapshot.data is EntityCubitStateError) {
          return Text(
            'Error: ${(snapshot.data as EntityCubitStateError).error}',
          );
        }
        if (snapshot.data == null) {
          return ListTile(
            leading: CircularProgressIndicator(),
            title: Text(
              counterpartyPubkey,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: subtitle,
            onTap: () {
              AutoRouter.of(context).push(ThreadRoute(id: thread.id));
            },
          );
        }
        return ListTile(
          leading: snapshot.data!.picture != null
              ? CircleAvatar(
                  backgroundImage: NetworkImage(snapshot.data!.picture!),
                )
              : Icon(Icons.account_circle),
          title: snapshot.data!.name != null
              ? Text(snapshot.data!.name!)
              : Text(counterpartyPubkey),
          subtitle: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              subtitle,
              Text(timeago.format(lastDateTime, locale: 'en_short')),
            ],
          ),
          onTap: () {
            AutoRouter.of(context).push(ThreadRoute(id: thread.id));
          },
        );
      },
    );
  }
}
