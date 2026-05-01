/// Unit tests for [Reservations.cancel] and [Reservations.confirm].
///
/// Covers:
/// - cancel() publishes a cancel-stage reservation with correct p-tags
/// - cancel() records a cancel transition
/// - cancel() throws when group is already cancelled
/// - confirm() publishes a commit-stage reservation with correct p-tags
/// - confirm() records a confirm transition
/// - confirm() throws when group is already cancelled
/// - confirm() throws when group is not yet committed
/// - p-tags are preserved from the original group in both cancel and confirm
/// - pre-existing reservation content is copied (not blank) when the caller
///   already has a reservation in the group
@Tags(['unit'])
library;

import 'package:hostr_sdk/seed/seed.dart';
import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/requests/requests.dart';
import 'package:hostr_sdk/usecase/reservation_transitions/reservation_transitions.dart';
import 'package:hostr_sdk/usecase/reservations/reservations.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:mockito/mockito.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/entities.dart' show RelayBroadcastResponse;
import 'package:ndk/ndk.dart'
    show Accounts, Filter, Ndk, Nip01Event, Nip01Utils;
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import '../../../support/fakes.dart';

final _f = EntityFactory();

// ─── Fake Requests ───────────────────────────────────────────────────────────

class _FakeRequests extends Fake implements Requests {
  final List<Nip01Event> broadcastedEvents = [];
  final Ndk _ndk = _FakeNdk();

  @override
  Ndk get ndk => _ndk;

  @override
  Future<List<RelayBroadcastResponse>> broadcast({
    required Nip01Event event,
    List<String>? relays,
  }) async {
    broadcastedEvents.add(event);
    return const <RelayBroadcastResponse>[];
  }

  @override
  Stream<T> query<T extends Nip01Event>({
    required Filter filter,
    Duration? timeout,
    List<String>? relays,
    String? name,
    bool cacheRead = true,
    bool cacheWrite = true,
  }) => const Stream.empty();

  @override
  StreamWithStatus<T> subscribe<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
    String? name,
    bool setSinceOnLiveFilter = true,
  }) => StreamWithStatus<T>();

  @override
  Future<int> count({
    required Filter filter,
    Duration? timeout,
    List<String>? relays,
  }) async => 0;

  @override
  LiveSubscriptionHandle liveSubscription<T extends Nip01Event>({
    required Filter filter,
    required void Function(T p1) onData,
    void Function(Object p1, StackTrace? p2)? onError,
    required String name,
    List<String>? relays,
  }) => throw UnimplementedError();
}

class _FakeAccounts extends Fake implements Accounts {
  @override
  String? getPublicKey() => null;

  @override
  Future<Nip01Event> sign(Nip01Event event) async => event;
}

class _FakeNdk extends Fake implements Ndk {
  final Accounts _accounts = _FakeAccounts();

  @override
  Accounts get accounts => _accounts;
}

// ─── Fake Auth ───────────────────────────────────────────────────────────────

class _FakeAuth extends Fake implements Auth {
  _FakeAuth(this._key);
  final KeyPair _key;

  @override
  KeyPair getActiveKey() => _key;
}

// ─── Fake Transitions ────────────────────────────────────────────────────────

class _RecordingTransitions extends Fake implements ReservationTransitions {
  final List<
    ({
      ReservationTransitionType type,
      ReservationStage from,
      ReservationStage to,
      String? commitTermsHash,
      String? reason,
      KeyPair? signerKeyPair,
    })
  >
  recorded = [];

  @override
  Future<ReservationTransition> record({
    required Reservation reservation,
    required ReservationTransitionType transitionType,
    required ReservationStage fromStage,
    required ReservationStage toStage,
    KeyPair? signerKeyPair,
    String? commitTermsHash,
    String? reason,
    Map<String, dynamic>? updatedFields,
    String? prevTransitionId,
  }) async {
    recorded.add((
      type: transitionType,
      from: fromStage,
      to: toStage,
      commitTermsHash: commitTermsHash,
      reason: reason,
      signerKeyPair: signerKeyPair,
    ));
    final unsigned = Nip01Event(
      kind: kNostrKindReservationTransition,
      pubKey: reservation.pubKey,
      tags: [
        ['d', reservation.getDtag() ?? ''],
      ],
      content: ReservationTransitionContent(
        transitionType: transitionType,
        fromStage: fromStage,
        toStage: toStage,
        commitTermsHash: commitTermsHash,
        reason: reason,
      ).toString(),
    );
    return ReservationTransition.fromNostrEvent(
      Nip01Utils.signWithPrivateKey(
        event: unsigned,
        privateKey: MockKeys.hoster.privateKey!,
      ),
    );
  }
}

