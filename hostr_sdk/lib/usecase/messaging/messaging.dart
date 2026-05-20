import 'package:injectable/injectable.dart' hide Order;
import 'package:meta/meta.dart' show visibleForTesting;
import 'package:models/main.dart';
import 'package:ndk/entities.dart' show UserRelayList;
import 'package:ndk/domain_layer/entities/broadcast_state.dart';
import 'package:ndk/ndk.dart' show Ndk, Nip01Event;

import '../../config.dart' show CoinlibEventSigner, HostrConfig;
import '../../injection.dart' show HostrScope, getIt;
import '../../util/coinlib_gift_wrap.dart';
import '../../util/custom_logger.dart';
import '../dm_relays/dm_relays.dart';
import '../relays/relays.dart';
import '../requests/requests.dart';
import 'threads.dart';

@visibleForTesting
List<String> resolveGiftWrapBroadcastRelays({
  required List<String> bootstrapRelays,
  required String hostrRelay,
  List<String> dmRelays = const [],
  UserRelayList? recipientRelayList,
}) {
  final relays = <String>{};
  relays.addAll(bootstrapRelays.where((relay) => relay.isNotEmpty));
  if (hostrRelay.isNotEmpty) relays.add(hostrRelay);
  relays.addAll(dmRelays.where((relay) => relay.isNotEmpty));
  if (recipientRelayList != null) {
    relays.addAll(recipientRelayList.urls.where((relay) => relay.isNotEmpty));
  }
  return relays.toList(growable: false);
}

@visibleForTesting
List<String> resolveHostrOnlyGiftWrapBroadcastRelays({
  required String hostrRelay,
}) {
  if (hostrRelay.isEmpty) return const [];
  return [hostrRelay];
}

@Singleton()
class Messaging {
  final Ndk _ndk;
  final Requests _requests;
  final DmRelays _dmRelays;
  final CustomLogger _logger;
  final HostrConfig? _config;
  final Relays? _relays;
  final HostrScope _scope;
  Threads get threads => _scope<Threads>();
  Messaging(
    Ndk ndk,
    Requests requests,
    DmRelays dmRelays,
    CustomLogger logger, [
    HostrConfig? config,
    Relays? relays,
    HostrScope? scope,
  ]) : _ndk = ndk,
       _requests = requests,
       _dmRelays = dmRelays,
       _config = config,
       _relays = relays,
       _scope = scope ?? HostrScope(getIt),
       _logger = logger.scope('messaging');

  Future<Nip01Event> getRumour(
    String content,
    List<List<String>> tags,
    List<String> recipientPubkeys,
  ) => _getRumour(content, tags, recipientPubkeys, kind: kNostrKindDM);

  @visibleForTesting
  Future<Nip01Event> getJsonRumour(
    String content,
    List<List<String>> tags,
    List<String> recipientPubkeys, {
    String? altText,
  }) => _getRumour(
    content,
    tags,
    recipientPubkeys,
    kind: kNostrKindJsonMessage,
    altText: altText,
  );

