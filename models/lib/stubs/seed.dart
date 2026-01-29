import 'dart:io';

import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

seed(String relayUrl) async {
  print("Seeding $relayUrl...");
  Ndk ndk = Ndk(NdkConfig(
      eventVerifier: Bip340EventVerifier(),
      cache: MemCacheManager(),
      bootstrapRelays: [relayUrl]));

  final MOCKED_EVENTS = await MOCK_EVENTS();

  // Seed regular events
  for (var x in MOCKED_EVENTS) {
    var broadcastResult =
        await ndk.broadcast.broadcast(nostrEvent: x).broadcastDoneFuture;
    if (!broadcastResult.first.broadcastSuccessful) {
      throw Exception(
          'Failed to broadcast event: ${broadcastResult.first.msg}');
    }
  }

  print('Seeded ${MOCKED_EVENTS.length} events.');
  exit(0);
}

/// Generate mock gift wraps at runtime using NDK's GiftWrap service
Future<List<Nip01Event>> _generateMockGiftWraps(
    GiftWrap giftWrapService) async {
  final giftWraps = <Nip01Event>[];

  // Thread 1: Host <-> Guest conversation about amenities
  final rumors1 = [
    mockRumorHostToGuest1,
    mockRumorGuestToHost1,
    mockRumorHostToGuest2,
  ];

  for (final rumor in rumors1) {
    // Send to recipient
    final toRecipient = await giftWrapService.toGiftWrap(
      rumor: rumor,
      recipientPubkey:
          rumor.tags.firstWhere((t) => t.isNotEmpty && t[0] == 'p')[1],
    );
    giftWraps.add(toRecipient);

    // Also send to sender (so they see their own messages)
    final toSender = await giftWrapService.toGiftWrap(
      rumor: rumor,
      recipientPubkey: rumor.pubKey,
    );
    giftWraps.add(toSender);
  }

  // Thread 2: Guest <-> Host conversation about pets
  final rumors2 = [
    mockRumorGuestToHost2,
    mockRumorHostToGuest3,
  ];

  for (final rumor in rumors2) {
    // Send to recipient
    final toRecipient = await giftWrapService.toGiftWrap(
      rumor: rumor,
      recipientPubkey:
          rumor.tags.firstWhere((t) => t.isNotEmpty && t[0] == 'p')[1],
    );
    giftWraps.add(toRecipient);

    // Send to sender
    final toSender = await giftWrapService.toGiftWrap(
      rumor: rumor,
      recipientPubkey: rumor.pubKey,
    );
    giftWraps.add(toSender);
  }

  return giftWraps;
}

void main(List<String> arguments) async {
  if (arguments.isEmpty) {
    print('Please provide a relay URL.');
    return;
  }

  String relayUrl = arguments[0];
  await seed(relayUrl);
}
