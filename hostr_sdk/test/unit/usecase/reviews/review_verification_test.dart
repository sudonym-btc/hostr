@Tags(['unit'])
library;

import 'dart:async';

import 'package:hostr_sdk/datasources/nostr/mock.relay.dart' show matchEvent;
import 'package:hostr_sdk/seed/seed.dart';
import 'package:hostr_sdk/usecase/escrow/escrow_verification.dart';
import 'package:hostr_sdk/usecase/listings/listings.dart';
import 'package:hostr_sdk/usecase/requests/requests.dart' as hostr_requests;
import 'package:hostr_sdk/usecase/reservations/reservation_pubkey_proofs.dart';
import 'package:hostr_sdk/usecase/reservations/reservations.dart';
import 'package:hostr_sdk/usecase/reviews/reviews.dart';
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
  Future<List<RelayBroadcastResponse>> broadcast({
    required Nip01Event event,
    List<String>? relays,
  }) async {
    events.add(event);
    return [];
  }

  Future<void> closeAll() async {
    for (final sub in _subscriptions) {
      await sub.close();
    }
  }
}

class _StubEscrowVerification extends Fake implements EscrowVerification {
  final Set<String> validTradeIds;

  _StubEscrowVerification({this.validTradeIds = const {}});

  @override
  Future<EscrowVerificationResult> verify({
    required Reservation reservation,
  }) async {
    final tradeId = reservation.getDtag();
    if (tradeId != null && validTradeIds.contains(tradeId)) {
      return const EscrowVerificationResult.valid();
    }
    return const EscrowVerificationResult.invalid('mock on-chain failure');
  }
}

