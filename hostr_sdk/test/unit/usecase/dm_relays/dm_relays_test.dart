@Tags(['unit'])
library;

import 'package:hostr_sdk/config.dart' show HostrConfig;
import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/dm_relays/dm_relays.dart';
import 'package:hostr_sdk/usecase/relays/relays.dart';
import 'package:hostr_sdk/usecase/requests/requests.dart' as hostr_requests;
import 'package:hostr_sdk/util/main.dart';
import 'package:mockito/mockito.dart';
import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart'
    show RelayBroadcastResponse;
import 'package:ndk/entities.dart'
    show Nip01Event, ReadWriteMarker, UserRelayList;
import 'package:ndk/ndk.dart' show Ndk;
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

class _FakeNdk extends Fake implements Ndk {}

class _FakeRelays extends Fake implements Relays {}

class _FakeConfig extends Fake implements HostrConfig {
  @override
  final String hostrRelay;

  _FakeConfig({this.hostrRelay = ''});
}

class _FakeAuth extends Fake implements Auth {
  @override
  KeyPair getActiveKey() => KeyPair.justPublicKey('active-pubkey');
}

class _FakeRequests extends Fake implements hostr_requests.Requests {
  Nip01Event? broadcastedEvent;
  List<String>? broadcastRelays;

  @override
  Future<hostr_requests.BroadcastResult> broadcastEvent({
    required Nip01Event event,
    List<String>? relays,
    hostr_requests.NostrEventSigner? signer,
  }) async {
    broadcastedEvent = event.sig == null && signer != null
        ? await signer(event)
        : event;
    broadcastRelays = relays;
    return hostr_requests.BroadcastResult(
      event: broadcastedEvent!,
      responses: [_successfulBroadcastResponse()],
    );
  }
}

RelayBroadcastResponse _successfulBroadcastResponse() {
  return RelayBroadcastResponse(
    relayUrl: 'wss://relay.test',
    okReceived: true,
    broadcastSuccessful: true,
  );
}

class _TestDmRelays extends DmRelays {
  final List<String> existingRelays;
  final List<String> discoveryRelays;

  _TestDmRelays({
    required _FakeRequests requests,
    required super.config,
    this.existingRelays = const [],
    this.discoveryRelays = const [],
  }) : super(
         ndk: _FakeNdk(),
         requests: requests,
         relays: _FakeRelays(),
         auth: _FakeAuth(),
         logger: CustomLogger(),
       );

  @override
  Future<List<String>> relaysFor(
    String pubkey, {
    UserRelayList? nip65RelayList,
  }) async => existingRelays;

  @override
  Future<List<String>> discoveryRelaysFor(
    String pubkey, {
    UserRelayList? nip65RelayList,
  }) async => discoveryRelays;
}

void main() {
  group('relayTagsFromDmRelayEvent', () {
    test('extracts unique relay tags from a kind 10050 event', () {
      final event = Nip01Event(
        pubKey: 'pubkey',
        kind: kNostrKindDmRelays,
        tags: const [
          ['relay', 'wss://dm.example'],
          ['relay', 'wss://dm.example'],
          ['r', 'wss://nip65.example'],
          ['relay', ''],
        ],
        content: '',
      );

      expect(relayTagsFromDmRelayEvent(event), ['wss://dm.example']);
    });
  });

  group('resolveDmRelayDiscoveryRelays', () {
    test('uses bootstrap, hostr, and NIP-65 read/write relays', () {
      final nip65 = UserRelayList(
        pubKey: 'pubkey',
        createdAt: 1,
        refreshedTimestamp: 1,
        relays: const {
          'wss://read.example': ReadWriteMarker.readOnly,
          'wss://write.example': ReadWriteMarker.writeOnly,
          'wss://both.example': ReadWriteMarker.readWrite,
        },
      );

      final result = resolveDmRelayDiscoveryRelays(
        bootstrapRelays: const ['wss://bootstrap.example'],
        hostrRelay: 'wss://relay.hostr.test',
        nip65RelayList: nip65,
      );

      expect(result, [
        'wss://bootstrap.example',
        'wss://relay.hostr.test',
        'wss://read.example',
        'wss://both.example',
        'wss://write.example',
      ]);
    });
  });

  group('addRelay', () {
    test('publishes a replaceable kind 10050 DM relay list', () async {
      final requests = _FakeRequests();
      final dmRelays = _TestDmRelays(
        requests: requests,
        config: _FakeConfig(hostrRelay: 'wss://relay.hostr.test'),
        existingRelays: const ['wss://old.example'],
        discoveryRelays: const ['wss://bootstrap.example'],
      );

      await dmRelays.addRelay('wss://new.example');

      expect(requests.broadcastedEvent?.kind, kNostrKindDmRelays);
      expect(requests.broadcastedEvent?.pubKey, 'active-pubkey');
      expect(requests.broadcastedEvent?.tags, [
        ['relay', 'wss://old.example'],
        ['relay', 'wss://new.example'],
        ['relay', 'wss://relay.hostr.test'],
      ]);
      expect(requests.broadcastRelays, [
        'wss://bootstrap.example',
        'wss://old.example',
        'wss://new.example',
        'wss://relay.hostr.test',
      ]);
    });
  });
}
