import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart';
import 'package:ndk/ndk.dart' show Ndk, Nip01Event;

import '../requests/requests.dart';
import 'threads.dart';

@Singleton()
class Messaging {
  final Ndk ndk;
  final Requests requests;
  late final Threads threads = Threads(this, requests, ndk);
  Messaging(this.ndk, this.requests);

  Future<List<Future<List<RelayBroadcastResponse>>>> broadcastMessage({
    required String content,
    required List<List<String>> tags,
    required String recipientPubkey,
  }) async {
    Nip01Event rumor = await ndk.giftWrap.createRumor(
      content: content,
      kind: NOSTR_KIND_DM,
      tags: [
        ...tags,
        ['p', recipientPubkey],
      ],
    );

    return [
      requests.broadcast(
        event: await ndk.giftWrap.toGiftWrap(
          rumor: rumor,
          recipientPubkey: recipientPubkey,
        ),
      ),
      requests.broadcast(
        event: await ndk.giftWrap.toGiftWrap(
          rumor: rumor,
          recipientPubkey: ndk.accounts.getPublicKey()!,
        ),
      ),
    ];
  }

  Future<Message> broadcastEventAndWait({
    required Nip01Event event,
    required List<List<String>> tags,
    required String recipientPubkey,
  }) async {
    broadcastEvent(event: event, tags: tags, recipientPubkey: recipientPubkey);
    return threads.awaitId(event.id);
  }

  Future<Message> broadcastMessageAndAwait({
    required String content,
    required List<List<String>> tags,
    required String recipientPubkey,
  }) async {
    Nip01Event rumor = await ndk.giftWrap.createRumor(
      content: content,
      kind: NOSTR_KIND_DM,
      tags: [
        ...tags,
        ['p', recipientPubkey],
      ],
    );
    return broadcastEventAndWait(
      event: rumor,
      tags: tags,
      recipientPubkey: recipientPubkey,
    );
  }

  Future<List<Future<List<RelayBroadcastResponse>>>> broadcastEvent({
    required Nip01Event event,
    required List<List<String>> tags,
    required String recipientPubkey,
  }) async {
    return broadcastMessage(
      content: event.toString(),
      tags: tags,
      recipientPubkey: recipientPubkey,
    );
  }
}
