@Tags(['unit'])
library;

import 'package:hostr_sdk/usecase/escrow_daemon/escrow_daemon.dart';
import 'package:hostr_sdk/usecase/reservations/reservation_pubkey_proofs.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/ndk.dart' show Metadata;
import 'package:test/test.dart';

class _SentNotice {
  final String content;
  final List<List<String>> tags;
  final List<String> recipientPubkeys;

  const _SentNotice({
    required this.content,
    required this.tags,
    required this.recipientPubkeys,
  });
}

class _SentLegacyNotice {
  final String content;
  final List<List<String>> tags;
  final String recipientPubkey;

  const _SentLegacyNotice({
    required this.content,
    required this.tags,
    required this.recipientPubkey,
  });
}

Listing _listing() => Listing.create(
  pubKey: MockKeys.hoster.publicKey,
  dTag: 'listing-1',
  title: 'Lake House',
  description: 'Fixture',
  images: const [],
  price: [
    Price(
      amount: DenominatedAmount(
        value: BigInt.from(100000),
        denomination: 'BTC',
        decimals: 8,
      ),
      frequency: Frequency.daily,
    ),
  ],
  location: 'Test',
  type: ListingType.house,
  specifications: Specifications(),
);

ProfileMetadata _profile(String pubkey, {required String displayName}) {
  return ProfileMetadata.fromNostrEvent(
    Metadata(
      pubKey: pubkey,
      name: '$displayName Example',
      displayName: displayName,
    ).toEvent(),
  );
}

Future<ReservationGroup> _group({
  required bool buyerProof,
  bool sellerProof = false,
  String tradeId = 'trade-123',
  DateTime? start,
  DateTime? end,
}) async {
  final disposableBuyer = mockKeys[30];
  final listingAnchor = '32121:${MockKeys.hoster.publicKey}:listing-1';
  final reservationStart = start ?? DateTime.utc(2026, 5, 1);
  final reservationEnd = end ?? DateTime.utc(2026, 5, 3);

  var buyer = Reservation.create(
    pubKey: disposableBuyer.publicKey,
    dTag: tradeId,
    listingAnchor: listingAnchor,
    pTags: [
      PTag.seller(MockKeys.hoster.publicKey),
      PTag.buyer(disposableBuyer.publicKey),
      PTag.escrow(MockKeys.escrow.publicKey),
    ],
    stage: ReservationStage.commit,
    start: reservationStart,
    end: reservationEnd,
  );
  if (buyerProof) {
    buyer = await buyer.attachPubkeyProof(
      role: 'buyer',
      proofKeyPair: MockKeys.guest,
      encryptionKeyPair: disposableBuyer,
    );
  }

  var seller = Reservation.create(
    pubKey: MockKeys.hoster.publicKey,
    dTag: tradeId,
    listingAnchor: listingAnchor,
    pTags: [
      PTag.seller(MockKeys.hoster.publicKey),
      PTag.buyer(disposableBuyer.publicKey),
      PTag.escrow(MockKeys.escrow.publicKey),
    ],
    stage: ReservationStage.commit,
    start: reservationStart,
    end: reservationEnd,
  );
  if (sellerProof) {
    seller = await seller.attachPubkeyProof(
      role: 'seller',
      proofKeyPair: MockKeys.reviewer,
      encryptionKeyPair: MockKeys.hoster,
      recipientPubkeys: [MockKeys.escrow.publicKey],
    );
  }

  return ReservationGroup(reservations: [buyer, seller]);
}

TextMessage _existingNotice({
  required String tradeId,
  required String role,
  required String recipientPubkey,
  String? authorPubkey,
}) {
  return TextMessage(
    pubKey: authorPubkey ?? MockKeys.escrow.publicKey,
    tags: MessageTags([
      ['tradeId', tradeId],
      ['p', recipientPubkey],
      ['hostr_notice', 'reservation_placed', role, recipientPubkey],
    ]),
    content: 'already sent',
    createdAt: 123,
  );
}

