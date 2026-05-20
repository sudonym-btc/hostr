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
    show Accounts, Filter, Ndk, Nip01Event, Nip01Utils;
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

  @override
  Accounts get accounts => fakeAccounts;
}

class _FakeRequests extends Fake implements hostr_requests.Requests {
  final hostr_requests.NostrEventSigner? defaultSigner;
  final _source = StreamWithStatus<OrderTransition>();
  final List<Nip01Event> broadcasted = [];
  final List<Nip01Event> queryResults = [];
  final List<Filter> queries = [];
  final List<Filter> subscriptions = [];

  _FakeRequests({this.defaultSigner});

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
        ? await ((signer ?? defaultSigner)?.call(event) ?? Future.value(event))
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

  void emit(OrderTransition t) => _source.add(t);
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

Future<Order> _makeOrder({
  String dTag = 'trade-1',
  Listing? listing,
  KeyPair? signer,
}) => _f.order(
  listing: listing ?? _testListing,
  dTag: dTag,
  signerOverride: signer ?? MockKeys.guest,
  stage: OrderStage.negotiate,
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
    ndk = _FakeNdk();
    relay = _FakeRequests(defaultSigner: ndk.fakeAccounts.sign);
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
        final order = await _makeOrder(dTag: 'trade-1');

        final result = await usecase.record(
          order: order,
          transitionType: OrderTransitionType.commit,
          fromStage: OrderStage.negotiate,
          toStage: OrderStage.commit,
          commitTermsHash: 'hash-abc',
        );

        expect(result, isA<OrderTransition>());
        expect(result.kind, kNostrKindOrderTransition);
        expect(relay.broadcasted, hasLength(1));
      });

      test(
        'uses provided local signer without asking ndk accounts to sign',
        () async {
          final order = await _makeOrder(
            dTag: 'trade-local-signer',
            signer: MockKeys.hoster,
          );

          final result = await usecase.record(
            order: order,
            transitionType: OrderTransitionType.cancel,
            fromStage: OrderStage.commit,
            toStage: OrderStage.cancel,
            signerKeyPair: MockKeys.hoster,
          );

          expect(ndk.fakeAccounts.signCalls, 0);
          expect(result.pubKey, MockKeys.hoster.publicKey);
          expect(result.valid(), isTrue);
          expect(relay.broadcasted, hasLength(1));
        },
      );

      test('transition content round-trips correctly', () async {
        final order = await _makeOrder(dTag: 'trade-2');

        final result = await usecase.record(
          order: order,
          transitionType: OrderTransitionType.cancel,
          fromStage: OrderStage.commit,
          toStage: OrderStage.cancel,
          reason: 'Changed plans',
        );

        expect(result.transitionType, OrderTransitionType.cancel);
        expect(result.fromStage, OrderStage.commit);
        expect(result.toStage, OrderStage.cancel);
        expect(result.reason, 'Changed plans');
      });

      test('includes d-tag, t-tag, e-tag, listing-ref tags', () async {
        final myListing = _f.listing(
          dTag: 'my-listing',
          signer: MockKeys.hoster,
        );
        final order = await _makeOrder(dTag: 'trade-3', listing: myListing);

        final result = await usecase.record(
          order: order,
          transitionType: OrderTransitionType.commit,
          fromStage: OrderStage.negotiate,
          toStage: OrderStage.commit,
        );

        expect(result.parsedTags.tradeId, 'trade-3');
        expect(result.parsedTags.getTags('d'), contains('trade-3'));
        expect(result.parsedTags.getTags('t'), contains('trade-3'));
        expect(result.parsedTags.orderEventId, order.id);
        expect(result.parsedTags.listingAnchor, myListing.anchor);
      });

      test('falls back to legacy t-tag when d-tag is missing', () {
        final transition = OrderTransition.fromNostrEvent(
          Nip01Utils.signWithPrivateKey(
            event: Nip01Event(
              kind: kNostrKindOrderTransition,
              pubKey: MockKeys.guest.publicKey,
              tags: const [
                ['t', 'legacy-trade'],
                ['e', 'order-id'],
              ],
              content: OrderTransitionContent(
                transitionType: OrderTransitionType.commit,
                fromStage: OrderStage.negotiate,
                toStage: OrderStage.commit,
              ).toString(),
            ),
            privateKey: MockKeys.guest.privateKey!,
          ),
        );

        expect(transition.parsedTags.tradeId, 'legacy-trade');
      });

      test('includes prev tag when prevTransitionId is provided', () async {
        final order = await _makeOrder(dTag: 'trade-4');

        final result = await usecase.record(
          order: order,
          transitionType: OrderTransitionType.counterOffer,
          fromStage: OrderStage.negotiate,
          toStage: OrderStage.negotiate,
          prevTransitionId: 'prev-event-id',
        );

        expect(result.parsedTags.prevTransitionId, 'prev-event-id');
      });

      test('omits prev tag when prevTransitionId is null', () async {
        final order = await _makeOrder(dTag: 'trade-5');

        final result = await usecase.record(
          order: order,
          transitionType: OrderTransitionType.commit,
          fromStage: OrderStage.negotiate,
          toStage: OrderStage.commit,
        );

        expect(result.parsedTags.prevTransitionId, isNull);
      });

      test('fills prev tag from existing participant transition', () async {
        final order = await _makeOrder(dTag: 'trade-5b');

        final first = await usecase.record(
          order: order,
          transitionType: OrderTransitionType.counterOffer,
          fromStage: OrderStage.negotiate,
          toStage: OrderStage.negotiate,
        );
        relay.queryResults.add(first);

        final second = await usecase.record(
          order: order,
          transitionType: OrderTransitionType.commit,
          fromStage: OrderStage.negotiate,
          toStage: OrderStage.commit,
        );

        expect(second.parsedTags.prevTransitionId, first.id);
      });

      test('includes updatedFields for counter-offers', () async {
        final order = await _makeOrder(dTag: 'trade-6');
        final updates = {'start': '2026-03-01', 'quantity': 2};

        final result = await usecase.record(
          order: order,
          transitionType: OrderTransitionType.counterOffer,
          fromStage: OrderStage.negotiate,
          toStage: OrderStage.negotiate,
          updatedFields: updates,
        );

        expect(result.updatedFields, updates);
      });
    });

    group('getForOrder()', () {
      test('queries with correct filter kind and d-tag', () async {
        final result = await usecase.getForOrder('trade-id-abc');
        expect(result, isA<List<OrderTransition>>());
        expect(relay.queries.single.kinds, OrderTransition.kinds);
        expect(relay.queries.single.dTags, ['trade-id-abc']);
      });
    });

    group('subscribeForOrder()', () {
      test('returns a StreamWithStatus', () {
        final stream = usecase.subscribeForOrder('trade-id-xyz');
        expect(stream, isA<StreamWithStatus<OrderTransition>>());
        expect(relay.subscriptions.single.kinds, OrderTransition.kinds);
        expect(relay.subscriptions.single.dTags, ['trade-id-xyz']);
      });
    });
  });
}
