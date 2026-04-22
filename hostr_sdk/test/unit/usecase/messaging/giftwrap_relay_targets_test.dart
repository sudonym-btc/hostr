@Tags(['unit'])
library;

import 'package:hostr_sdk/usecase/messaging/messaging.dart'
    show resolveGiftWrapBroadcastRelays;
import 'package:ndk/entities.dart' show ReadWriteMarker, UserRelayList;
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
          recipientRelayList: relayList,
        );

        expect(result, [
          'wss://relay.damus.io',
          'wss://relay.nostr.band',
          'wss://relay.hostr.test',
          'wss://read.example',
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
}