void main() {
  group('EscrowReservationNotifier', () {
    late List<_SentNotice> sent;
    late List<_SentLegacyNotice> sentLegacy;
    late List<TextMessage> existing;
    late EscrowReservationNotifier notifier;

    setUp(() {
      sent = [];
      sentLegacy = [];
      existing = [];
      notifier = EscrowReservationNotifier(
        escrowKeyPair: () => MockKeys.escrow,
        clock: () => DateTime.utc(2026, 4, 23),
        loadListing: (_) async => _listing(),
        loadMetadata: (pubkey) async {
          if (pubkey == MockKeys.guest.publicKey) {
            return _profile(pubkey, displayName: 'Josh');
          }
          if (pubkey == MockKeys.hoster.publicKey) {
            return _profile(pubkey, displayName: 'Alex');
          }
          if (pubkey == MockKeys.reviewer.publicKey) {
            return _profile(pubkey, displayName: 'Maya');
          }
          return null;
        },
        existingMessagesForTrade: (_) => existing,
        sendText:
            ({
              required content,
              required tags,
              required recipientPubkeys,
            }) async {
              sent.add(
                _SentNotice(
                  content: content,
                  tags: tags,
                  recipientPubkeys: recipientPubkeys,
                ),
              );
            },
        sendLegacyText:
            ({
              required content,
              required tags,
              required recipientPubkey,
            }) async {
              sentLegacy.add(
                _SentLegacyNotice(
                  content: content,
                  tags: tags,
                  recipientPubkey: recipientPubkey,
                ),
              );
            },
        logger: CustomLogger(),
      );
    });

    test(
      'decrypts buyer and seller proofs and notifies both real pubkeys',
      () async {
        final group = await _group(buyerProof: true, sellerProof: true);

        await notifier.notifyReservation(group);

        expect(sent, hasLength(2));
        expect(sentLegacy, hasLength(2));
        expect(sent.map((n) => n.recipientPubkeys.single).toSet(), {
          MockKeys.guest.publicKey,
          MockKeys.reviewer.publicKey,
        });
        expect(sentLegacy.map((n) => n.recipientPubkey).toSet(), {
          MockKeys.guest.publicKey,
          MockKeys.reviewer.publicKey,
        });
        expect(
          sent
              .singleWhere(
                (n) => n.recipientPubkeys.single == MockKeys.guest.publicKey,
              )
              .content,
          'You successfully reserved Lake House 2026-05-01 - 2026-05-03, '
          "hosted by Maya. Your payment is safely in escrow. We've reached "
          'out to the host to confirm, and they should be in touch soon. If '
          'they do not confirm in a timely manner, you can be refunded.',
        );
        expect(
          sent
              .singleWhere(
                (n) => n.recipientPubkeys.single == MockKeys.reviewer.publicKey,
              )
              .content,
          'A reservation was placed for Lake House 2026-05-01 - 2026-05-03. '
          'Payment has been paid and is sitting in escrow. Please login to '
          'https://hostr.network to confirm the booking with the guest.',
        );
        expect(
          sentLegacy
              .singleWhere((n) => n.recipientPubkey == MockKeys.guest.publicKey)
              .content,
          'You successfully reserved Lake House 2026-05-01 - 2026-05-03, '
          "hosted by Maya. Your payment is safely in escrow. We've reached "
          'out to the host to confirm, and they should be in touch soon. If '
          'they do not confirm in a timely manner, you can be refunded.',
        );
        expect(
          sentLegacy
              .singleWhere(
                (n) => n.recipientPubkey == MockKeys.reviewer.publicKey,
              )
              .content,
          'A reservation was placed for Lake House 2026-05-01 - 2026-05-03. '
          'Payment has been paid and is sitting in escrow. Please login to '
          'https://hostr.network to confirm the booking with the guest.',
        );
        expect(
          sent
              .expand((n) => n.tags)
              .where((tag) => tag.first == 'hostr_notice'),
          containsAll([
            [
              'hostr_notice',
              'reservation_placed',
              'buyer',
              MockKeys.guest.publicKey,
            ],
            [
              'hostr_notice',
              'reservation_placed',
              'seller',
              MockKeys.reviewer.publicKey,
            ],
          ]),
        );
        expect(
          sent.expand((n) => n.tags),
          containsAll([
            ['tradeId', 'trade-123'],
            ['tradeId', 'trade-123'],
          ]),
        );
        expect(
          sent.expand((n) => n.tags).any((tag) => tag.first == 'conversation'),
          isFalse,
        );
        expect(
          sentLegacy.expand((n) => n.tags),
          containsAll([
            ['tradeId', 'trade-123'],
            ['tradeId', 'trade-123'],
          ]),
        );
        expect(
          sentLegacy
              .expand((n) => n.tags)
              .any((tag) => tag.first == 'conversation'),
          isFalse,
        );
      },
    );

    test(
      'falls back to public listing seller when no seller proof exists',
      () async {
        final group = await _group(buyerProof: true);

        await notifier.notifyReservation(group);

        expect(sent.map((n) => n.recipientPubkeys.single).toSet(), {
          MockKeys.guest.publicKey,
          MockKeys.hoster.publicKey,
        });
        expect(sentLegacy.map((n) => n.recipientPubkey).toSet(), {
          MockKeys.guest.publicKey,
          MockKeys.hoster.publicKey,
        });
      },
    );

    test(
      'skips both delivery paths when NIP-17 notice already exists',
      () async {
        existing = [
          _existingNotice(
            tradeId: 'trade-123',
            role: 'buyer',
            recipientPubkey: MockKeys.guest.publicKey,
          ),
        ];
        final group = await _group(buyerProof: true);

        await notifier.notifyReservation(group);

        expect(sent, hasLength(1));
        expect(sentLegacy, hasLength(1));
        expect(sent.single.recipientPubkeys.single, MockKeys.hoster.publicKey);
        expect(sentLegacy.single.recipientPubkey, MockKeys.hoster.publicKey);
        expect(
          sent.single.tags.any(
            (tag) =>
                tag.length == 4 &&
                tag[0] == 'hostr_notice' &&
                tag[1] == 'reservation_placed' &&
                tag[2] == 'seller' &&
                tag[3] == MockKeys.hoster.publicKey,
          ),
          isTrue,
        );
      },
    );

    test('does not treat another trade notice as already sent', () async {
      existing = [
        _existingNotice(
          tradeId: 'other-trade',
          role: 'buyer',
          recipientPubkey: MockKeys.guest.publicKey,
        ),
      ];
      final group = await _group(buyerProof: true);

      await notifier.notifyReservation(group);

      expect(sent.map((n) => n.recipientPubkeys.single).toSet(), {
        MockKeys.guest.publicKey,
        MockKeys.hoster.publicKey,
      });
      expect(sentLegacy.map((n) => n.recipientPubkey).toSet(), {
        MockKeys.guest.publicKey,
        MockKeys.hoster.publicKey,
      });
    });

    test('does not treat inbound matching messages as already sent', () async {
      existing = [
        _existingNotice(
          tradeId: 'trade-123',
          role: 'buyer',
          recipientPubkey: MockKeys.guest.publicKey,
          authorPubkey: MockKeys.guest.publicKey,
        ),
      ];
      final group = await _group(buyerProof: true);

      await notifier.notifyReservation(group);

      expect(sent.map((n) => n.recipientPubkeys.single).toSet(), {
        MockKeys.guest.publicKey,
        MockKeys.hoster.publicKey,
      });
      expect(sentLegacy.map((n) => n.recipientPubkey).toSet(), {
        MockKeys.guest.publicKey,
        MockKeys.hoster.publicKey,
      });
    });

    test('does not notify anyone without a decryptable buyer proof', () async {
      final group = await _group(buyerProof: false);

      await notifier.notifyReservation(group);

      expect(sent, isEmpty);
      expect(sentLegacy, isEmpty);
    });

    test('does not notify anyone when the reservation already ended', () async {
      final group = await _group(
        buyerProof: true,
        sellerProof: true,
        end: DateTime.utc(2026, 4, 22),
      );

      await notifier.notifyReservation(group);

      expect(sent, isEmpty);
      expect(sentLegacy, isEmpty);
    });
  });
}