// ─── Helpers ─────────────────────────────────────────────────────────────────

/// Build a [ReservationGroup] with a buyer commit and optional seller/escrow.
ReservationGroup _buildCommittedGroup({
  required String tradeId,
  KeyPair? buyerKey,
  bool includeSeller = false,
  bool includeEscrow = false,
  bool includeEscrowReservation = false,
}) {
  final buyer = buyerKey ?? MockKeys.guest;
  final listingAnchor = _f
      .listing(
        signer: MockKeys.hoster,
        dTag: 'listing-$tradeId',
        title: 'Test',
        description: 'desc',
        images: const ['https://example.com/img.jpg'],
        priceSats: 100000,
        location: 'test',
        type: ListingType.house,
        specifications: Specifications(),
      )
      .anchor!;

  final buyerReservation = Reservation.create(
    pubKey: buyer.publicKey,
    dTag: tradeId,
    listingAnchor: listingAnchor,
    stage: ReservationStage.commit,
    pTags: [
      PTag.seller(MockKeys.hoster.publicKey),
      PTag.buyer(buyer.publicKey),
      if (includeEscrow) PTag.escrow(MockKeys.escrow.publicKey),
    ],
  ).signAs(buyer, Reservation.fromNostrEvent);

  var group = const ReservationGroup().addReservation(buyerReservation);

  if (includeSeller) {
    final sellerReservation = Reservation.create(
      pubKey: MockKeys.hoster.publicKey,
      dTag: tradeId,
      listingAnchor: listingAnchor,
      stage: ReservationStage.commit,
      pTags: [
        PTag.seller(MockKeys.hoster.publicKey),
        PTag.buyer(buyer.publicKey),
        if (includeEscrow) PTag.escrow(MockKeys.escrow.publicKey),
      ],
    ).signAs(MockKeys.hoster, Reservation.fromNostrEvent);
    group = group.addReservation(sellerReservation);
  }

  if (includeEscrowReservation) {
    final escrowReservation = Reservation.create(
      pubKey: MockKeys.escrow.publicKey,
      dTag: tradeId,
      listingAnchor: listingAnchor,
      stage: ReservationStage.commit,
      pTags: [
        PTag.seller(MockKeys.hoster.publicKey),
        PTag.buyer(buyer.publicKey),
        PTag.escrow(MockKeys.escrow.publicKey),
      ],
    ).signAs(MockKeys.escrow, Reservation.fromNostrEvent);
    group = group.addReservation(escrowReservation);
  }

  return group;
}

ReservationGroup _buildNegotiateGroup({required String tradeId}) {
  final listingAnchor = _f
      .listing(
        signer: MockKeys.hoster,
        dTag: 'listing-$tradeId',
        title: 'Test',
        description: 'desc',
        images: const ['https://example.com/img.jpg'],
        priceSats: 100000,
        location: 'test',
        type: ListingType.house,
        specifications: Specifications(),
      )
      .anchor!;

  final buyerReservation = Reservation.create(
    pubKey: MockKeys.guest.publicKey,
    dTag: tradeId,
    listingAnchor: listingAnchor,
    stage: ReservationStage.negotiate,
    pTags: [
      PTag.seller(MockKeys.hoster.publicKey),
      PTag.buyer(MockKeys.guest.publicKey),
    ],
  ).signAs(MockKeys.guest, Reservation.fromNostrEvent);

  return const ReservationGroup().addReservation(buyerReservation);
}

// ─── Tests ───────────────────────────────────────────────────────────────────