  Future<Nip01Event> _getRumour(
    String content,
    List<List<String>> tags,
    List<String> recipientPubkeys, {
    required int kind,
    String? altText,
  }) => _logger.span('getRumour', () async {
    final myPubkey = _ndk.accounts.getPublicKey();
    if (myPubkey == null) {
      throw Exception('cannot create rumor: no logged-in pubkey');
    }
    final rumor = Nip01Event(
      pubKey: myPubkey,
      content: content,
      kind: kind,
      tags: [
        ...tags,
        if (altText != null &&
            !tags.any((tag) => tag.isNotEmpty && tag.first == 'alt'))
          ['alt', altText],
        ...recipientPubkeys.map((pubkey) => ['p', pubkey]),
      ],
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
    _logger.d(
      'Created rumor kind=${rumor.kind} with content: ${rumor.content}, '
      'tags: ${rumor.tags}, recipientPubkeys: $recipientPubkeys',
    );
    return rumor;
  });

  Future<List<Future<List<RelayBroadcastResponse>>>> _broadcastRumour(
    Nip01Event rumor,
    List<String> recipientPubkeys, {
    bool allowExternalRelays = false,
  }) => _logger.span('_broadcastRumour', () async {
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

    final results = await Future.wait(
      pubkeys.map((pubkey) async {
        final wrapped = await wrap(pubkey);
        final relays = await _giftWrapBroadcastRelays(
          pubkey,
          allowExternalRelays: allowExternalRelays,
        );
        final broadcast = await _requests.broadcastEvent(
          event: wrapped,
          relays: relays,
        );
        final responses = broadcast.responses;
        final accepted = responses
            .where((response) => response.broadcastSuccessful)
            .map((response) => response.relayUrl)
            .toList(growable: false);
        final rejected = responses
            .where((response) => !response.broadcastSuccessful)
            .map((response) => '${response.relayUrl}: ${response.msg}')
            .toList(growable: false);
        _logger.i(
          'Giftwrap broadcast complete for $pubkey: '
          'accepted=$accepted rejected=$rejected',
        );
        return responses;
      }),
    );
    return results.map(Future.value).toList(growable: false);
  });

  Future<List<String>> _giftWrapBroadcastRelays(
    String recipientPubkey, {
    bool allowExternalRelays = false,
  }) async {
    if (!allowExternalRelays) {
      final relays = resolveHostrOnlyGiftWrapBroadcastRelays(
        hostrRelay: _config?.hostrRelay ?? '',
      );
      _logger.d('Giftwrap relay targets for $recipientPubkey: $relays');
      return relays;
    }
    UserRelayList? recipientRelayList;

    try {
      await _relays?.loadNip65Hints(recipientPubkey);
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

    List<String> dmRelays = const [];
    try {
      dmRelays = await _dmRelays.relaysFor(
        recipientPubkey,
        nip65RelayList: recipientRelayList,
      );
    } catch (error, stackTrace) {
      _logger.w(
        'Failed to load NIP-17 DM relays for giftwrap recipient $recipientPubkey',
        error: error,
        stackTrace: stackTrace,
      );
    }

    final relays = resolveGiftWrapBroadcastRelays(
      bootstrapRelays: _config?.bootstrapRelays ?? const [],
      hostrRelay: _config?.hostrRelay ?? '',
      dmRelays: dmRelays,
      recipientRelayList: recipientRelayList,
    );
    _logger.d('Giftwrap relay targets for $recipientPubkey: $relays');
    return relays;
  }

  /// Relay targets for private messages to [recipientPubkey].
  ///
  /// This includes the Hostr/bootstrap relays plus the recipient's NIP-17 DM
  /// relays and NIP-65 relay list when available. Escrow legacy NIP-04 copies
  /// use this so they are sent to relays the recipient is likely to monitor.
  Future<List<String>> recipientMessageRelays(String recipientPubkey) {
    return _giftWrapBroadcastRelays(recipientPubkey, allowExternalRelays: true);
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

  /// Escrow-only path: allows NIP-17/NIP-65 relay fan-out for recipients.
  Future<List<Future<List<RelayBroadcastResponse>>>>
  broadcastTextAllowingExternalRelays({
    required String content,
    required List<List<String>> tags,
    required List<String> recipientPubkeys,
  }) => _logger.span('broadcastTextAllowingExternalRelays', () async {
    _logger.d(
      'Broadcasting text with external relays: $content to $recipientPubkeys '
      'with tags: $tags',
    );
    final rumor = await getRumour(content, tags, recipientPubkeys);
    return _broadcastRumour(rumor, recipientPubkeys, allowExternalRelays: true);
  });

  Future<Nip01Event> broadcastEventAndWait({
    required Nip01Event event,
    required List<List<String>> tags,
    required List<String> recipientPubkeys,
  }) => _logger.span('broadcastEventAndWait', () async {
    final rumor = await getJsonRumour(
      event.toString(),
      tags,
      recipientPubkeys,
      altText: _altTextForJsonEvent(event),
    );
    await _broadcastRumour(rumor, recipientPubkeys);
    return threads.awaitEventId(rumor.id);
  });

  Future<List<Future<List<RelayBroadcastResponse>>>> broadcastEvent({
    required Nip01Event event,
    required List<List<String>> tags,
    required List<String> recipientPubkeys,
  }) => _logger.span('broadcastEvent', () async {
    _logger.d(
      'Broadcasting JSON event: ${event.toString()} to $recipientPubkeys '
      'with tags: $tags',
    );
    final rumor = await getJsonRumour(
      event.toString(),
      tags,
      recipientPubkeys,
      altText: _altTextForJsonEvent(event),
    );
    return _broadcastRumour(rumor, recipientPubkeys);
  });

  String? _altTextForJsonEvent(Nip01Event event) {
    return switch (event.kind) {
      kNostrKindOrder => 'Order Proposal',
      kNostrKindEscrowServiceSelected => 'Escrow Service Selected',
      _ => null,
    };
  }

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
