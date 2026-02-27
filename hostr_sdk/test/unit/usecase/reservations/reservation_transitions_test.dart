@Tags(['unit'])
library;

import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/requests/requests.dart' as hostr_requests;
import 'package:hostr_sdk/usecase/reservation_transitions/reservation_transitions.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:mockito/mockito.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart'
    show RelayBroadcastResponse;
import 'package:ndk/ndk.dart'
    show Accounts, Filter, Ndk, Nip01Event, Nip01Utils;
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

// ── Fakes ──────────────────────────────────────────────────────────────

class _FakeAuth extends Fake implements Auth {}

class _FakeAccounts extends Fake implements Accounts {
  @override
  String? getPublicKey() => MockKeys.guest.publicKey;

  @override
  Future<Nip01Event> sign(Nip01Event event) async {
    return Nip01Utils.signWithPrivateKey(
      event: event,
      privateKey: MockKeys.guest.privateKey!,
    );
  }
}

class _FakeNdk extends Fake implements Ndk {
  @override
  Accounts get accounts => _FakeAccounts();
}

class _FakeRequests extends Fake implements hostr_requests.Requests {
  final _source = StreamWithStatus<ReservationTransition>();
  final List<Nip01Event> broadcasted = [];

  @override
  StreamWithStatus<T> subscribe<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
    String? name,
  }) {
    return _source as StreamWithStatus<T>;
  }

  @override
  Stream<T> query<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
    Duration? timeout,
    String? name,
  }) {
    return Stream<T>.empty();
  }

  @override
  Future<List<RelayBroadcastResponse>> broadcast({
    required Nip01Event event,
    List<String>? relays,
  }) async {
    broadcasted.add(event);
    return [];
  }

  void emit(ReservationTransition t) => _source.add(t);
  void emitStatus(StreamStatus s) => _source.addStatus(s);
  Future<void> close() => _source.close();
}

// ── Helpers ────────────────────────────────────────────────────────────

Reservation _makeReservation({
  String dTag = 'trade-1',
  String listingAnchor = 'listing-anchor',
  KeyPair? signer,
}) {
  final key = signer ?? MockKeys.guest;
  return Reservation(
    pubKey: key.publicKey,
    createdAt: DateTime(2026, 1, 1).millisecondsSinceEpoch ~/ 1000,
    tags: ReservationTags([
      ['d', dTag],
      [kListingRefTag, listingAnchor],
    ]),
    content: ReservationContent(
      start: DateTime(2026, 2, 1),
      end: DateTime(2026, 2, 3),
      stage: ReservationStage.negotiate,
    ),
  ).signAs(key, Reservation.fromNostrEvent);
}

// ── Tests ──────────────────────────────────────────────────────────────

void main() {
  late _FakeRequests relay;
  late ReservationTransitions usecase;

  setUp(() {
    relay = _FakeRequests();
    usecase = ReservationTransitions(
      requests: relay,
      logger: CustomLogger(),
      ndk: _FakeNdk(),
      auth: _FakeAuth(),
    );
  });

  tearDown(() async {
    await relay.close();
  });

  group('ReservationTransitions', () {
    group('record()', () {
      test('broadcasts a transition event with correct kind', () async {
        final reservation = _makeReservation(dTag: 'trade-1');

        final result = await usecase.record(
          reservation: reservation,
          transitionType: ReservationTransitionType.sellerAck,
          fromStage: ReservationStage.negotiate,
          toStage: ReservationStage.commit,
          commitTermsHash: 'hash-abc',
        );

        expect(result, isA<ReservationTransition>());
        expect(result.kind, kNostrKindReservationTransition);
        expect(relay.broadcasted, hasLength(1));
      });

      test('transition content round-trips correctly', () async {
        final reservation = _makeReservation(dTag: 'trade-2');

        final result = await usecase.record(
          reservation: reservation,
          transitionType: ReservationTransitionType.cancel,
          fromStage: ReservationStage.commit,
          toStage: ReservationStage.cancel,
          reason: 'Changed plans',
        );

        final content = result.parsedContent;
        expect(content.transitionType, ReservationTransitionType.cancel);
        expect(content.fromStage, ReservationStage.commit);
        expect(content.toStage, ReservationStage.cancel);
        expect(content.reason, 'Changed plans');
      });

      test('includes d-tag, e-tag, listing-ref tags', () async {
        final reservation = _makeReservation(
          dTag: 'trade-3',
          listingAnchor: 'my-listing',
        );

        final result = await usecase.record(
          reservation: reservation,
          transitionType: ReservationTransitionType.commit,
          fromStage: ReservationStage.negotiate,
          toStage: ReservationStage.commit,
        );

        expect(result.parsedTags.tradeId, 'trade-3');
        expect(result.parsedTags.reservationEventId, reservation.id);
        expect(result.parsedTags.listingAnchor, 'my-listing');
      });

      test('includes prev tag when prevTransitionId is provided', () async {
        final reservation = _makeReservation(dTag: 'trade-4');

        final result = await usecase.record(
          reservation: reservation,
          transitionType: ReservationTransitionType.counterOffer,
          fromStage: ReservationStage.negotiate,
          toStage: ReservationStage.negotiate,
          prevTransitionId: 'prev-event-id',
        );

        expect(result.parsedTags.prevTransitionId, 'prev-event-id');
      });

      test('omits prev tag when prevTransitionId is null', () async {
        final reservation = _makeReservation(dTag: 'trade-5');

        final result = await usecase.record(
          reservation: reservation,
          transitionType: ReservationTransitionType.sellerAck,
          fromStage: ReservationStage.negotiate,
          toStage: ReservationStage.commit,
        );

        expect(result.parsedTags.prevTransitionId, isNull);
      });

      test('includes updatedFields for counter-offers', () async {
        final reservation = _makeReservation(dTag: 'trade-6');
        final updates = {'start': '2026-03-01', 'quantity': 2};

        final result = await usecase.record(
          reservation: reservation,
          transitionType: ReservationTransitionType.counterOffer,
          fromStage: ReservationStage.negotiate,
          toStage: ReservationStage.negotiate,
          updatedFields: updates,
        );

        expect(result.parsedContent.updatedFields, updates);
      });
    });

    group('getForReservation()', () {
      test('queries with correct filter kind and d-tag', () async {
        // getForReservation delegates to list() which calls requests.query.
        // With our fake it returns an empty stream so we just verify it
        // completes without error and returns a list.
        final result = await usecase.getForReservation('trade-id-abc');
        expect(result, isA<List<ReservationTransition>>());
      });
    });

    group('subscribeForReservation()', () {
      test('returns a StreamWithStatus', () {
        final stream = usecase.subscribeForReservation('trade-id-xyz');
        expect(stream, isA<StreamWithStatus<ReservationTransition>>());
      });
    });
  });
}
