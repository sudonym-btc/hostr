@Tags(['unit'])
library;

import 'dart:async';

import 'package:hostr_sdk/datasources/nostr/mock.relay.dart' show matchEvent;
import 'package:hostr_sdk/seed/seed.dart';
import 'package:hostr_sdk/usecase/escrow/escrow_verification.dart';
import 'package:hostr_sdk/usecase/listings/listings.dart';
import 'package:hostr_sdk/usecase/requests/requests.dart' as hostr_requests;
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

// ── Fakes ───────────────────────────────────────────────────────────

/// Fake requests that supports both `subscribe` (returning a manually-
/// controlled StreamWithStatus) and `query` (returning filter-matched
/// events from an in-memory store).
class _FakeRequests extends Fake implements hostr_requests.Requests {
  final List<Nip01Event> events = [];
  final List<StreamWithStatus<dynamic>> _subscriptions = [];

  /// Creates a StreamWithStatus that the test can push events into.
  /// Events are also matched against the filter from the in-memory store.
  @override
  StreamWithStatus<T> subscribe<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
    String? name,
    bool setSinceOnLiveFilter = true,
  }) {
    final source = StreamWithStatus<T>();
    _subscriptions.add(source);

    // Emit existing matching events, then go live.
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

// ── Helpers ─────────────────────────────────────────────────────────

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
  ReservationTweakMaterial? tweakMaterial,
}) => _f.reservation(
  listing: listing,
  dTag: tradeId,
  signerOverride: signer,
  start: start,
  end: end,
  proof: proof,
  stage: stage,
  recipient: recipient,
  tweakMaterial: tweakMaterial,
  createdAt:
      DateTime(2026, 1, 1).millisecondsSinceEpoch ~/ 1000 +
      createdAtOffsetSeconds,
);

