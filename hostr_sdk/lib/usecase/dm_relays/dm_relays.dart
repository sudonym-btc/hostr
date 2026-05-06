import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart' show visibleForTesting;
import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart'
    show RelayBroadcastResponse;
import 'package:ndk/entities.dart' show Nip01Event, UserRelayList;
import 'package:ndk/ndk.dart' show Filter, Ndk;

import '../../config.dart' show HostrConfig;
import '../../util/main.dart';
import '../auth/auth.dart';
import '../relays/relays.dart';
import '../requests/requests.dart';

@visibleForTesting
List<String> relayTagsFromDmRelayEvent(Nip01Event event) {
  return [
    ...{
      for (final tag in event.tags)
        if (tag.length > 1 && tag[0] == 'relay' && tag[1].isNotEmpty) tag[1],
    },
  ];
}

@visibleForTesting
List<String> resolveDmRelayDiscoveryRelays({
  required List<String> bootstrapRelays,
  required String hostrRelay,
  UserRelayList? nip65RelayList,
}) {
  final relays = <String>{};
  relays.addAll(bootstrapRelays.where((relay) => relay.isNotEmpty));
  if (hostrRelay.isNotEmpty) relays.add(hostrRelay);
  if (nip65RelayList != null) {
    relays.addAll(nip65RelayList.readUrls.where((relay) => relay.isNotEmpty));
    relays.addAll(
      nip65RelayList.relays.entries
          .where((entry) => entry.value.isWrite)
          .map((entry) => entry.key)
          .where((relay) => relay.isNotEmpty),
    );
  }
  return relays.toList(growable: false);
}

@Singleton()
class DmRelays {
  final Ndk _ndk;
  final Requests _requests;
  final Relays _relays;
  final Auth _auth;
  final HostrConfig _config;
  final CustomLogger _logger;

  DmRelays({
    required Ndk ndk,
    required Requests requests,
    required Relays relays,
    required Auth auth,
    required HostrConfig config,
    required CustomLogger logger,
  }) : _ndk = ndk,
       _requests = requests,
       _relays = relays,
       _auth = auth,
       _config = config,
       _logger = logger.scope('dmRelays');

  Future<List<String>> relaysFor(
    String pubkey, {
    UserRelayList? nip65RelayList,
  }) => _logger.span('relaysFor', () async {
    final queryRelays = await discoveryRelaysFor(
      pubkey,
      nip65RelayList: nip65RelayList,
    );
    Nip01Event? latest;

    await for (final event in _requests.query<Nip01Event>(
      filter: Filter(authors: [pubkey], kinds: [kNostrKindDmRelays], limit: 1),
      relays: queryRelays,
      name: 'DmRelays-discovery',
    )) {
      if (latest == null || event.createdAt > latest.createdAt) {
        latest = event;
      }
    }

    if (latest == null) {
      _logger.i('No NIP-17 DM relay list found for $pubkey');
      return const [];
    }

    final relays = relayTagsFromDmRelayEvent(latest);
    _logger.i('Found ${relays.length} NIP-17 DM relays for $pubkey: $relays');
    return relays;
  });

  Future<List<String>> discoveryRelaysFor(
    String pubkey, {
    UserRelayList? nip65RelayList,
  }) async {
    var resolvedNip65RelayList = nip65RelayList;
    if (resolvedNip65RelayList == null) {
      try {
        await _relays.loadNip65Hints(pubkey);
        resolvedNip65RelayList = await _ndk.userRelayLists
            .getSingleUserRelayList(pubkey);
      } catch (error, stackTrace) {
        _logger.w(
          'Failed to load NIP-65 relays for DM relay discovery: $pubkey',
          error: error,
          stackTrace: stackTrace,
        );
      }
    }

    return resolveDmRelayDiscoveryRelays(
      bootstrapRelays: _config.bootstrapRelays,
      hostrRelay: _config.hostrRelay,
      nip65RelayList: resolvedNip65RelayList,
    );
  }

  Future<List<RelayBroadcastResponse>> addRelay(String relayUrl) =>
      _logger.span('addRelay', () async {
        final pubkey = _auth.getActiveKey().publicKey;
        final existing = await relaysFor(pubkey);
        final updatedRelays = [
          ...{
            ...existing,
            relayUrl,
            if (_config.hostrRelay.isNotEmpty) _config.hostrRelay,
          },
        ];

        final event = Nip01Event(
          pubKey: pubkey,
          kind: kNostrKindDmRelays,
          tags: updatedRelays.map((relay) => ['relay', relay]).toList(),
          content: '',
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        );

        final broadcastRelays = [
          ...{...await discoveryRelaysFor(pubkey), ...updatedRelays},
        ];

        _logger.i('Publishing NIP-17 DM relay list to $broadcastRelays');
        final broadcast = await _requests.broadcastEvent(
          event: event,
          relays: broadcastRelays,
        );
        return broadcast.responses;
      });
}
