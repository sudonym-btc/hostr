@Tags(['unit'])
library;

import 'package:hostr_sdk/seed/seed.dart';
import 'package:hostr_sdk/usecase/requests/requests.dart' as hostr_requests;
import 'package:hostr_sdk/usecase/order_transitions/order_transitions.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:mockito/mockito.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart'
    show RelayBroadcastResponse;
import 'package:ndk/ndk.dart'
    show
        Accounts,
        Bip340EventSigner,
        EventSigner,
        Filter,
        Marketplace,
        MarketplaceOrder,
        MarketplaceOrderStage,
        MarketplaceOrderTransition,
        MarketplaceOrderTransitionContent,
        MarketplaceOrderTransitionPublishResult,
        MarketplaceOrderTransitionType,
        MarketplaceOrderTransitionsUsecase,
        MarketplaceResponse,
        Ndk,
        NdkBroadcastResponse,
        Nip01Event,
        Nip01Utils;
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

// ── Fakes ──────────────────────────────────────────────────────────────

class _FakeAccounts extends Fake implements Accounts {
  int signCalls = 0;

  @override
  String? getPublicKey() => MockKeys.guest.publicKey;

  @override
  Future<Nip01Event> sign(Nip01Event event) async {
    signCalls += 1;
    return Nip01Utils.signWithPrivateKey(
      event: event,
      privateKey: MockKeys.guest.privateKey!,
    );
  }
}

class _FakeNdk extends Fake implements Ndk {
  final _FakeAccounts fakeAccounts = _FakeAccounts();
  late final _FakeMarketplace fakeMarketplace;

  _FakeNdk(_FakeRequests relay) {
    fakeMarketplace = _FakeMarketplace(relay: relay, accounts: fakeAccounts);
  }

  @override
  Accounts get accounts => fakeAccounts;

  @override
  Marketplace get marketplace => fakeMarketplace;
}

class _FakeMarketplace extends Fake implements Marketplace {
  @override
  final MarketplaceOrderTransitionsUsecase orderTransitions;

  _FakeMarketplace({
    required _FakeRequests relay,
    required _FakeAccounts accounts,
  }) : orderTransitions = _FakeMarketplaceOrderTransitions(
         relay: relay,
         accounts: accounts,
       );
}

class _FakeMarketplaceOrderTransitions extends Fake
    implements MarketplaceOrderTransitionsUsecase {
  final _FakeRequests relay;
  final _FakeAccounts accounts;

  _FakeMarketplaceOrderTransitions({
    required this.relay,
    required this.accounts,
  });

  @override
  Future<MarketplaceOrderTransitionPublishResult> record({
    required MarketplaceOrder order,
    required MarketplaceOrderTransitionType transitionType,
    required MarketplaceOrderStage fromStage,
    required MarketplaceOrderStage toStage,
    EventSigner? customSigner,
    Iterable<String>? specificRelays,
    String? commitTermsHash,
    String? reason,
    Map<String, dynamic>? updatedFields,
    String? prevTransitionId,
  }) async {
    final signer =
        customSigner ??
        Bip340EventSigner(
          privateKey: MockKeys.guest.privateKey!,
          publicKey: accounts.getPublicKey()!,
        );
    final transition = MarketplaceOrderTransition.create(
      pubKey: signer.getPublicKey(),
      order: order,
      prevTransitionId: prevTransitionId ?? _previousFor(order, signer),
      content: MarketplaceOrderTransitionContent(
        transitionType: transitionType,
        fromStage: fromStage,
        toStage: toStage,
        commitTermsHash: commitTermsHash ?? order.commitHash(),
        reason: reason,
        updatedFields: updatedFields,
      ),
    );
    final signed = MarketplaceOrderTransition.fromEvent(
      await signer.sign(transition),
    );
    relay.broadcasted.add(signed);
    return MarketplaceOrderTransitionPublishResult(
      transition: signed,
      broadcast: NdkBroadcastResponse(
        publishEvent: signed,
        broadcastDoneStream: Stream.value([_successfulBroadcastResponse()]),
      ),
    );
  }

  @override
  MarketplaceResponse<MarketplaceOrderTransition> queryByTradeId(
    String tradeId, {
    Duration? timeout,
    Iterable<String>? explicitRelays,
    bool cacheRead = true,
    bool cacheWrite = true,
    int? limit,
  }) {
    relay.queries.add(
      Filter(kinds: const [kNostrKindReservationTransition], dTags: [tradeId]),
    );
    return MarketplaceResponse(
      'fake-transitions',
      Stream.fromIterable(
        relay.queryResults.whereType<ReservationTransition>().map(
          MarketplaceOrderTransition.fromEvent,
        ),
      ),
    );
  }

  String? _previousFor(MarketplaceOrder order, EventSigner signer) {
    final tradeId = order.tradeId;
    if (tradeId == null || tradeId.isEmpty) return null;
    MarketplaceOrderTransition? latest;
    for (final event in relay.queryResults.whereType<ReservationTransition>()) {
      if (event.parsedTags.tradeId == tradeId &&
          event.pubKey == signer.getPublicKey()) {
        latest = MarketplaceOrderTransition.fromEvent(event);
      }
    }
    return latest?.id;
  }
}

