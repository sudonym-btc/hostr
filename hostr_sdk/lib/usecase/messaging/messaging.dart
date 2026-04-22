import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart' show visibleForTesting;
import 'package:models/main.dart';
import 'package:ndk/entities.dart' show UserRelayList;
import 'package:ndk/domain_layer/entities/broadcast_state.dart';
import 'package:ndk/ndk.dart' show Ndk, Nip01Event;

import '../../config.dart' show CoinlibEventSigner, HostrConfig;
import '../../injection.dart';
import '../../util/coinlib_gift_wrap.dart';
import '../../util/custom_logger.dart';
import '../relays/relays.dart';
import '../requests/requests.dart';
import 'threads.dart';

@visibleForTesting
List<String> resolveGiftWrapBroadcastRelays({
  required List<String> bootstrapRelays,
  required String hostrRelay,
  UserRelayList? recipientRelayList,
}) {
  final relays = <String>{};
  relays.addAll(bootstrapRelays.where((relay) => relay.isNotEmpty));
  if (hostrRelay.isNotEmpty) relays.add(hostrRelay);
  if (recipientRelayList != null) {
    relays.addAll(
      recipientRelayList.readUrls.where((relay) => relay.isNotEmpty),
    );
  }
  return relays.toList(growable: false);
}

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
    final rawSigner = _ndk.accounts.getLoggedAccount()?.signer;
    final signer = rawSigner is CoinlibEventSigner ? rawSigner : null;

    Future<Nip01Event> wrap(String pubkey) {
      if (signer?.privateKey != null) {
        return coinlibToGiftWrap(
          rumor: rumor,
          recipientPubkey: pubkey,
          senderPrivKey: signer!.privateKey!,
          senderPubKey: signer.getPublicKey(),
        );
      }
      // Fallback for non-coinlib signers (e.g. hardware wallet / NIP-46).
      return _ndk.giftWrap.toGiftWrap(rumor: rumor, recipientPubkey: pubkey);
    }

    return pubkeys.map((pubkey) async {
      final wrapped = await wrap(pubkey);
      final relays = await _giftWrapBroadcastRelays(pubkey);
      return _requests.broadcast(event: wrapped, relays: relays);
    }).toList();
  });

  Future<List<String>> _giftWrapBroadcastRelays(String recipientPubkey) async {
    final config = getIt<HostrConfig>();
    UserRelayList? recipientRelayList;

    try {
      await getIt<Relays>().loadNip65Hints(recipientPubkey);
      recipientRelayList = await _ndk.userRelayLists.getSingleUserRelayList(
        recipientPubkey,
      );
    } catch (error, stackTrace) {
      _logger.w(
        'Failed to load NIP-65 relays for giftwrap recipient $recipientPubkey',
        error: error,
        stackTrace: stackTrace,
      );
    }

    final relays = resolveGiftWrapBroadcastRelays(
      bootstrapRelays: config.bootstrapRelays,
      hostrRelay: config.hostrRelay,
      recipientRelayList: recipientRelayList,
    );
    _logger.d('Giftwrap relay targets for $recipientPubkey: $relays');
    return relays;
  }

  Future<Nip01Event> broadcastTextAndAwait({
    required String content,
    required List<List<String>> tags,
    required List<String> recipientPubkeys,
  }) => _logger.span('broadcastTextAndAwait', () async {
    final rumor = await getRumour(content, tags, recipientPubkeys);
    await _broadcastRumour(rumor, recipientPubkeys);
    return threads.awaitEventId(rumor.id);
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

  Future<Nip01Event> broadcastEventAndWait({
    required Nip01Event event,
    required List<List<String>> tags,
    required List<String> recipientPubkeys,
  }) => _logger.span('broadcastEventAndWait', () async {
    final rumor = await getRumour(event.toString(), tags, recipientPubkeys);
    await _broadcastRumour(rumor, recipientPubkeys);
    return threads.awaitEventId(rumor.id);
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

  /// Broadcasts a kind:16 seen receipt gift-wrapped to each recipient + self.
  /// No expiration is set on the gift wrap.
  Future<void> broadcastSeenReceipt({
    required int seenUntil,
    required List<List<String>> tags,
    required List<String> recipientPubkeys,
  }) => _logger.span('broadcastSeenReceipt', () async {
    _logger.d(
      'Broadcasting seen receipt seenUntil=$seenUntil to $recipientPubkeys',
    );
    final rumor = await _ndk.giftWrap.createRumor(
      content: '',
      kind: kNostrKindSeenStatus,
      tags: [
        ...tags,
        ...recipientPubkeys.map((pubkey) => ['p', pubkey]),
        ['seen_until', seenUntil.toString()],
      ],
    );
    await _broadcastRumour(rumor, recipientPubkeys);
  });
}
