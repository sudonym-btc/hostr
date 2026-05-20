@Tags(['unit'])
library;

import 'dart:async';

import 'package:hostr_sdk/datasources/nostr/mock.relay.dart' show matchEvent;
import 'package:hostr_sdk/seed/seed.dart';
import 'package:hostr_sdk/usecase/escrow/escrow_verification.dart';
import 'package:hostr_sdk/usecase/listings/listings.dart';
import 'package:hostr_sdk/usecase/metadata/metadata.dart';
import 'package:hostr_sdk/usecase/requests/requests.dart' as hostr_requests;
import 'package:hostr_sdk/usecase/orders/order_participant_authorization.dart';
import 'package:hostr_sdk/usecase/orders/order_participant_tags.dart';
import 'package:hostr_sdk/usecase/orders/orders.dart';
import 'package:hostr_sdk/usecase/reviews/reviews.dart';
import 'package:hostr_sdk/util/coinlib_gift_wrap.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:mockito/mockito.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/entities.dart' show RelayBroadcastResponse;
import 'package:ndk/ndk.dart'
    show Filter, Nip01Event, Nip01EventModel, Nip01Utils;
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import '../../../support/fakes.dart';

final _f = EntityFactory();

class _FakeRequests extends Fake implements hostr_requests.Requests {
  final List<Nip01Event> events = [];
  final List<StreamWithStatus<dynamic>> _subscriptions = [];

  @override
  StreamWithStatus<T> subscribe<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
    String? name,
    bool setSinceOnLiveFilter = true,
  }) {
    final source = StreamWithStatus<T>();
    _subscriptions.add(source);

    Future.microtask(() {
      source.addStatus(StreamStatusQuerying());
      for (final event in events) {
        if (matchEvent(event, filter)) {
          source.add(event as T);
        }
      }
      source.addStatus(StreamStatusQueryComplete());
      source.addStatus(StreamStatusLive());
    });

    return source;
  }

  @override
  Stream<T> query<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
    Duration? timeout,
    String? name,
    bool cacheRead = true,
    bool cacheWrite = true,
  }) async* {
    for (final event in events) {
      if (matchEvent(event, filter)) {
        yield event as T;
      }
    }
  }

  @override
  Future<hostr_requests.BroadcastResult> broadcastEvent({
    required Nip01Event event,
    List<String>? relays,
    hostr_requests.NostrEventSigner? signer,
  }) async {
    final eventToBroadcast = event.sig == null && signer != null
        ? await signer(event)
        : event;
    events.add(eventToBroadcast);
    return hostr_requests.BroadcastResult(
      event: eventToBroadcast,
      responses: [_successfulBroadcastResponse()],
    );
  }

  Future<void> closeAll() async {
    for (final sub in _subscriptions) {
      await sub.close();
    }
  }
}

class _FakeMetadata extends Fake implements MetadataUseCase {
  @override
  Future<void> ensureSellerConfig(String pubkey) async {}
}

RelayBroadcastResponse _successfulBroadcastResponse() {
  return RelayBroadcastResponse(
    relayUrl: 'wss://relay.test',
    okReceived: true,
    broadcastSuccessful: true,
  );
}

class _StubEscrowVerification extends Fake implements EscrowVerification {
  final Set<String> validTradeIds;

  _StubEscrowVerification({this.validTradeIds = const {}});

  @override
  Future<EscrowVerificationResult> verify({required Order order}) async {
    final tradeId = order.getDtag();
    if (tradeId != null && validTradeIds.contains(tradeId)) {
      return const EscrowVerificationResult.valid();
    }
    return const EscrowVerificationResult.invalid('mock on-chain failure');
  }
}

Future<Order> _order({
  required Listing listing,
  required KeyPair signer,
  required String tradeId,
  required DateTime start,
  required DateTime end,
  PaymentProof? proof,
  OrderStage stage = OrderStage.negotiate,
  int createdAtOffsetSeconds = 0,
  String? recipient,
  List<PTag>? pTags,
}) => _f.order(
  listing: listing,
  dTag: tradeId,
  signerOverride: signer,
  start: start,
  end: end,
  proof: proof,
  stage: stage,
  recipient: recipient,
  pTags: pTags,
  createdAt:
      DateTime(2026, 1, 1).millisecondsSinceEpoch ~/ 1000 +
      createdAtOffsetSeconds,
);

