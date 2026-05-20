@Tags(['unit'])
library;

import 'dart:async';

import 'package:hostr_sdk/seed/seed.dart';
import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/deterministic_keys/deterministic_keys.dart';
import 'package:hostr_sdk/usecase/requests/requests.dart';
import 'package:hostr_sdk/usecase/order_requests/order_requests.dart';
import 'package:hostr_sdk/usecase/order_transitions/order_transitions.dart';
import 'package:hostr_sdk/usecase/orders/orders.dart';
import 'package:hostr_sdk/usecase/trade_account_allocator/trade_account_allocator.dart';
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

class _FakeRequests extends Fake implements Requests {
  _FakeRequests({String? activePubkey, String? signingPrivateKey})
    : _ndk = _FakeNdk(
        activePubkey: activePubkey,
        signingPrivateKey: signingPrivateKey,
      );

  final List<Nip01Event> broadcastedEvents = [];
  final Ndk _ndk;

  @override
  Ndk get ndk => _ndk;

  @override
  Future<BroadcastResult> broadcastEvent({
    required Nip01Event event,
    List<String>? relays,
    NostrEventSigner? signer,
  }) async {
    final eventToBroadcast = event.sig == null && signer != null
        ? await signer(event)
        : event;
    broadcastedEvents.add(eventToBroadcast);
    return BroadcastResult(
      event: eventToBroadcast,
      responses: [_successfulBroadcastResponse()],
    );
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
}

RelayBroadcastResponse _successfulBroadcastResponse() {
  return RelayBroadcastResponse(
    relayUrl: 'wss://relay.test',
    okReceived: true,
    broadcastSuccessful: true,
  );
}

class _FakeAccounts extends Fake implements Accounts {
  _FakeAccounts({this.activePubkey, this.signingPrivateKey});

  final String? activePubkey;
  final String? signingPrivateKey;

  @override
  String? getPublicKey() => activePubkey;

  @override
  Future<Nip01Event> sign(Nip01Event event) async {
    return Nip01Utils.signWithPrivateKey(
      event: event,
      privateKey: signingPrivateKey ?? MockKeys.guest.privateKey!,
    );
  }
}

class _FakeNdk extends Fake implements Ndk {
  _FakeNdk({this.activePubkey, this.signingPrivateKey});

  final String? activePubkey;
  final String? signingPrivateKey;

  @override
  Accounts get accounts => _FakeAccounts(
    activePubkey: activePubkey,
    signingPrivateKey: signingPrivateKey,
  );
}

class _FakeAuth extends Fake implements Auth {
  _FakeAuth(this._activeKeyPair);

  final KeyPair _activeKeyPair;
  final DeterministicKeys _hd = _FakeDeterministicKeys();

  @override
  KeyPair getActiveKey() => _activeKeyPair;

  @override
  DeterministicKeys get hd => _hd;
}

class _FakeDeterministicKeys extends Fake implements DeterministicKeys {
  static final KeyPair _tradeKey = mockKeys[30];

  @override
  Future<String> getTradeId({required int accountIndex}) async =>
      'trade-id-$accountIndex';

  @override
  Future<KeyPair> getTradeKeyPair({required int accountIndex}) async =>
      _tradeKey;
}

class _FakeTradeAccountAllocator extends Fake implements TradeAccountAllocator {
  @override
  Future<int> reserveNextTradeIndex() async => 7;
}

class _FakeOrderTransitions extends Fake implements OrderTransitions {
  int recordCalls = 0;

  @override
  Future<OrderTransition> record({
    required Order order,
    required OrderTransitionType transitionType,
    required OrderStage fromStage,
    required OrderStage toStage,
    KeyPair? signerKeyPair,
    String? commitTermsHash,
    String? reason,
    Map<String, dynamic>? updatedFields,
    String? prevTransitionId,
  }) async {
    recordCalls += 1;
    final unsigned = Nip01Event(
      kind: kNostrKindOrderTransition,
      pubKey: order.pubKey,
      tags: [
        ['d', order.getDtag() ?? ''],
      ],
      content: OrderTransitionContent(
        transitionType: transitionType,
        fromStage: fromStage,
        toStage: toStage,
        commitTermsHash: commitTermsHash,
        reason: reason,
        updatedFields: updatedFields,
      ).toString(),
    );

    return OrderTransition.fromNostrEvent(
      Nip01Utils.signWithPrivateKey(
        event: unsigned,
        privateKey: MockKeys.hoster.privateKey!,
      ),
    );
  }
}

Listing _listing() => _f.listing(
  signer: MockKeys.hoster,
  dTag: 'listing-trade-identity',
  title: 'Trade Identity Test Listing',
  description: 'Listing used for trade identity regression tests',
  images: const ['https://picsum.photos/seed/trade/800/600'],
  priceSats: 100000,
  location: 'test-location',
  type: ListingType.house,
  specifications: Specifications(),
  negotiable: true,
  allowSelfSignedOrder: true,
);

void main() {
  late _FakeRequests requests;
  late _FakeAuth auth;
  late OrderRequests orderRequests;
  late Orders orders;
  late _FakeOrderTransitions transitions;
  late _FakeTradeAccountAllocator tradeAccountAllocator;

  setUp(() {
    requests = _FakeRequests();
    auth = _FakeAuth(MockKeys.guest);
    transitions = _FakeOrderTransitions();
    tradeAccountAllocator = _FakeTradeAccountAllocator();

    orderRequests = OrderRequests(
      requests: requests,
      logger: CustomLogger(),
      auth: auth,
      tradeAccountAllocator: tradeAccountAllocator,
      relays: FakeRelays(),
    );

    orders = Orders(
      requests: requests,
      logger: CustomLogger(),
      messaging: FakeMessaging(),
      auth: auth,
      transitions: transitions,
      listings: FakeListings(),
      relays: FakeRelays(),
    );
  });

  test(
    'counter-offers and self-signed commits preserve the original trade identity',
    () async {
      final listing = _listing();

      final hostProfile = await _f.profile(signer: MockKeys.hoster);

      final initialRequest = await orderRequests.createOrderRequest(
        listing: listing,
        startDate: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 3, 4),
      );

      final hostCounter = await orderRequests.createCounterOffer(
        listing: listing,
        previousRequest: initialRequest,
        amount: DenominatedAmount(
          value: BigInt.from(90000),
          denomination: 'BTC',
          decimals: 8,
        ),
        signerKeyPair: MockKeys.hoster,
      );

      final guestTradeKey = await auth.hd.getTradeKeyPair(accountIndex: 7);

      final commit = await orders.createSelfSigned(
        activeKeyPair: guestTradeKey,
        negotiateOrder: hostCounter,
        proof: _f.zapPaymentProof(hostProfile: hostProfile, listing: listing),
      );

      expect(initialRequest.getDtag(), 'trade-id-7');

      expect(hostCounter.getDtag(), initialRequest.getDtag());
      expect(hostCounter.recipient, initialRequest.recipient);
      expect(
        hostCounter.parsedTags.listingAnchor,
        initialRequest.parsedTags.listingAnchor,
      );
      expect(
        hostCounter.commitAuthorization?.pubKey,
        MockKeys.hoster.publicKey,
      );

      expect(commit.getDtag(), initialRequest.getDtag());
      expect(commit.recipient, initialRequest.recipient);
      expect(
        commit.parsedTags.listingAnchor,
        initialRequest.parsedTags.listingAnchor,
      );
      expect(
        commit.commitAuthorization?.id,
        hostCounter.commitAuthorization?.id,
      );
      expect(commit.pubKey, guestTradeKey.publicKey);

      expect(requests.broadcastedEvents, isNotEmpty);
      expect(requests.broadcastedEvents.last, same(commit));
      expect(transitions.recordCalls, 1);
    },
  );

