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
    List<String> recipientPubkeys,
  ) {
    return ndk.giftWrap.createRumor(
      content: content,
      kind: kNostrKindDM,
      tags: [
        ...tags,
        ['p', ...recipientPubkeys],
      ],
    );
  }

  Future<Message> broadcastTextAndAwait({
    required String content,
    required List<List<String>> tags,
    required List<String> recipientPubkeys,
  }) async {
    return broadcastEventAndWait(
      event: await getRumour(content, tags, recipientPubkeys),
      tags: tags,
      recipientPubkeys: recipientPubkeys,
    );
  }

  Future<List<Future<List<RelayBroadcastResponse>>>> broadcastText({
    required String content,
    required List<List<String>> tags,
    required List<String> recipientPubkeys,
  }) async {
    final rumor = await getRumour(content, tags, recipientPubkeys);

    final broadcasts = [...recipientPubkeys, ndk.accounts.getPublicKey()!]
        .map(
          (pubkey) async => requests.broadcast(
            event: await ndk.giftWrap.toGiftWrap(
              rumor: rumor,
              recipientPubkey: pubkey,
            ),
          ),
        )
        .toList();
    return broadcasts;
  }

  Future<Message> broadcastEventAndWait({
    required Nip01Event event,
    required List<List<String>> tags,
    required List<String> recipientPubkeys,
  }) async {
    final rumor = await getRumour(event.toString(), tags, recipientPubkeys);
    broadcastEvent(
      event: event,
      tags: tags,
      recipientPubkeys: recipientPubkeys,
    );

    // Need to get the wrapped event here
    return threads.awaitMessageId(rumor.id);
  }

  Future<List<Future<List<RelayBroadcastResponse>>>> broadcastEvent({
    required Nip01Event event,
    required List<List<String>> tags,
    required List<String> recipientPubkeys,
  }) {
    return broadcastText(
      content: event.toString(),
      tags: tags,
      recipientPubkeys: recipientPubkeys,
    );
  }
}