Future<Order> _withBuyerProof({
  required Order order,
  required KeyPair identityKeyPair,
  required KeyPair orderAuthorKeyPair,
}) async {
  final tradeId = order.getDtag();
  if (tradeId == null || tradeId.isEmpty) {
    throw StateError('Order trade id is required');
  }
  final sellerPubkey = getPubKeyFromAnchor(order.parsedTags.listingAnchor);
  final buyerPubkey = order.participantPubkeyForRole('buyer');
  final escrowPubkey = order.parsedTags.getTagValueByMarker('p', 'escrow');
  final plan = await buildOrderParticipantTagPlan(
    tradeId: tradeId,
    orderAuthorKey: orderAuthorKeyPair,
    participants: [
      OrderParticipant.real(role: 'seller', pubkey: sellerPubkey),
      OrderParticipant(
        role: 'buyer',
        participantPubkey: buyerPubkey,
        identityPubkey: identityKeyPair.publicKey,
      ),
      if (escrowPubkey != null)
        OrderParticipant.real(role: 'escrow', pubkey: escrowPubkey),
    ],
    signAuthorization: (draft) async {
      final authorization = TradeKeyAuthorization.create(
        identityPubkey: draft.identityPubkey,
        listingAnchor: order.parsedTags.listingAnchor,
        tradeId: draft.tradeId,
        participantPubkey: draft.participantPubkey,
        role: draft.role,
      ).signAs(identityKeyPair, TradeKeyAuthorization.fromNostrEvent);
      return OrderParticipantAuthorizationPayload.fromAuthorizationEvent(
        authorization,
      ).encode();
    },
    encryptAuthorization:
        ({
          required plaintext,
          required senderPrivateKey,
          required recipientPubkey,
        }) => coinlibEncryptNip44(plaintext, senderPrivateKey, recipientPubkey),
  );

  final retainedTags = order.parsedTags.tags.where((tag) {
    if (tag.isEmpty) return true;
    return tag.first != 'p' && tag.first != kOrderParticipantProofTag;
  });
  return order
      .copy(
        id: null,
        sig: null,
        tags: OrderTags([...retainedTags, ...plan.tags]),
      )
      .signAs(orderAuthorKeyPair, Order.fromNostrEvent);
}

String _signedAuthorizationPayload({
  required KeyPair signer,
  required Order order,
  required String role,
}) {
  final tradeId = order.getDtag();
  if (tradeId == null || tradeId.isEmpty) {
    throw StateError('Order trade id is required');
  }
  final authorization = TradeKeyAuthorization.create(
    identityPubkey: signer.publicKey,
    listingAnchor: order.parsedTags.listingAnchor,
    tradeId: tradeId,
    participantPubkey: order.participantPubkeyForRole(role),
    role: role,
  ).signAs(signer, TradeKeyAuthorization.fromNostrEvent);
  return OrderParticipantAuthorizationPayload.fromAuthorizationEvent(
    authorization,
  ).encode();
}

Future<ParticipationProof> _proofForReview({
  required KeyPair signer,
  required Order order,
  required KeyPair proofRecipientKeyPair,
  String role = 'buyer',
}) async {
  final privateKey = proofRecipientKeyPair.privateKey;
  final participantPubkey = order.participantPubkeyForRole(role);
  if (privateKey != null && privateKey.isNotEmpty) {
    for (final proof in order.parsedTags.participantProofs) {
      if (proof.role != role) continue;
      if (proof.participantPubkey != participantPubkey) continue;
      if (proof.recipientPubkey != proofRecipientKeyPair.publicKey) continue;
      final plaintext = await coinlibDecryptNip44(
        proof.payload,
        privateKey,
        order.pubKey,
      );
      if (!proof.matchesPayload(plaintext)) continue;
      final payload = OrderParticipantAuthorizationPayload.tryDecode(plaintext);
      if (payload?.pubkey != signer.publicKey) continue;
      return ParticipationProof(
        role: role,
        participantPubkey: participantPubkey,
        authorizationPayload: plaintext,
      );
    }
  }

  return ParticipationProof(
    role: role,
    participantPubkey: participantPubkey,
    authorizationPayload: _signedAuthorizationPayload(
      signer: signer,
      order: order,
      role: role,
    ),
  );
}