  test(
    'guest order requests can use deterministic trade keys without a local identity private key',
    () async {
      final listing = _listing();
      final bunkerGuestRequests = _FakeRequests(
        activePubkey: MockKeys.guest.publicKey,
        signingPrivateKey: MockKeys.guest.privateKey,
      );
      final bunkerGuestAuth = _FakeAuth(
        KeyPair.justPublicKey(MockKeys.guest.publicKey),
      );
      final bunkerGuestOrderRequests = OrderRequests(
        requests: bunkerGuestRequests,
        logger: CustomLogger(),
        auth: bunkerGuestAuth,
        tradeAccountAllocator: _FakeTradeAccountAllocator(),
        relays: FakeRelays(),
      );

      final initialRequest = await bunkerGuestOrderRequests.createOrderRequest(
        listing: listing,
        startDate: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 3, 4),
      );

      final expectedTradeKey = await bunkerGuestAuth.hd.getTradeKeyPair(
        accountIndex: 7,
      );

      expect(initialRequest.pubKey, expectedTradeKey.publicKey);
      expect(initialRequest.recipient, expectedTradeKey.publicKey);
      expect(initialRequest.sig, isNotNull);
      expect(initialRequest.valid(), isTrue);
    },
  );

  test(
    'host negotiation events can be signed through the active NDK signer without a local private key',
    () async {
      final listing = _listing();
      final guestRequests = _FakeRequests();
      final guestAuth = _FakeAuth(MockKeys.guest);
      final guestOrderRequests = OrderRequests(
        requests: guestRequests,
        logger: CustomLogger(),
        auth: guestAuth,
        tradeAccountAllocator: _FakeTradeAccountAllocator(),
        relays: FakeRelays(),
      );

      final initialRequest = await guestOrderRequests.createOrderRequest(
        listing: listing,
        startDate: DateTime(2026, 3, 1),
        endDate: DateTime(2026, 3, 4),
      );

      final bunkerHostRequests = _FakeRequests(
        activePubkey: MockKeys.hoster.publicKey,
        signingPrivateKey: MockKeys.hoster.privateKey,
      );
      final bunkerHostAuth = _FakeAuth(
        KeyPair.justPublicKey(MockKeys.hoster.publicKey),
      );
      final bunkerHostOrderRequests = OrderRequests(
        requests: bunkerHostRequests,
        logger: CustomLogger(),
        auth: bunkerHostAuth,
        tradeAccountAllocator: _FakeTradeAccountAllocator(),
        relays: FakeRelays(),
      );

      final hostCounter = await bunkerHostOrderRequests.createCounterOffer(
        listing: listing,
        previousRequest: initialRequest,
        amount: DenominatedAmount(
          value: BigInt.from(90000),
          denomination: 'BTC',
          decimals: 8,
        ),
        signerKeyPair: KeyPair.justPublicKey(MockKeys.hoster.publicKey),
      );

      final cancellation = await bunkerHostOrderRequests.createCancellation(
        previousRequest: hostCounter,
        signerKeyPair: KeyPair.justPublicKey(MockKeys.hoster.publicKey),
      );

      expect(hostCounter.pubKey, MockKeys.hoster.publicKey);
      expect(hostCounter.sig, isNotNull);
      expect(
        hostCounter.commitAuthorization?.pubKey,
        MockKeys.hoster.publicKey,
      );
      expect(cancellation.pubKey, MockKeys.hoster.publicKey);
      expect(cancellation.sig, isNotNull);
      expect(cancellation.stage, OrderStage.cancel);
    },
  );
}