class _FakeRequests extends Fake implements hostr_requests.Requests {
  final _source = StreamWithStatus<ReservationTransition>();
  final List<Nip01Event> broadcasted = [];
  final List<Nip01Event> queryResults = [];
  final List<Filter> queries = [];
  final List<Filter> subscriptions = [];

  @override
  StreamWithStatus<T> subscribe<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
    String? name,
    bool setSinceOnLiveFilter = true,
  }) {
    subscriptions.add(filter);
    return _source as StreamWithStatus<T>;
  }

  @override
  Stream<T> query<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
    Duration? timeout,
    String? name,
    bool cacheRead = true,
    bool cacheWrite = true,
  }) {
    queries.add(filter);
    return Stream<T>.fromIterable(queryResults.whereType<T>());
  }

  @override
  Future<hostr_requests.BroadcastResult> broadcastEvent({
    required Nip01Event event,
    List<String>? relays,
    hostr_requests.NostrEventSigner? signer,
  }) async {
    var eventToBroadcast = event.sig == null
        ? await (signer?.call(event) ?? Future.value(event))
        : event;
    if (eventToBroadcast.sig != null && eventToBroadcast.id.isEmpty) {
      eventToBroadcast = eventToBroadcast.copyWith(
        id: Nip01Utils.calculateId(eventToBroadcast),
      );
    }
    broadcasted.add(eventToBroadcast);
    return hostr_requests.BroadcastResult(
      event: eventToBroadcast,
      responses: [_successfulBroadcastResponse()],
    );
  }

  void emit(ReservationTransition t) => _source.add(t);
  void emitStatus(StreamStatus s) => _source.addStatus(s);
  Future<void> close() => _source.close();
}

RelayBroadcastResponse _successfulBroadcastResponse() {
  return RelayBroadcastResponse(
    relayUrl: 'wss://relay.test',
    okReceived: true,
    broadcastSuccessful: true,
  );
}

// ── Helpers ────────────────────────────────────────────────────────────

final _f = EntityFactory();
final _testListing = EntityFactory().listing(
  dTag: 'test-listing',
  signer: MockKeys.hoster,
);

Future<Reservation> _makeReservation({
  String dTag = 'trade-1',
  Listing? listing,
  KeyPair? signer,
}) => _f.reservation(
  listing: listing ?? _testListing,
  dTag: dTag,
  signerOverride: signer ?? MockKeys.guest,
  stage: ReservationStage.negotiate,
  start: DateTime(2026, 2, 1),
  end: DateTime(2026, 2, 3),
  createdAt: DateTime(2026, 1, 1).millisecondsSinceEpoch ~/ 1000,
);

// ── Tests ──────────────────────────────────────────────────────────────