Future<Review> _review({
  required KeyPair signer,
  required Listing listing,
  required Order proofOrder,
  required KeyPair proofOrderAuthorKeyPair,
  String? orderAnchor,
}) async {
  return Review(
    pubKey: signer.publicKey,
    createdAt: DateTime(2026, 6, 1).millisecondsSinceEpoch ~/ 1000,
    tags: ReviewTags([
      ['d', proofOrder.getDtag() ?? 'review-trade'],
      [kListingRefTag, listing.anchor!],
      if (orderAnchor != null) [kOrderRefTag, orderAnchor],
    ]),
    content: ReviewContent(
      rating: 5,
      content: 'Great stay!',
      proof: await _proofForReview(
        signer: signer,
        order: proofOrder,
        proofRecipientKeyPair: proofOrderAuthorKeyPair,
      ),
    ),
  ).signAs(signer, Review.fromNostrEvent);
}

PaymentProof _escrowPaymentProof({required Listing listing}) {
  final escrowService = MOCK_ESCROWS(
    contractAddress: '0xDEAD',
    evmAddress: '0x000000000000000000000000000000000000bEEF',
  ).first;
  final methodEvent = Nip01Utils.signWithPrivateKey(
    event: Nip01Event(
      kind: kNostrKindEscrowMethod,
      pubKey: MockKeys.hoster.publicKey,
      tags: const [],
      content: '',
    ),
    privateKey: MockKeys.hoster.privateKey!,
  );

  return PaymentProof(
    hoster: Nip01EventModel.fromEntity(
      Nip01Utils.signWithPrivateKey(
        event: Nip01Event(
          kind: 0,
          pubKey: MockKeys.hoster.publicKey,
          tags: const [],
          content: '',
        ),
        privateKey: MockKeys.hoster.privateKey!,
      ),
    ),
    listing: listing,
    zapProof: null,
    escrowProof: EscrowProof(
      escrowService: escrowService,
      sellerEscrowMethods: EscrowMethod.fromNostrEvent(methodEvent),
      params: EvmEscrowProofParams(txHash: '0xabc123'),
    ),
  );
}

Listing _fixtureListing() => _f.listing(
  signer: MockKeys.hoster,
  dTag: 'review-listing',
  title: 'Review Listing',
  description: 'Fixture',
  images: const [],
  priceSats: 100000,
  location: 'Test',
  type: ListingType.house,
  specifications: Specifications(),
);

