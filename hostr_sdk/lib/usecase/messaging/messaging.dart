import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart';
import 'package:ndk/ndk.dart' show Ndk, Nip01Event;

import '../../util/custom_logger.dart';
import '../requests/requests.dart';
import 'threads.dart';

@Singleton()
class Messaging {
  final Ndk ndk;
  final Requests requests;
  final CustomLogger logger;
  late final Threads threads = Threads(this, requests, ndk, logger);
  Messaging(this.ndk, this.requests, this.logger);

  Future<Nip01Event> getRumour(
    String content,
    List<List<String>> tags,
    String recipientPubkey,
  ) {
    return ndk.giftWrap.createRumor(
      content: content,
      kind: kNostrKindDM,
      tags: [
        ...tags,
        ['p', recipientPubkey],
      ],
    );
  }

  Future<Message> broadcastTextAndAwait({
    required String content,
    required List<List<String>> tags,
    required String recipientPubkey,
  }) async {
    return broadcastEventAndWait(
      event: await getRumour(content, tags, recipientPubkey),
      tags: tags,
      recipientPubkey: recipientPubkey,
    );
  }

  Future<List<Future<List<RelayBroadcastResponse>>>> broadcastText({
    required String content,
    required List<List<String>> tags,
    required String recipientPubkey,
  }) async {
    final rumor = await getRumour(content, tags, recipientPubkey);
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
    final rumor = await getRumour(event.toString(), tags, recipientPubkey);
    broadcastEvent(event: event, tags: tags, recipientPubkey: recipientPubkey);

    // Need to get the wrapped event here
    return threads.awaitMessageId(rumor.id);
  }

  Future<List<Future<List<RelayBroadcastResponse>>>> broadcastEvent({
    required Nip01Event event,
    required List<List<String>> tags,
    required String recipientPubkey,
  }) {
    return broadcastText(
      content: event.toString(),
      tags: tags,
      recipientPubkey: recipientPubkey,
    );
  }
}
