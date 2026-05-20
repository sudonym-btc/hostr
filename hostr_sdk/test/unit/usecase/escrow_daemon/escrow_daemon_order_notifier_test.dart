@Tags(['unit'])
library;

import 'package:hostr_sdk/usecase/escrow_daemon/escrow_daemon.dart';
import 'package:hostr_sdk/usecase/orders/order_participant_tags.dart';
import 'package:hostr_sdk/util/coinlib_gift_wrap.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/ndk.dart' show Metadata;
import 'package:ndk/shared/nips/nip01/key_pair.dart';
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

final int _futureOrderYear = DateTime.now().toUtc().year + 1;
final String _defaultOrderRange =
    '1 May $_futureOrderYear - 3 May $_futureOrderYear';

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

Future<String> _signAuthorization({
  required String listingAnchor,
  required KeyPair identityKeyPair,
  required OrderParticipantAuthorizationDraft draft,
}) async {
  final authorization = TradeKeyAuthorization.create(
    identityPubkey: draft.identityPubkey,
    listingAnchor: listingAnchor,
    tradeId: draft.tradeId,
    participantPubkey: draft.participantPubkey,
    role: draft.role,
  ).signAs(identityKeyPair, TradeKeyAuthorization.fromNostrEvent);
  return OrderParticipantAuthorizationPayload.fromAuthorizationEvent(
    authorization,
  ).encode();
}

Future<OrderParticipantTagPlan> _participantTags({
  required String tradeId,
  required String listingAnchor,
  required KeyPair orderAuthorKey,
  required KeyPair disposableBuyer,
  required bool buyerProof,
  required bool sellerProof,
  bool includeEscrowParticipant = true,
}) {
  final sellerIdentity = sellerProof ? MockKeys.reviewer : MockKeys.hoster;
  final buyerIdentity = buyerProof ? MockKeys.guest : disposableBuyer;

  return buildOrderParticipantTagPlan(
    tradeId: tradeId,
    orderAuthorKey: orderAuthorKey,
    participants: [
      OrderParticipant(
        role: 'seller',
        participantPubkey: MockKeys.hoster.publicKey,
        identityPubkey: sellerIdentity.publicKey,
      ),
      OrderParticipant(
        role: 'buyer',
        participantPubkey: disposableBuyer.publicKey,
        identityPubkey: buyerIdentity.publicKey,
      ),
      if (includeEscrowParticipant)
        OrderParticipant.real(
          role: 'escrow',
          pubkey: MockKeys.escrow.publicKey,
        ),
    ],
    signAuthorization: (draft) => _signAuthorization(
      listingAnchor: listingAnchor,
      identityKeyPair: draft.role == 'seller' ? sellerIdentity : buyerIdentity,
      draft: draft,
    ),
    encryptAuthorization:
        ({
          required plaintext,
          required senderPrivateKey,
          required recipientPubkey,
        }) => coinlibEncryptNip44(plaintext, senderPrivateKey, recipientPubkey),
  );
}

Future<OrderGroup> _group({
  required bool buyerProof,
  bool sellerProof = false,
  bool includeEscrowParticipant = true,
  String tradeId = 'trade-123',
  DateTime? start,
  DateTime? end,
}) async {
  final disposableBuyer = mockKeys[30];
  final listingAnchor = '30402:${MockKeys.hoster.publicKey}:listing-1';
  final orderStart = start ?? DateTime.utc(_futureOrderYear, 5, 1);
  final orderEnd = end ?? DateTime.utc(_futureOrderYear, 5, 3);
  final buyerTags = await _participantTags(
    tradeId: tradeId,
    listingAnchor: listingAnchor,
    orderAuthorKey: disposableBuyer,
    disposableBuyer: disposableBuyer,
    buyerProof: buyerProof,
    sellerProof: sellerProof,
    includeEscrowParticipant: includeEscrowParticipant,
  );

  final buyer = Order.create(
    pubKey: disposableBuyer.publicKey,
    dTag: tradeId,
    listingAnchor: listingAnchor,
    extraTags: buyerTags.tags,
    stage: OrderStage.commit,
    start: orderStart,
    end: orderEnd,
  );
  final sellerTags = await _participantTags(
    tradeId: tradeId,
    listingAnchor: listingAnchor,
    orderAuthorKey: MockKeys.hoster,
    disposableBuyer: disposableBuyer,
    buyerProof: buyerProof,
    sellerProof: sellerProof,
    includeEscrowParticipant: includeEscrowParticipant,
  );

  final seller = Order.create(
    pubKey: MockKeys.hoster.publicKey,
    dTag: tradeId,
    listingAnchor: listingAnchor,
    extraTags: sellerTags.tags,
    stage: OrderStage.commit,
    start: orderStart,
    end: orderEnd,
  );

  return OrderGroup(orders: [buyer, seller]);
}