void main() {
  group('Reviews.subscribeVerified', () {
    late _FakeRequests fakeRequests;
    late _StubEscrowVerification escrowVerification;
    late Reviews reviews;
    late Orders orders;
    late Listings listings;
    late Listing listing;

    setUp(() {
      fakeRequests = _FakeRequests();
      escrowVerification = _StubEscrowVerification();
      final logger = CustomLogger();

      listings = Listings(
        requests: fakeRequests,
        logger: logger,
        metadata: _FakeMetadata(),
      );
      orders = Orders(
        requests: fakeRequests,
        logger: logger,
        messaging: FakeMessaging(),
        auth: FakeAuth(),
        transitions: FakeTransitions(),
        listings: listings,
        relays: FakeRelays(),
      );
      reviews = Reviews(
        requests: fakeRequests,
        logger: logger,
        orders: orders,
        listings: listings,
        escrowVerification: escrowVerification,
      );

      listing = _fixtureListing();
      fakeRequests.events.add(listing);
    });

    tearDown(() async {
      await fakeRequests.closeAll();
    });

    test(
      'host-confirmed order validates a review via trade-group proof',
      () async {
        final buyerAlias = MockKeys.reviewer;

        final negotiate = await _withBuyerProof(
          order: await _order(
            listing: listing,
            signer: buyerAlias,
            tradeId: 'trade-host-confirmed',
            start: DateTime(2026, 2, 1),
            end: DateTime(2026, 2, 3),
            recipient: buyerAlias.publicKey,
            pTags: [
              PTag.seller(listing.pubKey),
              PTag.buyer(buyerAlias.publicKey),
            ],
          ),
          identityKeyPair: MockKeys.guest,
          orderAuthorKeyPair: buyerAlias,
        );
        final hostCommit = await _order(
          listing: listing,
          signer: MockKeys.hoster,
          tradeId: 'trade-host-confirmed',
          start: DateTime(2026, 2, 1),
          end: DateTime(2026, 2, 3),
          stage: OrderStage.commit,
          recipient: buyerAlias.publicKey,
          pTags: [
            PTag.seller(listing.pubKey),
            PTag.buyer(buyerAlias.publicKey),
          ],
        );
        final review = await _review(
          signer: MockKeys.guest,
          listing: listing,
          proofOrder: negotiate,
          proofOrderAuthorKeyPair: buyerAlias,
        );

        fakeRequests.events.addAll([negotiate, hostCommit, review]);

        final verified = reviews.subscribeVerified(
          filter: Filter(
            tags: {
              kListingRefTag: [listing.anchor!],
            },
          ),
          debounce: Duration.zero,
        );

        final snapshot = await verified.itemsStream.firstWhere(
          (items) => items.isNotEmpty,
        );
        expect(snapshot, hasLength(1));
        expect(snapshot.first, isA<Valid<Review>>());

        await verified.close();
      },
    );

    test('invalid review when no order exists', () async {
      final proofOrder = Order.create(
        pubKey: MockKeys.guest.publicKey,
        dTag: 'trade-missing',
        listingAnchor: listing.anchor!,
        start: DateTime(2026, 2, 1),
        end: DateTime(2026, 2, 3),
      );
      final review = await _review(
        signer: MockKeys.guest,
        listing: listing,
        proofOrder: proofOrder,
        proofOrderAuthorKeyPair: MockKeys.guest,
      );
      fakeRequests.events.add(review);

      final verified = reviews.subscribeVerified(
        filter: Filter(
          tags: {
            kListingRefTag: [listing.anchor!],
          },
        ),
        debounce: Duration.zero,
      );

      final snapshot = await verified.itemsStream.firstWhere(
        (items) => items.isNotEmpty,
      );
      expect(snapshot, hasLength(1));
      expect(snapshot.first, isA<Invalid<Review>>());
      expect(
        (snapshot.first as Invalid<Review>).reason,
        contains('No matching order'),
      );

      await verified.close();
    });

    test(
      'invalid review when authorization payload does not match a order proof',
      () async {
        final buyerAlias = MockKeys.reviewer;
        final seededOrder = await _withBuyerProof(
          order: await _order(
            listing: listing,
            signer: buyerAlias,
            tradeId: 'trade-correct',
            start: DateTime(2026, 2, 1),
            end: DateTime(2026, 2, 3),
            recipient: buyerAlias.publicKey,
            pTags: [
              PTag.seller(listing.pubKey),
              PTag.buyer(buyerAlias.publicKey),
            ],
          ),
          identityKeyPair: MockKeys.guest,
          orderAuthorKeyPair: buyerAlias,
        );
        final wrongAlias = MockKeys.escrow;
        final wrongOrder = Order.create(
          pubKey: wrongAlias.publicKey,
          dTag: 'trade-wrong',
          listingAnchor: listing.anchor!,
          start: DateTime(2026, 2, 1),
          end: DateTime(2026, 2, 3),
        );
        final review = await _review(
          signer: MockKeys.guest,
          listing: listing,
          proofOrder: wrongOrder,
          proofOrderAuthorKeyPair: wrongAlias,
        );

        fakeRequests.events.addAll([seededOrder, review]);

        final verified = reviews.subscribeVerified(
          filter: Filter(
            tags: {
              kListingRefTag: [listing.anchor!],
            },
          ),
          debounce: Duration.zero,
        );

        final snapshot = await verified.itemsStream.firstWhere(
          (items) => items.isNotEmpty,
        );
        expect(snapshot, hasLength(1));
        expect(snapshot.first, isA<Invalid<Review>>());
        expect(
          (snapshot.first as Invalid<Review>).reason,
          contains('Participation proof does not match'),
        );

        await verified.close();
      },
    );

    test('multiple reviews batch their dependency lookups', () async {
      final tradeIds = ['trade-a', 'trade-b', 'trade-c'];
      escrowVerification = _StubEscrowVerification(
        validTradeIds: tradeIds.toSet(),
      );
      reviews = Reviews(
        requests: fakeRequests,
        logger: CustomLogger(),
        orders: orders,
        listings: listings,
        escrowVerification: escrowVerification,
      );

      for (final tradeId in tradeIds) {
        final commit = await _withBuyerProof(
          order: await _order(
            listing: listing,
            signer: MockKeys.guest,
            tradeId: tradeId,
            start: DateTime(2026, 3, 1),
            end: DateTime(2026, 3, 5),
            stage: OrderStage.commit,
            recipient: MockKeys.guest.publicKey,
            proof: _escrowPaymentProof(listing: listing),
            pTags: [
              PTag.seller(listing.pubKey),
              PTag.buyer(MockKeys.guest.publicKey),
              PTag.escrow(MockKeys.escrow.publicKey),
            ],
          ),
          identityKeyPair: MockKeys.guest,
          orderAuthorKeyPair: MockKeys.guest,
        );
        fakeRequests.events.add(commit);
        fakeRequests.events.add(
          await _review(
            signer: MockKeys.guest,
            listing: listing,
            proofOrder: commit,
            proofOrderAuthorKeyPair: MockKeys.guest,
          ),
        );
      }

      final verified = reviews.subscribeVerified(
        filter: Filter(
          tags: {
            kListingRefTag: [listing.anchor!],
          },
        ),
        debounce: Duration.zero,
      );

      final snapshot = await verified.itemsStream.firstWhere(
        (items) => items.length >= 3,
      );
      expect(snapshot, hasLength(3));
      expect(snapshot.every((v) => v is Valid<Review>), isTrue);

      await verified.close();
    });

    test(
      'escrow-backed buyer order validates review when confirmed committed',
      () async {
        const tradeId = 'trade-escrow-valid';
        final commit = await _withBuyerProof(
          order: await _order(
            listing: listing,
            signer: MockKeys.guest,
            tradeId: tradeId,
            start: DateTime(2026, 4, 1),
            end: DateTime(2026, 4, 3),
            stage: OrderStage.commit,
            recipient: MockKeys.guest.publicKey,
            proof: _escrowPaymentProof(listing: listing),
            pTags: [
              PTag.seller(listing.pubKey),
              PTag.buyer(MockKeys.guest.publicKey),
              PTag.escrow(MockKeys.escrow.publicKey),
            ],
          ),
          identityKeyPair: MockKeys.guest,
          orderAuthorKeyPair: MockKeys.guest,
        );
        escrowVerification = _StubEscrowVerification(validTradeIds: {tradeId});
        reviews = Reviews(
          requests: fakeRequests,
          logger: CustomLogger(),
          orders: orders,
          listings: listings,
          escrowVerification: escrowVerification,
        );

        fakeRequests.events.add(commit);
        fakeRequests.events.add(
          await _review(
            signer: MockKeys.guest,
            listing: listing,
            proofOrder: commit,
            proofOrderAuthorKeyPair: MockKeys.guest,
          ),
        );

        final verified = reviews.subscribeVerified(
          filter: Filter(
            tags: {
              kListingRefTag: [listing.anchor!],
            },
          ),
          debounce: Duration.zero,
        );

        final snapshot = await verified.itemsStream.firstWhere(
          (items) => items.isNotEmpty,
        );
        expect(snapshot, hasLength(1));
        expect(snapshot.first, isA<Valid<Review>>());

        await verified.close();
      },
    );

    test(
      'later buyer cancellation does not erase review when escrow proof stays valid',
      () async {
        const tradeId = 'trade-escrow-cancelled';
        final commit = await _withBuyerProof(
          order: await _order(
            listing: listing,
            signer: MockKeys.guest,
            tradeId: tradeId,
            start: DateTime(2026, 4, 1),
            end: DateTime(2026, 4, 3),
            stage: OrderStage.commit,
            recipient: MockKeys.guest.publicKey,
            proof: _escrowPaymentProof(listing: listing),
            pTags: [
              PTag.seller(listing.pubKey),
              PTag.buyer(MockKeys.guest.publicKey),
              PTag.escrow(MockKeys.escrow.publicKey),
            ],
          ),
          identityKeyPair: MockKeys.guest,
          orderAuthorKeyPair: MockKeys.guest,
        );
        final cancel = commit
            .copy(
              createdAt: commit.createdAt + 1,
              id: null,
              content: commit.parsedContent.copyWith(stage: OrderStage.cancel),
            )
            .signAs(MockKeys.guest, Order.fromNostrEvent);

        escrowVerification = _StubEscrowVerification(validTradeIds: {tradeId});
        reviews = Reviews(
          requests: fakeRequests,
          logger: CustomLogger(),
          orders: orders,
          listings: listings,
          escrowVerification: escrowVerification,
        );

        fakeRequests.events.addAll([
          commit,
          cancel,
          await _review(
            signer: MockKeys.guest,
            listing: listing,
            proofOrder: commit,
            proofOrderAuthorKeyPair: MockKeys.guest,
          ),
        ]);

        final verified = reviews.subscribeVerified(
          filter: Filter(
            tags: {
              kListingRefTag: [listing.anchor!],
            },
          ),
          debounce: Duration.zero,
        );

        final snapshot = await verified.itemsStream.firstWhere(
          (items) => items.isNotEmpty,
        );
        expect(snapshot, hasLength(1));
        expect(snapshot.first, isA<Valid<Review>>());

        await verified.close();
      },
    );
  });
}
