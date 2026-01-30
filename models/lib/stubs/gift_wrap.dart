import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

/// Helper to create mock gift wraps for testing
/// Since NDK's GiftWrap usecase requires async operations and cryptography,
/// these must be generated at runtime in seed.dart using the NDK instance
Future<List<Nip01Event>> createMockGiftWraps(
    KeyPair pair, Nip01Event rumor, String recipientPubkey) async {
  Ndk ndk = Ndk(NdkConfig(
      eventVerifier: Bip340EventVerifier(),
      cache: MemCacheManager(),
      engine: NdkEngine.JIT,
      defaultQueryTimeout: Duration(seconds: 10),
      bootstrapRelays: []));
  ndk.accounts
      .loginPrivateKey(pubkey: pair.publicKey, privkey: pair.privateKey!);
  return [
    await ndk.giftWrap
        .toGiftWrap(rumor: rumor, recipientPubkey: recipientPubkey),
    await ndk.giftWrap.toGiftWrap(rumor: rumor, recipientPubkey: pair.publicKey)
  ];
}

/// Mock rumor events (unsigned inner messages) that will be wrapped
final mockRumorHostToGuest1 = Nip01Event(
  pubKey: MockKeys.hoster.publicKey,
  kind: NOSTR_KIND_DM,
  tags: [
    ['a', 'thread-conversation-1'], // Thread ID via anchor tag
    ['p', MockKeys.guest.publicKey],
  ],
  content: 'Hey! I have a great place available for your dates.',
  createdAt: DateTime(2026, 1, 15).millisecondsSinceEpoch ~/ 1000,
  id: '',
  sig: '',
);

final mockRumorGuestToHost1 = Nip01Event(
  pubKey: MockKeys.guest.publicKey,
  kind: NOSTR_KIND_DM,
  tags: [
    ['a', 'thread-conversation-1'], // Same thread ID
    ['p', MockKeys.hoster.publicKey],
  ],
  content: 'That sounds perfect! Can you tell me more about the amenities?',
  createdAt: DateTime(2026, 1, 15, 10).millisecondsSinceEpoch ~/ 1000,
  id: '',
  sig: '',
);

final mockRumorHostToGuest2 = Nip01Event(
  pubKey: MockKeys.hoster.publicKey,
  kind: NOSTR_KIND_DM,
  tags: [
    ['a', 'thread-conversation-1'],
    ['p', MockKeys.guest.publicKey],
  ],
  content: 'Sure! It has WiFi, kitchen, and a beautiful garden view.',
  createdAt: DateTime(2026, 1, 15, 11).millisecondsSinceEpoch ~/ 1000,
  id: '',
  sig: '',
);

// Second thread
final mockRumorGuestToHost2 = Nip01Event(
  pubKey: MockKeys.guest.publicKey,
  kind: NOSTR_KIND_DM,
  tags: [
    ['a', 'thread-booking-inquiry'], // Different thread
    ['p', MockKeys.hoster.publicKey],
  ],
  content: 'Is your place pet-friendly?',
  createdAt: DateTime(2026, 1, 16).millisecondsSinceEpoch ~/ 1000,
  id: '',
  sig: '',
);

final mockRumorHostToGuest3 = Nip01Event(
  pubKey: MockKeys.hoster.publicKey,
  kind: NOSTR_KIND_DM,
  tags: [
    ['a', 'thread-booking-inquiry'],
    ['p', MockKeys.guest.publicKey],
  ],
  content: 'Yes! Small pets are welcome.',
  createdAt: DateTime(2026, 1, 16, 9).millisecondsSinceEpoch ~/ 1000,
  id: '',
  sig: '',
);

/// Legacy mock events for reservation requests

Nip01Event hostInvitesGuest = Nip01Event(
    pubKey: MockKeys.hoster.publicKey,
    kind: NOSTR_KIND_DM,
    tags: [
      ['a', 'random-topic-id'],
      [
        'p',
        MockKeys.guest.publicKey,
      ]
    ],
    createdAt: DateTime(2026).millisecondsSinceEpoch ~/ 1000,
    content: hostInvitesGuestReservationRequest.toString());

Nip01Event guestRequest = Nip01Event(
    pubKey: MockKeys.guest.publicKey,
    kind: NOSTR_KIND_DM,
    tags: [
      ['a', 'random-topic-id-2'],
      [
        'p',
        MockKeys.hoster.publicKey,
      ]
    ],
    createdAt: DateTime(2026).millisecondsSinceEpoch ~/ 1000,
    content: guestInvitesHostReservationRequest.toString().toString());

Future<List<Nip01Event>> MOCK_GIFT_WRAPS() async => [
      ...(await createMockGiftWraps(
          MockKeys.guest, guestRequest, MockKeys.hoster.publicKey)),
      ...(await createMockGiftWraps(
          MockKeys.hoster, hostInvitesGuest, MockKeys.guest.publicKey)),
    ].toList();