void main() {
  late _FakeRequests relay;
  late _FakeNdk ndk;
  late OrderTransitions usecase;

  setUp(() {
    relay = _FakeRequests();
    ndk = _FakeNdk(relay);
    usecase = OrderTransitions(
      requests: relay,
      logger: CustomLogger(),
      ndk: ndk,
    );
  });

  tearDown(() async {
    await relay.close();
  });

  group('OrderTransitions', () {
    group('record()', () {
      test('broadcasts a transition event with correct kind', () async {
        final reservation = await _makeReservation(dTag: 'trade-1');

        final result = await usecase.record(
          reservation: reservation,
          transitionType: ReservationTransitionType.commit,
          fromStage: ReservationStage.negotiate,
          toStage: ReservationStage.commit,
          commitTermsHash: 'hash-abc',
        );

        expect(result, isA<ReservationTransition>());
        expect(result.kind, kNostrKindReservationTransition);
        expect(relay.broadcasted, hasLength(1));
      });

      test(
        'uses provided local signer without asking ndk accounts to sign',
        () async {
          final reservation = await _makeReservation(
            dTag: 'trade-local-signer',
            signer: MockKeys.hoster,
          );

          final result = await usecase.record(
            reservation: reservation,
            transitionType: ReservationTransitionType.cancel,
            fromStage: ReservationStage.commit,
            toStage: ReservationStage.cancel,
            signerKeyPair: MockKeys.hoster,
          );

          expect(ndk.fakeAccounts.signCalls, 0);
          expect(result.pubKey, MockKeys.hoster.publicKey);
          expect(result.valid(), isTrue);
          expect(relay.broadcasted, hasLength(1));
        },
      );

      test('transition content round-trips correctly', () async {
        final reservation = await _makeReservation(dTag: 'trade-2');

        final result = await usecase.record(
          reservation: reservation,
          transitionType: ReservationTransitionType.cancel,
          fromStage: ReservationStage.commit,
          toStage: ReservationStage.cancel,
          reason: 'Changed plans',
        );

        expect(result.transitionType, ReservationTransitionType.cancel);
        expect(result.fromStage, ReservationStage.commit);
        expect(result.toStage, ReservationStage.cancel);
        expect(result.reason, 'Changed plans');
      });

      test('includes d-tag, t-tag, e-tag, listing-ref tags', () async {
        final myListing = _f.listing(
          dTag: 'my-listing',
          signer: MockKeys.hoster,
        );
        final reservation = await _makeReservation(
          dTag: 'trade-3',
          listing: myListing,
        );

        final result = await usecase.record(
          reservation: reservation,
          transitionType: ReservationTransitionType.commit,
          fromStage: ReservationStage.negotiate,
          toStage: ReservationStage.commit,
        );

        expect(result.parsedTags.tradeId, 'trade-3');
        expect(result.parsedTags.getTags('d'), contains('trade-3'));
        expect(result.parsedTags.getTags('t'), contains('trade-3'));
        expect(result.parsedTags.reservationEventId, reservation.id);
        expect(result.parsedTags.listingAnchor, myListing.anchor);
      });

      test('falls back to legacy t-tag when d-tag is missing', () {
        final transition = ReservationTransition.fromNostrEvent(
          Nip01Utils.signWithPrivateKey(
            event: Nip01Event(
              kind: kNostrKindReservationTransition,
              pubKey: MockKeys.guest.publicKey,
              tags: const [
                ['t', 'legacy-trade'],
                ['e', 'reservation-id'],
              ],
              content: ReservationTransitionContent(
                transitionType: ReservationTransitionType.commit,
                fromStage: ReservationStage.negotiate,
                toStage: ReservationStage.commit,
              ).toString(),
            ),
            privateKey: MockKeys.guest.privateKey!,
          ),
        );

        expect(transition.parsedTags.tradeId, 'legacy-trade');
      });

      test('includes prev tag when prevTransitionId is provided', () async {
        final reservation = await _makeReservation(dTag: 'trade-4');

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
        final reservation = await _makeReservation(dTag: 'trade-5');

        final result = await usecase.record(
          reservation: reservation,
          transitionType: ReservationTransitionType.commit,
          fromStage: ReservationStage.negotiate,
          toStage: ReservationStage.commit,
        );

        expect(result.parsedTags.prevTransitionId, isNull);
      });

      test('fills prev tag from existing participant transition', () async {
        final reservation = await _makeReservation(dTag: 'trade-5b');

        final first = await usecase.record(
          reservation: reservation,
          transitionType: ReservationTransitionType.counterOffer,
          fromStage: ReservationStage.negotiate,
          toStage: ReservationStage.negotiate,
        );
        relay.queryResults.add(first);

        final second = await usecase.record(
          reservation: reservation,
          transitionType: ReservationTransitionType.commit,
          fromStage: ReservationStage.negotiate,
          toStage: ReservationStage.commit,
        );

        expect(second.parsedTags.prevTransitionId, first.id);
      });

      test('includes updatedFields for counter-offers', () async {
        final reservation = await _makeReservation(dTag: 'trade-6');
        final updates = {'start': '2026-03-01', 'quantity': 2};

        final result = await usecase.record(
          reservation: reservation,
          transitionType: ReservationTransitionType.counterOffer,
          fromStage: ReservationStage.negotiate,
          toStage: ReservationStage.negotiate,
          updatedFields: updates,
        );

        expect(result.updatedFields, updates);
      });
    });

    group('getForReservation()', () {
      test('queries with correct filter kind and d-tag', () async {
        final result = await usecase.getForReservation('trade-id-abc');
        expect(result, isA<List<ReservationTransition>>());
        expect(relay.queries.single.kinds, ReservationTransition.kinds);
        expect(relay.queries.single.dTags, ['trade-id-abc']);
      });
    });

    group('subscribeForReservation()', () {
      test('returns a StreamWithStatus', () {
        final stream = usecase.subscribeForReservation('trade-id-xyz');
        expect(stream, isA<StreamWithStatus<ReservationTransition>>());
        expect(relay.subscriptions.single.kinds, ReservationTransition.kinds);
        expect(relay.subscriptions.single.dTags, ['trade-id-xyz']);
      });
    });
  });
}
