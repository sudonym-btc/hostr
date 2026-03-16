import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart';
import 'package:ndk/ndk.dart' show Ndk, Nip01Event;

import '../../injection.dart';
import '../../util/custom_logger.dart';
import '../requests/requests.dart';
import 'threads.dart';

@Singleton()
class Messaging {
  final Ndk _ndk;
  final Requests _requests;
  final CustomLogger _logger;
  Threads get threads => getIt<Threads>();
  Messaging(Ndk ndk, Requests requests, CustomLogger logger)
    : _ndk = ndk,
      _requests = requests,
      _logger = logger.scope('messaging');

  Future<Nip01Event> getRumour(
    String content,
    List<List<String>> tags,
    List<String> recipientPubkeys,
  ) => _logger.span('getRumour', () async {
    _logger.d(
      'Creating rumor with content: $content, tags: $tags, recipientPubkeys: $recipientPubkeys',
    );
    return _ndk.giftWrap.createRumor(
      content: content,
      kind: kNostrKindDM,
      tags: [
        ...tags,
        ...recipientPubkeys.map((pubkey) => ['p', pubkey]),
      ],
    );
  });

  Future<List<Future<List<RelayBroadcastResponse>>>> _broadcastRumour(
    Nip01Event rumor,
    List<String> recipientPubkeys,
  ) => _logger.span('_broadcastRumour', () async {
    final pubkeys = {...recipientPubkeys, _ndk.accounts.getPublicKey()!};

    return pubkeys
        .map(
          (pubkey) async => _requests.broadcast(
            event: await _ndk.giftWrap.toGiftWrap(
              rumor: rumor,
              recipientPubkey: pubkey,
            ),
          ),
        )
        .toList();
  });

  Future<Message> broadcastTextAndAwait({
    required String content,
    required List<List<String>> tags,
    required List<String> recipientPubkeys,
  }) => _logger.span('broadcastTextAndAwait', () async {
    final rumor = await getRumour(content, tags, recipientPubkeys);
    await _broadcastRumour(rumor, recipientPubkeys);
    return threads.awaitMessageId(rumor.id);
  });

  Future<List<Future<List<RelayBroadcastResponse>>>> broadcastText({
    required String content,
    required List<List<String>> tags,
    required List<String> recipientPubkeys,
  }) => _logger.span('broadcastText', () async {
    _logger.d(
      'Broadcasting text: $content to $recipientPubkeys with tags: $tags',
    );
    final rumor = await getRumour(content, tags, recipientPubkeys);
    return _broadcastRumour(rumor, recipientPubkeys);
  });

  Future<Message> broadcastEventAndWait({
    required Nip01Event event,
    required List<List<String>> tags,
    required List<String> recipientPubkeys,
  }) => _logger.span('broadcastEventAndWait', () async {
    final rumor = await getRumour(event.toString(), tags, recipientPubkeys);
    await _broadcastRumour(rumor, recipientPubkeys);
    return threads.awaitMessageId(rumor.id);
  });

  Future<List<Future<List<RelayBroadcastResponse>>>> broadcastEvent({
    required Nip01Event event,
    required List<List<String>> tags,
    required List<String> recipientPubkeys,
  }) => _logger.span('broadcastEvent', () async {
    return broadcastText(
      content: event.toString(),
      tags: tags,
      recipientPubkeys: recipientPubkeys,
    );
  });
}