Future<Reservation> _reservation({
  required Listing listing,
  required KeyPair signer,
  required String tradeId,
  required DateTime start,
  required DateTime end,
  PaymentProof? proof,
  ReservationStage stage = ReservationStage.negotiate,
  int createdAtOffsetSeconds = 0,
  String? recipient,
  List<PTag>? pTags,
}) => _f.reservation(
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

Future<Reservation> _withBuyerProof({
  required Reservation reservation,
  required KeyPair identityKeyPair,
  required KeyPair reservationAuthorKeyPair,
}) {
  return reservation.attachPubkeyProof(
    role: 'buyer',
    proofKeyPair: identityKeyPair,
    encryptionKeyPair: reservationAuthorKeyPair,
  );
}

Review _review({
  required KeyPair signer,
  required Listing listing,
  required Reservation proofReservation,
  required KeyPair proofReservationAuthorKeyPair,
  String? reservationAnchor,
}) {
  final revealKeyPair = deriveReviewRevealKeyPair(
    reservation: proofReservation,
    reservationAuthorKeyPair: proofReservationAuthorKeyPair,
    role: 'buyer',
  );

  return Review(
    pubKey: signer.publicKey,
    createdAt: DateTime(2026, 6, 1).millisecondsSinceEpoch ~/ 1000,
    tags: ReviewTags([
      [kListingRefTag, listing.anchor!],
      if (reservationAnchor != null) [kReservationRefTag, reservationAnchor],
    ]),
    content: ReviewContent(
      rating: 5,
      content: 'Great stay!',
      proof: ParticipationProof(revealPrivateKey: revealKeyPair.privateKey!),
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
      txHash: '0xabc123',
      escrowService: escrowService,
      hostsEscrowMethods: EscrowMethod.fromNostrEvent(methodEvent),
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
    late Reservations reservations;
    late Listings listings;
    late Listing listing;

    setUp(() {
      fakeRequests = _FakeRequests();
      escrowVerification = _StubEscrowVerification();
      final logger = CustomLogger();

      listings = Listings(requests: fakeRequests, logger: logger);
      reservations = Reservations(
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
        reservations: reservations,
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
      'host-confirmed reservation validates a review via trade-group proof',
      () async {
        final buyerAlias = MockKeys.reviewer;

        final negotiate = await _withBuyerProof(
          reservation: await _reservation(
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
          reservationAuthorKeyPair: buyerAlias,
        );
        final hostCommit = await _reservation(
          listing: listing,
          signer: MockKeys.hoster,
          tradeId: 'trade-host-confirmed',
          start: DateTime(2026, 2, 1),
          end: DateTime(2026, 2, 3),
          stage: ReservationStage.commit,
          recipient: buyerAlias.publicKey,
          pTags: [
            PTag.seller(listing.pubKey),
            PTag.buyer(buyerAlias.publicKey),
          ],
        );
        final review = _review(
          signer: MockKeys.guest,
          listing: listing,
          proofReservation: negotiate,
          proofReservationAuthorKeyPair: buyerAlias,
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

    test('invalid review when no reservation exists', () async {
      final proofReservation = Reservation.create(
        pubKey: MockKeys.guest.publicKey,
        dTag: 'trade-missing',
        listingAnchor: listing.anchor!,
        start: DateTime(2026, 2, 1),
        end: DateTime(2026, 2, 3),
      );
      final review = _review(
        signer: MockKeys.guest,
        listing: listing,
        proofReservation: proofReservation,
        proofReservationAuthorKeyPair: MockKeys.guest,
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
        contains('No matching reservation'),
      );

      await verified.close();
    });

    test(
      'invalid review when reveal key does not match any proof capsule',
      () async {
        final buyerAlias = MockKeys.reviewer;
        final seededReservation = await _withBuyerProof(
          reservation: await _reservation(
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
          reservationAuthorKeyPair: buyerAlias,
        );
        final wrongAlias = MockKeys.escrow;
        final wrongReservation = Reservation.create(
          pubKey: wrongAlias.publicKey,
          dTag: 'trade-wrong',
          listingAnchor: listing.anchor!,
          start: DateTime(2026, 2, 1),
          end: DateTime(2026, 2, 3),
        );
        final review = _review(
          signer: MockKeys.guest,
          listing: listing,
          proofReservation: wrongReservation,
          proofReservationAuthorKeyPair: wrongAlias,
        );

        fakeRequests.events.addAll([seededReservation, review]);

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
        reservations: reservations,
        listings: listings,
        escrowVerification: escrowVerification,
      );

      for (final tradeId in tradeIds) {
        final commit = await _withBuyerProof(
          reservation: await _reservation(
            listing: listing,
            signer: MockKeys.guest,
            tradeId: tradeId,
            start: DateTime(2026, 3, 1),
            end: DateTime(2026, 3, 5),
            stage: ReservationStage.commit,
            recipient: MockKeys.guest.publicKey,
            proof: _escrowPaymentProof(listing: listing),
            pTags: [
              PTag.seller(listing.pubKey),
              PTag.buyer(MockKeys.guest.publicKey),
              PTag.escrow(MockKeys.escrow.publicKey),
            ],
          ),
          identityKeyPair: MockKeys.guest,
          reservationAuthorKeyPair: MockKeys.guest,
        );
        fakeRequests.events.add(commit);
        fakeRequests.events.add(
          _review(
            signer: MockKeys.guest,
            listing: listing,
            proofReservation: commit,
            proofReservationAuthorKeyPair: MockKeys.guest,
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
      'escrow-backed buyer reservation validates review when confirmed committed',
      () async {
        const tradeId = 'trade-escrow-valid';
        final commit = await _withBuyerProof(
          reservation: await _reservation(
            listing: listing,
            signer: MockKeys.guest,
            tradeId: tradeId,
            start: DateTime(2026, 4, 1),
            end: DateTime(2026, 4, 3),
            stage: ReservationStage.commit,
            recipient: MockKeys.guest.publicKey,
            proof: _escrowPaymentProof(listing: listing),
            pTags: [
              PTag.seller(listing.pubKey),
              PTag.buyer(MockKeys.guest.publicKey),
              PTag.escrow(MockKeys.escrow.publicKey),
            ],
          ),
          identityKeyPair: MockKeys.guest,
          reservationAuthorKeyPair: MockKeys.guest,
        );
        escrowVerification = _StubEscrowVerification(validTradeIds: {tradeId});
        reviews = Reviews(
          requests: fakeRequests,
          logger: CustomLogger(),
          reservations: reservations,
          listings: listings,
          escrowVerification: escrowVerification,
        );

        fakeRequests.events.add(commit);
        fakeRequests.events.add(
          _review(
            signer: MockKeys.guest,
            listing: listing,
            proofReservation: commit,
            proofReservationAuthorKeyPair: MockKeys.guest,
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
          reservation: await _reservation(
            listing: listing,
            signer: MockKeys.guest,
            tradeId: tradeId,
            start: DateTime(2026, 4, 1),
            end: DateTime(2026, 4, 3),
            stage: ReservationStage.commit,
            recipient: MockKeys.guest.publicKey,
            proof: _escrowPaymentProof(listing: listing),
            pTags: [
              PTag.seller(listing.pubKey),
              PTag.buyer(MockKeys.guest.publicKey),
              PTag.escrow(MockKeys.escrow.publicKey),
            ],
          ),
          identityKeyPair: MockKeys.guest,
          reservationAuthorKeyPair: MockKeys.guest,
        );
        final cancel = commit
            .copy(
              createdAt: commit.createdAt + 1,
              id: null,
              content: commit.parsedContent.copyWith(
                stage: ReservationStage.cancel,
              ),
            )
            .signAs(MockKeys.guest, Reservation.fromNostrEvent);

        escrowVerification = _StubEscrowVerification(validTradeIds: {tradeId});
        reviews = Reviews(
          requests: fakeRequests,
          logger: CustomLogger(),
          reservations: reservations,
          listings: listings,
          escrowVerification: escrowVerification,
        );

        fakeRequests.events.addAll([
          commit,
          cancel,
          _review(
            signer: MockKeys.guest,
            listing: listing,
            proofReservation: commit,
            proofReservationAuthorKeyPair: MockKeys.guest,
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