TextMessage _existingNotice({
  required String tradeId,
  required String role,
  required String recipientPubkey,
  String noticeType = 'order_placed',
  String? authorPubkey,
}) {
  return TextMessage(
    pubKey: authorPubkey ?? MockKeys.escrow.publicKey,
    tags: MessageTags([
      ['tradeId', tradeId],
      ['p', recipientPubkey],
      ['hostr_notice', noticeType, role, recipientPubkey],
    ]),
    content: 'already sent',
    createdAt: 123,
  );
}

void main() {
  group('EscrowOrderNotifier', () {
    late List<_SentNotice> sent;
    late List<_SentLegacyNotice> sentLegacy;
    late List<TextMessage> existing;
    late EscrowOrderNotifier notifier;

    setUp(() {
      sent = [];
      sentLegacy = [];
      existing = [];
      notifier = EscrowOrderNotifier(
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

        await notifier.notifyOrder(group);

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
          'You successfully reserved Lake House $_defaultOrderRange, '
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
          'A order was placed for Lake House $_defaultOrderRange. '
          'Payment has been paid and is sitting in escrow. Please login to '
          'https://hostr.network to confirm the booking with the guest.',
        );
        expect(
          sentLegacy
              .singleWhere((n) => n.recipientPubkey == MockKeys.guest.publicKey)
              .content,
          'You successfully reserved Lake House $_defaultOrderRange, '
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
          'A order was placed for Lake House $_defaultOrderRange. '
          'Payment has been paid and is sitting in escrow. Please login to '
          'https://hostr.network to confirm the booking with the guest.',
        );
        expect(
          sent
              .expand((n) => n.tags)
              .where((tag) => tag.first == 'hostr_notice'),
          containsAll([
            ['hostr_notice', 'order_placed', 'buyer', MockKeys.guest.publicKey],
            [
              'hostr_notice',
              'order_placed',
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

        await notifier.notifyOrder(group);

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

        await notifier.notifyOrder(group);

        expect(sent, hasLength(1));
        expect(sentLegacy, hasLength(1));
        expect(sent.single.recipientPubkeys.single, MockKeys.hoster.publicKey);
        expect(sentLegacy.single.recipientPubkey, MockKeys.hoster.publicKey);
        expect(
          sent.single.tags.any(
            (tag) =>
                tag.length == 4 &&
                tag[0] == 'hostr_notice' &&
                tag[1] == 'order_placed' &&
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

      await notifier.notifyOrder(group);

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

      await notifier.notifyOrder(group);

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
      final group = await _group(
        buyerProof: true,
        includeEscrowParticipant: false,
      );

      await notifier.notifyOrder(group);

      expect(sent, isEmpty);
      expect(sentLegacy, isEmpty);
    });

    test('does not notify anyone when the order already ended', () async {
      final group = await _group(
        buyerProof: true,
        sellerProof: true,
        end: DateTime.utc(2026, 4, 22),
      );

      await notifier.notifyOrder(group);

      expect(sent, isEmpty);
      expect(sentLegacy, isEmpty);
    });

    test('sends cancellation notice only to buyer', () async {
      final group = await _group(buyerProof: true, sellerProof: true);

      await notifier.notifyCancellation(group);

      expect(sent, hasLength(1));
      expect(sentLegacy, hasLength(1));
      expect(sent.single.recipientPubkeys, [MockKeys.guest.publicKey]);
      expect(sentLegacy.single.recipientPubkey, MockKeys.guest.publicKey);
      expect(
        sent.single.content,
        'Your order for Lake House $_defaultOrderRange could not '
        'be confirmed by escrow. No booking was created, and any escrowed '
        'payment should be refunded according to the payment method used.',
      );
      expect(
        sent.single.tags.map((tag) => tag.join('|')),
        contains(
          'hostr_notice|order_cancelled|buyer|'
          '${MockKeys.guest.publicKey}',
        ),
      );
    });

    test('skips cancellation notice when buyer was already notified', () async {
      existing = [
        _existingNotice(
          tradeId: 'trade-123',
          noticeType: 'order_cancelled',
          role: 'buyer',
          recipientPubkey: MockKeys.guest.publicKey,
        ),
      ];
      final group = await _group(buyerProof: true, sellerProof: true);

      await notifier.notifyCancellation(group);

      expect(sent, isEmpty);
      expect(sentLegacy, isEmpty);
    });
  });
}
