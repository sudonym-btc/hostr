import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Ndk, NdkBroadcastResponse, Nip01Event;

import '../requests/requests.dart';
import 'threads.dart';

class Messaging {
  final Ndk ndk;
  final Requests requests;
  late final Threads threads = Threads(this, requests, ndk);
  Messaging(this.ndk, this.requests);

  Future<List<NdkBroadcastResponse>> broadcastMessage({
    required String content,
    required List<List<String>> tags,
    required String recipientPubkey,
  }) async {
    Nip01Event rumor = await ndk.giftWrap.createRumor(
      content: content,
      kind: NOSTR_KIND_DM,
      tags: tags,
    );

    return [
      ndk.broadcast.broadcast(
        nostrEvent: await ndk.giftWrap.toGiftWrap(
          rumor: rumor,
          recipientPubkey: recipientPubkey,
        ),
      ),
      ndk.broadcast.broadcast(
        nostrEvent: await ndk.giftWrap.toGiftWrap(
          rumor: rumor,
          recipientPubkey: ndk.accounts.getPublicKey()!,
        ),
      ),
    ];
  }

  Future<Message> broadcastMessageAndAwait({
    required String content,
    required List<List<String>> tags,
    required String recipientPubkey,
  }) async {
    Nip01Event rumor = await ndk.giftWrap.createRumor(
      content: content,
      kind: NOSTR_KIND_DM,
      tags: tags,
    );

    final r = broadcastMessage(
      content: content,
      tags: tags,
      recipientPubkey: recipientPubkey,
    );

    return threads.awaitId(rumor.id);
  }

  Future<List<NdkBroadcastResponse>> broadcastEvent({
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
