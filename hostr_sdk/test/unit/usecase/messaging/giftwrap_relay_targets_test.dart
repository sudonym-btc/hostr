@Tags(['unit'])
library;

import 'package:hostr_sdk/usecase/messaging/messaging.dart'
    show ensureSuccessfulGiftWrapBroadcast, resolveGiftWrapBroadcastRelays;
import 'package:ndk/entities.dart'
    show ReadWriteMarker, RelayBroadcastResponse, UserRelayList;
import 'package:test/test.dart';

void main() {
  group('resolveGiftWrapBroadcastRelays', () {
    test(
      'includes bootstrap relays, hostr relay, and recipient NIP-65 reads',
      () {
        final relayList = UserRelayList(
          pubKey: 'recipient',
          createdAt: 1,
          refreshedTimestamp: 1,
          relays: const {
            'wss://read.example': ReadWriteMarker.readOnly,
            'wss://write.example': ReadWriteMarker.writeOnly,
            'wss://both.example': ReadWriteMarker.readWrite,
          },
        );

        final result = resolveGiftWrapBroadcastRelays(
          bootstrapRelays: const [
            'wss://relay.damus.io',
            'wss://relay.nostr.band',
            'wss://relay.damus.io',
          ],
          hostrRelay: 'wss://relay.hostr.test',
          dmRelays: const ['wss://dm.example', 'wss://relay.damus.io'],
          recipientRelayList: relayList,
        );

        expect(result, [
          'wss://relay.damus.io',
          'wss://relay.nostr.band',
          'wss://relay.hostr.test',
          'wss://dm.example',
          'wss://read.example',
          'wss://write.example',
          'wss://both.example',
        ]);
      },
    );

    test('falls back to bootstrap plus hostr when no NIP-65 list exists', () {
      final result = resolveGiftWrapBroadcastRelays(
        bootstrapRelays: const ['wss://relay.damus.io'],
        hostrRelay: 'wss://relay.hostr.test',
      );

      expect(result, ['wss://relay.damus.io', 'wss://relay.hostr.test']);
    });
  });

  group('ensureSuccessfulGiftWrapBroadcast', () {
    test('allows a send when at least one relay accepted the gift wrap', () {
      expect(
        () => ensureSuccessfulGiftWrapBroadcast(
          recipientPubkey: 'recipient',
          responses: [
            RelayBroadcastResponse(
              relayUrl: 'wss://blocked.example',
              okReceived: true,
              broadcastSuccessful: false,
              msg: 'blocked',
            ),
            RelayBroadcastResponse(
              relayUrl: 'wss://accepted.example',
              okReceived: true,
              broadcastSuccessful: true,
            ),
          ],
        ),
        returnsNormally,
      );
    });

    test('throws when no relay accepted the gift wrap', () {
      expect(
        () => ensureSuccessfulGiftWrapBroadcast(
          recipientPubkey: 'recipient',
          responses: [
            RelayBroadcastResponse(
              relayUrl: 'wss://blocked.example',
              okReceived: true,
              broadcastSuccessful: false,
              msg: 'kind 1059 is not allowed',
            ),
          ],
        ),
        throwsA(isA<StateError>()),
      );
    });
  });
}