Review _review({
  required KeyPair signer,
  required Listing listing,
  required ReservationTweakMaterial tweakMaterial,
}) {
  return Review(
    pubKey: signer.publicKey,
    createdAt: DateTime(2026, 6, 1).millisecondsSinceEpoch ~/ 1000,
    tags: ReviewTags([
      [kListingRefTag, listing.anchor!],
    ]),
    content: ReviewContent(
      rating: 5,
      content: 'Great stay!',
      proof: ParticipationProof(tweakMaterial: tweakMaterial),
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
      // Seed the listing so getOneByAnchor can find it.
      fakeRequests.events.add(listing);
    });

    tearDown(() async {
      await fakeRequests.closeAll();
    });

    test('host-confirmed reservation validates a review', () async {
      final salt = 'salt-host-confirmed';
      final tweakMaterial = ReservationTweakMaterial(salt: salt, parity: true);

      // Host published the reservation (auto-valid, no payment proof needed).
      final tweakedKey = tweakKeyPair(
        privateKey: MockKeys.guest.privateKey!,
        salt: salt,
      );
      final hostReservation = await _reservation(
        listing: listing,
        signer: MockKeys.hoster,
        tradeId: 'trade-host-confirmed',
        start: DateTime(2026, 2, 1),
        end: DateTime(2026, 2, 3),
        stage: ReservationStage.commit,
        recipient: tweakedKey.publicKey,
      );
      fakeRequests.events.add(hostReservation);

      // Guest writes a review with proof.
      final review = _review(
        signer: MockKeys.guest,
        listing: listing,
        tweakMaterial: tweakMaterial.copyWith(parity: tweakedKey.parity),
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

      // Wait for the verification pipeline to process all items.
      final snapshot = await verified.itemsStream.firstWhere(
        (items) => items.isNotEmpty,
      );
      expect(snapshot, hasLength(1));
      expect(snapshot.first, isA<Valid<Review>>());

      await verified.close();
    });

    test('invalid review when no reservation exists', () async {
      final salt = 'salt-no-reservation';

      // No reservation seeded — only the review.
      final review = _review(
        signer: MockKeys.guest,
        listing: listing,
        tweakMaterial: ReservationTweakMaterial(salt: salt, parity: false),
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

    test('invalid review when proof does not match commitment', () async {
      final reviewSalt = 'salt-wrong';
      final reservationSalt = 'salt-correct';

      // Reservation with a different salt/commitment.
      final commitment = ParticipationProof.computeCommitmentHash(
        MockKeys.guest.publicKey,
        reservationSalt,
      );

      final hostReservation = await _reservation(
        listing: listing,
        signer: MockKeys.hoster,
        tradeId: commitment,
        start: DateTime(2026, 2, 1),
        end: DateTime(2026, 2, 3),
        // No recipient — simulates a reservation that does not name this guest.
      );
      fakeRequests.events.add(hostReservation);

      // Review with wrong salt — findByTag for the review's computed
      // commitment hash won't find the reservation.
      final review = _review(
        signer: MockKeys.guest,
        listing: listing,
        tweakMaterial: ReservationTweakMaterial(
          salt: reviewSalt,
          parity: false,
        ),
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

      await verified.close();
    });

    test('multiple reviews batch their dependency lookups', () async {
      // Create multiple reviews, each with an escrow-backed paid reservation.
      final salts = ['salt-a', 'salt-b', 'salt-c'];
      escrowVerification = _StubEscrowVerification(
        validTradeIds: {for (final salt in salts) 'trade-$salt'},
      );
      reviews = Reviews(
        requests: fakeRequests,
        logger: CustomLogger(),
        reservations: reservations,
        listings: listings,
        escrowVerification: escrowVerification,
      );
      for (final salt in salts) {
        final tweakedRecipient = tweakKeyPair(
          privateKey: MockKeys.guest.privateKey!,
          salt: salt,
        );
        fakeRequests.events.add(
          await _reservation(
            listing: listing,
            signer: MockKeys.guest,
            tradeId: 'trade-$salt',
            start: DateTime(2026, 3, 1),
            end: DateTime(2026, 3, 5),
            stage: ReservationStage.commit,
            recipient: tweakedRecipient.publicKey,
            tweakMaterial: ReservationTweakMaterial(
              salt: salt,
              parity: tweakedRecipient.parity,
            ),
            proof: _escrowPaymentProof(listing: listing),
          ),
        );
        fakeRequests.events.add(
          _review(
            signer: MockKeys.guest,
            listing: listing,
            tweakMaterial: ReservationTweakMaterial(
              salt: salt,
              parity: tweakedRecipient.parity,
            ),
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
      'escrow-backed buyer reservation validates review when confirmedCommitted=true',
      () async {
        const salt = 'salt-escrow-valid';
        final tweakedKey = tweakKeyPair(
          privateKey: MockKeys.guest.privateKey!,
          salt: salt,
        );
        final negotiate = await _reservation(
          listing: listing,
          signer: MockKeys.guest,
          tradeId: 'trade-$salt',
          start: DateTime(2026, 4, 1),
          end: DateTime(2026, 4, 3),
          recipient: tweakedKey.publicKey,
          tweakMaterial: ReservationTweakMaterial(
            salt: salt,
            parity: tweakedKey.parity,
          ),
        );
        final commit = await _reservation(
          listing: listing,
          signer: MockKeys.guest,
          tradeId: 'trade-$salt',
          start: negotiate.start!,
          end: negotiate.end!,
          stage: ReservationStage.commit,
          recipient: negotiate.recipient,
          tweakMaterial: negotiate.tweakMaterial,
          proof: _escrowPaymentProof(listing: listing),
        );
        escrowVerification = _StubEscrowVerification(
          validTradeIds: {'trade-$salt'},
        );
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
            tweakMaterial: ReservationTweakMaterial(
              salt: salt,
              parity: tweakedKey.parity,
            ),
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
        const salt = 'salt-escrow-cancelled';
        final tweakedKey = tweakKeyPair(
          privateKey: MockKeys.guest.privateKey!,
          salt: salt,
        );
        final commit = await _reservation(
          listing: listing,
          signer: MockKeys.guest,
          tradeId: 'trade-$salt',
          start: DateTime(2026, 4, 1),
          end: DateTime(2026, 4, 3),
          stage: ReservationStage.commit,
          recipient: tweakedKey.publicKey,
          tweakMaterial: ReservationTweakMaterial(
            salt: salt,
            parity: tweakedKey.parity,
          ),
          proof: _escrowPaymentProof(listing: listing),
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

        escrowVerification = _StubEscrowVerification(
          validTradeIds: {'trade-$salt'},
        );
        reviews = Reviews(
          requests: fakeRequests,
          logger: CustomLogger(),
          reservations: reservations,
          listings: listings,
          escrowVerification: escrowVerification,
        );

        fakeRequests.events.add(cancel);
        fakeRequests.events.add(
          _review(
            signer: MockKeys.guest,
            listing: listing,
            tweakMaterial: ReservationTweakMaterial(
              salt: salt,
              parity: tweakedKey.parity,
            ),
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
  });
}