void main() {
  late _FakeRequests requests;
  late _RecordingTransitions transitions;
  late Reservations reservations;

  setUp(() {
    requests = _FakeRequests();
    transitions = _RecordingTransitions();
    reservations = Reservations(
      requests: requests as dynamic,
      logger: CustomLogger(),
      messaging: FakeMessaging(),
      auth: _FakeAuth(MockKeys.hoster),
      transitions: transitions,
      listings: FakeListings(),
      relays: FakeRelays(),
    );
  });

  // ── cancel() ────────────────────────────────────────────────────────────────

  group('Reservations.cancel()', () {
    test('broadcasts a cancel-stage reservation', () async {
      final group = _buildCommittedGroup(tradeId: 'trade-cancel-1');

      await reservations.cancel(group, MockKeys.hoster);

      expect(requests.broadcastedEvents, hasLength(1));
      final published = Reservation.fromNostrEvent(
        requests.broadcastedEvents.first,
      );
      expect(published.stage, ReservationStage.cancel);
    });

    test(
      'preserves the tradeId (d-tag) in the published reservation',
      () async {
        const tradeId = 'trade-cancel-dtag';
        final group = _buildCommittedGroup(tradeId: tradeId);

        await reservations.cancel(group, MockKeys.hoster);

        final published = Reservation.fromNostrEvent(
          requests.broadcastedEvents.first,
        );
        expect(published.getDtag(), tradeId);
      },
    );

    test(
      'preserves all p-tags (seller, buyer, escrow) from the group',
      () async {
        final group = _buildCommittedGroup(
          tradeId: 'trade-cancel-ptags',
          includeEscrow: true,
        );

        await reservations.cancel(group, MockKeys.hoster);

        final published = Reservation.fromNostrEvent(
          requests.broadcastedEvents.first,
        );
        expect(
          published.parsedTags.getTagValueByMarker('p', 'seller'),
          MockKeys.hoster.publicKey,
        );
        expect(
          published.parsedTags.getTagValueByMarker('p', 'buyer'),
          MockKeys.guest.publicKey,
        );
        expect(
          published.parsedTags.getTagValueByMarker('p', 'escrow'),
          MockKeys.escrow.publicKey,
        );
      },
    );

    test(
      'records a cancel transition (fromStage=commit, toStage=cancel)',
      () async {
        final group = _buildCommittedGroup(tradeId: 'trade-cancel-trans');

        await reservations.cancel(group, MockKeys.hoster);

        expect(transitions.recorded, hasLength(1));
        final t = transitions.recorded.first;
        expect(t.type, ReservationTransitionType.cancel);
        expect(t.to, ReservationStage.cancel);
      },
    );

    test(
      'passes the cancellation signer through to the transition recorder',
      () async {
        final group = _buildCommittedGroup(tradeId: 'trade-cancel-signer');

        await reservations.cancel(group, MockKeys.hoster);

        expect(transitions.recorded, hasLength(1));
        expect(transitions.recorded.first.signerKeyPair, MockKeys.hoster);
      },
    );

    test('also records cancel from negotiate stage', () async {
      final group = _buildNegotiateGroup(tradeId: 'trade-cancel-neg');

      await reservations.cancel(group, MockKeys.guest);

      expect(transitions.recorded, hasLength(1));
      final t = transitions.recorded.first;
      expect(t.type, ReservationTransitionType.cancel);
      expect(t.from, ReservationStage.negotiate);
      expect(t.to, ReservationStage.cancel);
    });

    test('throws if group is already cancelled', () async {
      final group = _buildCommittedGroup(tradeId: 'trade-cancel-dup');
      // First cancel.
      await reservations.cancel(group, MockKeys.hoster);

      // Build a new group that already has the cancel reservation.
      final cancelledGroup = group.addReservation(
        Reservation.fromNostrEvent(requests.broadcastedEvents.first),
      );

      expect(
        () => reservations.cancel(cancelledGroup, MockKeys.hoster),
        throwsA(isA<Exception>()),
      );
    });

    test('sets the published reservation pubkey to the signer', () async {
      final group = _buildCommittedGroup(tradeId: 'trade-cancel-signer');

      await reservations.cancel(group, MockKeys.hoster);

      final published = Reservation.fromNostrEvent(
        requests.broadcastedEvents.first,
      );
      expect(published.pubKey, MockKeys.hoster.publicKey);
    });

    test(
      'replacements use a newer created_at than the existing signer event',
      () async {
        final group = _buildCommittedGroup(
          tradeId: 'trade-cancel-replacement-time',
          includeSeller: true,
        );
        final existing = group.sellerReservation!;

        await reservations.cancel(group, MockKeys.hoster);

        final published = Reservation.fromNostrEvent(
          requests.broadcastedEvents.first,
        );
        expect(published.createdAt, greaterThan(existing.createdAt));
      },
    );
  });

  // ── confirm() ───────────────────────────────────────────────────────────────

  group('Reservations.confirm()', () {
    test('broadcasts a commit-stage reservation', () async {
      final group = _buildCommittedGroup(tradeId: 'trade-confirm-1');

      await reservations.confirm(group, MockKeys.escrow);

      expect(requests.broadcastedEvents, hasLength(1));
      final published = Reservation.fromNostrEvent(
        requests.broadcastedEvents.first,
      );
      expect(published.stage, ReservationStage.commit);
    });

    test(
      'preserves the tradeId (d-tag) in the published reservation',
      () async {
        const tradeId = 'trade-confirm-dtag';
        final group = _buildCommittedGroup(tradeId: tradeId);

        await reservations.confirm(group, MockKeys.escrow);

        final published = Reservation.fromNostrEvent(
          requests.broadcastedEvents.first,
        );
        expect(published.getDtag(), tradeId);
      },
    );

    test(
      'preserves all p-tags (seller, buyer, escrow) from the group',
      () async {
        final group = _buildCommittedGroup(
          tradeId: 'trade-confirm-ptags',
          includeEscrow: true,
        );

        await reservations.confirm(group, MockKeys.escrow);

        final published = Reservation.fromNostrEvent(
          requests.broadcastedEvents.first,
        );
        expect(
          published.parsedTags.getTagValueByMarker('p', 'seller'),
          MockKeys.hoster.publicKey,
        );
        expect(
          published.parsedTags.getTagValueByMarker('p', 'buyer'),
          MockKeys.guest.publicKey,
        );
        expect(
          published.parsedTags.getTagValueByMarker('p', 'escrow'),
          MockKeys.escrow.publicKey,
        );
      },
    );

    test(
      'records a confirm transition (fromStage=commit, toStage=commit, type=confirm)',
      () async {
        final group = _buildCommittedGroup(tradeId: 'trade-confirm-trans');

        await reservations.confirm(group, MockKeys.escrow);

        expect(transitions.recorded, hasLength(1));
        final t = transitions.recorded.first;
        expect(t.type, ReservationTransitionType.confirm);
        expect(t.from, ReservationStage.commit);
        expect(t.to, ReservationStage.commit);
      },
    );

    test('sets the published reservation pubkey to the signer', () async {
      final group = _buildCommittedGroup(tradeId: 'trade-confirm-signer');

      await reservations.confirm(group, MockKeys.escrow);

      final published = Reservation.fromNostrEvent(
        requests.broadcastedEvents.first,
      );
      expect(published.pubKey, MockKeys.escrow.publicKey);
    });

    test(
      'replacements use a newer created_at than the existing signer event',
      () async {
        final group = _buildCommittedGroup(
          tradeId: 'trade-confirm-replacement-time',
          includeEscrow: true,
          includeEscrowReservation: true,
        );
        final existing = group.escrowReservation!;

        await reservations.confirm(group, MockKeys.escrow);

        final published = Reservation.fromNostrEvent(
          requests.broadcastedEvents.first,
        );
        expect(published.createdAt, greaterThan(existing.createdAt));
      },
    );

    test('throws if group is already cancelled', () async {
      final group = _buildCommittedGroup(tradeId: 'trade-confirm-cancel');
      // Add a cancel reservation to make it cancelled.
      final cancelReservation = Reservation.create(
        pubKey: MockKeys.hoster.publicKey,
        dTag: 'trade-confirm-cancel',
        listingAnchor: group.listingAnchor,
        stage: ReservationStage.cancel,
        pTags: [
          PTag.seller(MockKeys.hoster.publicKey),
          PTag.buyer(MockKeys.guest.publicKey),
        ],
      ).signAs(MockKeys.hoster, Reservation.fromNostrEvent);
      final cancelledGroup = group.addReservation(cancelReservation);

      expect(
        () => reservations.confirm(cancelledGroup, MockKeys.escrow),
        throwsA(isA<Exception>()),
      );
    });

    test('throws if group is not yet committed (still negotiate)', () async {
      final group = _buildNegotiateGroup(tradeId: 'trade-confirm-neg');

      expect(
        () => reservations.confirm(group, MockKeys.escrow),
        throwsA(isA<Exception>()),
      );
    });

    test(
      'p-tags for cancel and confirm are identical for the same group',
      () async {
        final group = _buildCommittedGroup(
          tradeId: 'trade-ptags-compare',
          includeEscrow: true,
        );

        // Confirm
        await reservations.confirm(group, MockKeys.escrow);
        final confirmPublished = Reservation.fromNostrEvent(
          requests.broadcastedEvents.first,
        );

        requests.broadcastedEvents.clear();
        transitions.recorded.clear();

        // Re-create a fresh committed group
        final group2 = _buildCommittedGroup(
          tradeId: 'trade-ptags-compare2',
          includeEscrow: true,
        );

        // Cancel
        await reservations.cancel(group2, MockKeys.escrow);
        final cancelPublished = Reservation.fromNostrEvent(
          requests.broadcastedEvents.first,
        );

        // Both should have the same p-tag structure
        expect(
          confirmPublished.parsedTags.getTagValueByMarker('p', 'seller'),
          cancelPublished.parsedTags.getTagValueByMarker('p', 'seller'),
        );
        expect(
          confirmPublished.parsedTags.getTagValueByMarker('p', 'buyer'),
          cancelPublished.parsedTags.getTagValueByMarker('p', 'buyer'),
        );
        expect(
          confirmPublished.parsedTags.getTagValueByMarker('p', 'escrow'),
          cancelPublished.parsedTags.getTagValueByMarker('p', 'escrow'),
        );
      },
    );
  });
}
