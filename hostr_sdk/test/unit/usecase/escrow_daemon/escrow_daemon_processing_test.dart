@Tags(['unit'])
library;

import 'dart:async';
import 'dart:typed_data';

import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/crud.usecase.dart';
import 'package:hostr_sdk/usecase/deterministic_keys/deterministic_keys.dart';
import 'package:hostr_sdk/usecase/escrow/escrow_verification.dart';
import 'package:hostr_sdk/usecase/escrow_daemon/escrow_daemon.dart';
import 'package:hostr_sdk/usecase/escrow_daemon/escrow_daemon_models.dart';
import 'package:hostr_sdk/usecase/evm/capabilities/escrow_capability.dart';
import 'package:hostr_sdk/usecase/evm/chain/evm_chain.dart';
import 'package:hostr_sdk/usecase/evm/config/evm_config.dart';
import 'package:hostr_sdk/usecase/escrows/escrows.dart';
import 'package:hostr_sdk/usecase/evm/evm.dart';
import 'package:hostr_sdk/usecase/listings/listings.dart';
import 'package:hostr_sdk/usecase/messaging/messaging.dart';
import 'package:hostr_sdk/usecase/messaging/thread.dart';
import 'package:hostr_sdk/usecase/messaging/threads.dart';
import 'package:hostr_sdk/usecase/metadata/metadata.dart';
import 'package:hostr_sdk/usecase/requests/requests.dart';
import 'package:hostr_sdk/usecase/orders/orders.dart';
import 'package:hostr_sdk/usecase/user_subscriptions/user_subscriptions.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:http/http.dart' as http;
import 'package:mockito/mockito.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart';
import 'package:ndk/ndk.dart' show Filter, Metadata, Nip01Event;
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';
import 'package:wallet/wallet.dart' as bip;
import 'package:web3dart/web3dart.dart'
    show BlockNum, EthPrivateKey, Web3Client;

final _listingAnchor =
    '30402:${MockKeys.hoster.publicKey}:daemon-processing-listing';

class _SentText {
  final String content;
  final List<List<String>> tags;
  final List<String> recipientPubkeys;

  const _SentText({
    required this.content,
    required this.tags,
    required this.recipientPubkeys,
  });
}

class _FakeAuth extends Fake implements Auth {
  final _FakeDeterministicKeys _hd = _FakeDeterministicKeys();

  @override
  KeyPair? activeKeyPair = MockKeys.escrow;

  @override
  DeterministicKeys get hd => _hd;
}

class _FakeDeterministicKeys extends Fake implements DeterministicKeys {
  final _evmKey = EthPrivateKey.fromHex('1'.padLeft(64, '0'));

  @override
  Future<EthPrivateKey> getActiveEvmKey({int accountIndex = 0}) async =>
      _evmKey;

  @override
  Future<bip.EthereumAddress> getEvmAddress({int accountIndex = 0}) async =>
      _evmKey.address;
}

class _FakeEvm extends Fake implements Evm {
  final _chain = _FakeEvmChain();

  @override
  List<EvmChain> get configuredChains => [_chain];

  @override
  EvmChain getChainForEscrowService(EscrowService service) => _chain;
}

class _FakeEvmChain extends Fake implements EvmChain {
  final _client = Web3Client('http://127.0.0.1:8545', http.Client());

  @override
  EvmChainConfig get config => const EvmChainConfig(
    id: 'regtest',
    chainId: 30,
    rpcUrls: ['http://127.0.0.1:8545'],
    nativeDenomination: 'ETH',
    escrowContractAddress: '0x0000000000000000000000000000000000000001',
  );

  @override
  Web3Client get client => _client;

  @override
  int get clientGeneration => 0;

  @override
  EscrowCapability get escrow =>
      EscrowCapability(chain: this, logger: CustomLogger());

  @override
  Future<Uint8List> getCode(
    bip.EthereumAddress address, {
    BlockNum? atBlock,
  }) async => Uint8List.fromList([1, 2, 3]);
}

class _FakeEscrows extends Fake implements Escrows {
  final upserts = <EscrowService>[];

  @override
  Future<List<EscrowService>> list(Filter f, {String? name}) async => [];

  @override
  Future<UpsertResult<EscrowService>> upsert(
    EscrowService event, {
    NostrEventSigner? signer,
  }) async {
    upserts.add(event);
    return UpsertResult(
      event: event,
      responses: [_successfulBroadcastResponse()],
    );
  }
}

class _FakeUserSubscriptions extends Fake implements UserSubscriptions {}

class _FakeEscrowVerification extends Fake implements EscrowVerification {}

class _FakeListings extends Fake implements Listings {
  @override
  Future<Listing?> getOneByAnchor(String anchor) async => _listing();
}

class _FakeMetadata extends Fake implements MetadataUseCase {
  @override
  Future<ProfileMetadata?> loadMetadata(
    String pubkey, {
    bool forceRefresh = false,
  }) async {
    final displayName = pubkey == MockKeys.hoster.publicKey
        ? 'Host'
        : pubkey == MockKeys.guest.publicKey
        ? 'Guest'
        : pubkey == MockKeys.escrow.publicKey
        ? 'Escrow'
        : null;
    if (displayName == null) return null;
    return ProfileMetadata.fromNostrEvent(
      Metadata(
        pubKey: pubkey,
        name: displayName,
        displayName: displayName,
      ).toEvent(),
    );
  }
}

class _FakeThreads extends Fake implements Threads {
  final _threadController = StreamController<Thread>.broadcast();

  @override
  final Map<String, Thread> threads = {};

  @override
  Stream<Thread> get threadStream => _threadController.stream;

  @override
  Stream<StreamStatus> get status => Stream.value(StreamStatusLive());

  @override
  Future<void> close() => _threadController.close();
}

class _FakeMessaging extends Fake implements Messaging {
  final _FakeThreads fakeThreads;
  final sentTexts = <_SentText>[];
  final recipientRelayLookups = <String>[];
  final recipientRelays = <String, List<String>>{};

  _FakeMessaging(this.fakeThreads);

  @override
  Threads get threads => fakeThreads;

  @override
  Future<List<String>> recipientMessageRelays(String recipientPubkey) async {
    recipientRelayLookups.add(recipientPubkey);
    return recipientRelays[recipientPubkey] ??
        [
          'wss://bootstrap.test',
          'wss://dm-${recipientPubkey.substring(0, 8)}.test',
        ];
  }

  @override
  Future<List<Future<List<RelayBroadcastResponse>>>>
  broadcastTextAllowingExternalRelays({
    required String content,
    required List<List<String>> tags,
    required List<String> recipientPubkeys,
  }) async {
    sentTexts.add(
      _SentText(
        content: content,
        tags: tags,
        recipientPubkeys: recipientPubkeys,
      ),
    );
    return [
      Future.value([_successfulBroadcastResponse()]),
    ];
  }
}

class _BroadcastCall {
  final Nip01Event event;
  final List<String>? relays;

  _BroadcastCall({required this.event, required this.relays});
}

class _FakeRequests extends Fake implements Requests {
  final broadcasts = <Nip01Event>[];
  final broadcastCalls = <_BroadcastCall>[];
  bool failLegacyBroadcasts = false;

  @override
  Future<BroadcastResult> broadcastEvent({
    required Nip01Event event,
    List<String>? relays,
    NostrEventSigner? signer,
  }) async {
    final eventToBroadcast = event.sig == null && signer != null
        ? await signer(event)
        : event;
    broadcasts.add(eventToBroadcast);
    broadcastCalls.add(_BroadcastCall(event: eventToBroadcast, relays: relays));
    if (failLegacyBroadcasts && eventToBroadcast.kind == kNostrKindLegacyDM) {
      throw StateError('legacy broadcast failed');
    }
    return BroadcastResult(
      event: eventToBroadcast,
      responses: [_successfulBroadcastResponse()],
    );
  }
}

RelayBroadcastResponse _successfulBroadcastResponse() {
  return RelayBroadcastResponse(
    relayUrl: 'wss://relay.test',
    okReceived: true,
    broadcastSuccessful: true,
  );
}

class _FakeOrders extends Fake implements Orders {
  final StreamWithStatus<Order> source = StreamWithStatus<Order>();
  final Map<String, List<Order>> _byTradeId = {};
  final confirmed = <Order>[];
  final cancelled = <Order>[];
  final queriedTradeIds = <String>[];
  final Duration queryDelay;

  _FakeOrders({this.queryDelay = Duration.zero});

  void seed(Iterable<Order> orders) {
    for (final order in orders) {
      add(order, emit: false);
    }
  }

  void add(Order order, {bool emit = true}) {
    final tradeId = order.getDtag()!;
    _byTradeId.putIfAbsent(tradeId, () => []);
    _byTradeId[tradeId]!.removeWhere((r) => r.pubKey == order.pubKey);
    _byTradeId[tradeId]!.add(order);
    if (emit) source.add(order);
  }

  @override
  StreamWithStatus<Order> subscribe(Filter f, {String? name}) => source;

  @override
  Future<List<Order>> getByTradeId(String tradeId) async {
    queriedTradeIds.add(tradeId);
    if (queryDelay > Duration.zero) {
      await Future<void>.delayed(queryDelay);
    }
    return [...?_byTradeId[tradeId]];
  }

  @override
  Future<Order> confirm(OrderGroup orderGroup, KeyPair keyPair) async {
    final order = _escrowOrder(
      tradeId: orderGroup.tradeId,
      stage: OrderStage.commit,
      createdAt: orderGroup.orders.length + 1000,
    );
    confirmed.add(order);
    add(order, emit: false);
    return order;
  }

  @override
  Future<Order> cancel(OrderGroup orderGroup, KeyPair keyPair) async {
    final order = _escrowOrder(
      tradeId: orderGroup.tradeId,
      stage: OrderStage.cancel,
      createdAt: orderGroup.orders.length + 2000,
    );
    cancelled.add(order);
    add(order, emit: false);
    return order;
  }

  Future<void> close() => source.close();
}

class _Harness {
  final _FakeThreads threads;
  final _FakeMessaging messaging;
  final _FakeRequests requests;
  final _FakeEscrows escrows;
  final _FakeOrders orders;
  final EscrowDaemon daemon;
  FutureOr<Validation<OrderGroup>> Function(OrderGroup group) verifier;
  final verifiedTradeIds = <String>[];

  _Harness._({
    required this.threads,
    required this.messaging,
    required this.requests,
    required this.escrows,
    required this.orders,
    required this.daemon,
    required this.verifier,
  });

  factory _Harness({
    _FakeOrders? orders,
    FutureOr<Validation<OrderGroup>> Function(OrderGroup group)? verifier,
    DateTime Function()? clock,
  }) {
    final threads = _FakeThreads();
    final messaging = _FakeMessaging(threads);
    messaging.recipientRelays.addAll({
      MockKeys.guest.publicKey: ['wss://bootstrap.test', 'wss://guest.test'],
      MockKeys.hoster.publicKey: ['wss://bootstrap.test', 'wss://host.test'],
    });
    final requests = _FakeRequests();
    final escrows = _FakeEscrows();
    late _Harness harness;
    final fakeOrders = orders ?? _FakeOrders();
    harness = _Harness._(
      threads: threads,
      messaging: messaging,
      requests: requests,
      escrows: escrows,
      orders: fakeOrders,
      verifier: verifier ?? ((group) => Valid(group)),
      daemon: EscrowDaemon(
        auth: _FakeAuth(),
        evm: _FakeEvm(),
        listings: _FakeListings(),
        metadata: _FakeMetadata(),
        messaging: messaging,
        requests: requests,
        escrows: escrows,
        orders: fakeOrders,
        userSubscriptions: _FakeUserSubscriptions(),
        escrowVerification: _FakeEscrowVerification(),
        logger: CustomLogger(),
        clock: clock ?? (() => DateTime.utc(2026, 5, 1)),
        verifyOrderGroup:
            (
              group, {
              required forceValidateSelfSigned,
              required escrowVerification,
            }) async {
              harness.verifiedTradeIds.add(group.tradeId);
              return Future.value(harness.verifier(group));
            },
      ),
    );
    return harness;
  }

  Future<void> close() async {
    await daemon.stop();
    await orders.close();
    await threads.close();
  }
}

Listing _listing() => Listing.create(
  pubKey: MockKeys.hoster.publicKey,
  dTag: 'daemon-processing-listing',
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

EscrowService _escrowService() => EscrowService(
  pubKey: MockKeys.escrow.publicKey,
  tags: EventTags([
    ['d', 'mock-escrow-service-30'],
  ]),
  content: EscrowServiceContent(
    pubkey: MockKeys.escrow.publicKey,
    evmAddress: '0x0000000000000000000000000000000000000002',
    contractAddress: '0x0000000000000000000000000000000000000001',
    contractBytecodeHash: 'mock-bytecode',
    chainId: 30,
    maxDuration: const Duration(days: 30),
    type: EscrowType.EVM,
  ),
);

EscrowMethod _escrowMethod() => EscrowMethod.fromNostrEvent(
  Nip01Event(
    pubKey: MockKeys.hoster.publicKey,
    kind: kNostrKindEscrowMethod,
    tags: [
      ['p', MockKeys.escrow.publicKey],
      ['c', 'mock-bytecode'],
      [kAcceptedPaymentFormTag, 'BTC', Token.native(30).tagId],
    ],
    content: '',
    createdAt: 100,
  ),
);

PaymentProof _paymentProof() => PaymentProof(
  hoster: Metadata(
    pubKey: MockKeys.hoster.publicKey,
    name: 'Host',
    displayName: 'Host',
  ).toEvent(),
  listing: _listing(),
  zapProof: null,
  escrowProof: EscrowProof(
    txHash: '0xabc',
    hostsEscrowMethods: _escrowMethod(),
    escrowService: _escrowService(),
  ),
);

List<PTag> _participants() => [
  PTag.seller(MockKeys.hoster.publicKey),
  PTag.buyer(MockKeys.guest.publicKey),
  PTag.escrow(MockKeys.escrow.publicKey),
];

Order _buyerOrder({
  required String tradeId,
  int createdAt = 100,
  DateTime? start,
  DateTime? end,
}) => Order.create(
  id: '$tradeId-buyer',
  pubKey: MockKeys.guest.publicKey,
  dTag: tradeId,
  listingAnchor: _listingAnchor,
  pTags: _participants(),
  stage: OrderStage.commit,
  start: start ?? DateTime.utc(2026, 6, 1),
  end: end ?? DateTime.utc(2026, 6, 3),
  proof: _paymentProof(),
  createdAt: createdAt,
);

Order _escrowOrder({
  required String tradeId,
  required OrderStage stage,
  int createdAt = 200,
  DateTime? start,
  DateTime? end,
}) => Order.create(
  id: '$tradeId-escrow-${stage.name}-$createdAt',
  pubKey: MockKeys.escrow.publicKey,
  dTag: tradeId,
  listingAnchor: _listingAnchor,
  pTags: _participants(),
  stage: stage,
  start: start ?? DateTime.utc(2026, 6, 1),
  end: end ?? DateTime.utc(2026, 6, 3),
  createdAt: createdAt,
);

Future<void> _waitUntil(bool Function() test, {String? reason}) async {
  for (var i = 0; i < 200; i++) {
    if (test()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail(reason ?? 'Timed out waiting for condition');
}

Iterable<_SentText> _noticesOf(_Harness harness, String noticeType) {
  return harness.messaging.sentTexts.where(
    (message) => message.tags.any(
      (tag) =>
          tag.length >= 2 && tag[0] == 'hostr_notice' && tag[1] == noticeType,
    ),
  );
}

String _recipientPubkey(_BroadcastCall call) {
  return call.event.tags.firstWhere((tag) => tag[0] == 'p')[1];
}

void main() {
  group('EscrowDaemon order processing', () {
    late _Harness harness;

    tearDown(() async {
      await harness.close();
    });

    test('bootstrap does not publish an escrow service', () async {
      harness = _Harness();

      final context = await harness.daemon.bootstrap(
        const EscrowDaemonConfig(),
      );

      expect(
        context.escrowService.contractAddress,
        _escrowService().contractAddress,
      );
      expect(harness.escrows.upserts, isEmpty);
      expect(
        harness.requests.broadcasts.where(
          (event) => EscrowService.kinds.contains(event.kind),
        ),
        isEmpty,
      );
    });

    test(
      'confirms a valid buyer order and notifies buyer and seller',
      () async {
        harness = _Harness();
        final buyer = _buyerOrder(tradeId: 'trade-valid');
        harness.orders.seed([buyer]);

        harness.daemon.startOrderListenerForTesting();
        harness.orders.source.add(buyer);

        await _waitUntil(
          () => harness.orders.confirmed.length == 1,
          reason: 'daemon did not publish escrow confirmation',
        );
        await _waitUntil(
          () => _noticesOf(harness, 'order_placed').length == 2,
          reason: 'daemon did not send order placed notices',
        );

        expect(harness.orders.cancelled, isEmpty);
        expect(harness.verifiedTradeIds, ['trade-valid']);
        final placedNotices = _noticesOf(harness, 'order_placed').toList();
        expect(
          placedNotices.map((notice) => notice.recipientPubkeys.single).toSet(),
          {MockKeys.guest.publicKey, MockKeys.hoster.publicKey},
        );
        expect(
          placedNotices.map((notice) => notice.content),
          everyElement(contains('Lake House 1 Jun - 3 Jun')),
        );
        expect(
          harness.requests.broadcasts.where(
            (e) => e.kind == kNostrKindLegacyDM,
          ),
          hasLength(2),
        );
        final legacyCalls = harness.requests.broadcastCalls
            .where((call) => call.event.kind == kNostrKindLegacyDM)
            .toList();
        expect(legacyCalls.map(_recipientPubkey).toSet(), {
          MockKeys.guest.publicKey,
          MockKeys.hoster.publicKey,
        });
        for (final call in legacyCalls) {
          final recipient = _recipientPubkey(call);
          expect(call.relays, harness.messaging.recipientRelays[recipient]);
        }
      },
    );

    test(
      'adds configured public bootstrap relays only to legacy notices',
      () async {
        harness = _Harness();
        harness.daemon.setLegacyDmBootstrapRelays([
          'wss://relay.primal.net',
          'wss://bootstrap.test',
        ]);
        final buyer = _buyerOrder(tradeId: 'trade-legacy-relays');
        harness.orders.seed([buyer]);

        harness.daemon.startOrderListenerForTesting();
        harness.orders.source.add(buyer);

        await _waitUntil(
          () => _noticesOf(harness, 'order_placed').length == 2,
          reason: 'daemon did not send order placed notices',
        );

        final legacyCalls = harness.requests.broadcastCalls
            .where((call) => call.event.kind == kNostrKindLegacyDM)
            .toList();
        expect(legacyCalls, hasLength(2));
        for (final call in legacyCalls) {
          final recipient = _recipientPubkey(call);
          expect(call.relays, [
            ...harness.messaging.recipientRelays[recipient]!,
            'wss://relay.primal.net',
          ]);
        }
      },
    );

    test('includes years in order notices outside the current year', () async {
      harness = _Harness(clock: () => DateTime.utc(2026, 5, 1));
      final buyer = _buyerOrder(
        tradeId: 'trade-next-year',
        start: DateTime.utc(2027, 4, 30),
        end: DateTime.utc(2027, 5, 2),
      );
      harness.orders.seed([buyer]);

      harness.daemon.startOrderListenerForTesting();
      harness.orders.source.add(buyer);

      await _waitUntil(
        () => _noticesOf(harness, 'order_placed').length == 2,
        reason: 'daemon did not send order placed notices',
      );

      expect(
        _noticesOf(harness, 'order_placed').map((notice) => notice.content),
        everyElement(contains('Lake House 30 Apr 2027 - 2 May 2027')),
      );
    });

    test(
      'does not fail order processing when legacy notice broadcast fails',
      () async {
        harness = _Harness();
        harness.requests.failLegacyBroadcasts = true;
        final buyer = _buyerOrder(tradeId: 'trade-legacy-failure');
        harness.orders.seed([buyer]);

        harness.daemon.startOrderListenerForTesting();
        harness.orders.source.add(buyer);

        await _waitUntil(
          () => harness.orders.confirmed.length == 1,
          reason: 'daemon did not publish escrow confirmation',
        );
        await _waitUntil(
          () => _noticesOf(harness, 'order_placed').length == 2,
          reason: 'daemon did not send modern order notices',
        );

        expect(harness.verifiedTradeIds, ['trade-legacy-failure']);
        expect(
          harness.requests.broadcastCalls.where(
            (call) => call.event.kind == kNostrKindLegacyDM,
          ),
          hasLength(2),
        );
      },
    );

    test(
      'cancels an invalid buyer order and notifies only the buyer',
      () async {
        harness = _Harness(
          verifier: (group) => Invalid(group, 'mock invalid escrow proof'),
        );
        final buyer = _buyerOrder(tradeId: 'trade-invalid');
        harness.orders.seed([buyer]);

        harness.daemon.startOrderListenerForTesting();
        harness.orders.source.add(buyer);

        await _waitUntil(
          () => harness.orders.cancelled.length == 1,
          reason: 'daemon did not publish escrow cancellation',
        );
        await _waitUntil(
          () => _noticesOf(harness, 'order_cancelled').length == 1,
          reason: 'daemon did not send cancellation notice',
        );

        expect(harness.orders.confirmed, isEmpty);
        expect(harness.verifiedTradeIds, ['trade-invalid']);
        expect(_noticesOf(harness, 'order_cancelled').single.recipientPubkeys, [
          MockKeys.guest.publicKey,
        ]);
        expect(_noticesOf(harness, 'order_placed'), isEmpty);
        expect(
          harness.requests.broadcasts.where(
            (e) => e.kind == kNostrKindLegacyDM,
          ),
          hasLength(1),
        );
        final legacyCall = harness.requests.broadcastCalls.singleWhere(
          (call) => call.event.kind == kNostrKindLegacyDM,
        );
        expect(_recipientPubkey(legacyCall), MockKeys.guest.publicKey);
        expect(
          legacyCall.relays,
          harness.messaging.recipientRelays[MockKeys.guest.publicKey],
        );
      },
    );

    test('drains queued startup orders sequentially', () async {
      final orders = _FakeOrders(queryDelay: const Duration(milliseconds: 20));
      harness = _Harness(orders: orders);
      final queued = [
        _buyerOrder(tradeId: 'trade-startup-1', createdAt: 101),
        _buyerOrder(tradeId: 'trade-startup-2', createdAt: 102),
        _buyerOrder(tradeId: 'trade-startup-3', createdAt: 103),
        _buyerOrder(tradeId: 'trade-startup-4', createdAt: 104),
      ];
      orders.seed(queued);
      for (final order in queued) {
        orders.source.add(order);
      }

      harness.daemon.startOrderListenerForTesting();

      await _waitUntil(
        () => orders.confirmed.length == queued.length,
        reason: 'daemon did not drain queued startup orders',
      );

      expect(orders.confirmed.map((order) => order.getDtag()), [
        'trade-startup-1',
        'trade-startup-2',
        'trade-startup-3',
        'trade-startup-4',
      ]);
      expect(_noticesOf(harness, 'order_placed'), hasLength(queued.length * 2));
    });

    test(
      'sends queued startup cancellation notices without re-verifying',
      () async {
        harness = _Harness();
        final buyer = _buyerOrder(tradeId: 'trade-startup-cancel');
        final escrowCancel = _escrowOrder(
          tradeId: 'trade-startup-cancel',
          stage: OrderStage.cancel,
        );
        harness.orders.seed([buyer, escrowCancel]);
        harness.orders.source.add(escrowCancel);

        harness.daemon.startOrderListenerForTesting();

        await _waitUntil(
          () => _noticesOf(harness, 'order_cancelled').length == 1,
          reason: 'daemon did not send queued startup cancellation notice',
        );

        expect(harness.verifiedTradeIds, isEmpty);
        expect(harness.orders.confirmed, isEmpty);
        expect(harness.orders.cancelled, isEmpty);
        expect(_noticesOf(harness, 'order_cancelled').single.recipientPubkeys, [
          MockKeys.guest.publicKey,
        ]);
      },
    );

    test('processes in-flight cancellation after current order work', () async {
      final verificationStarted = Completer<void>();
      final releaseVerification = Completer<void>();
      harness = _Harness(
        verifier: (group) async {
          if (!verificationStarted.isCompleted) {
            verificationStarted.complete();
            await releaseVerification.future;
          }
          return Valid(group);
        },
      );
      final buyer = _buyerOrder(tradeId: 'trade-inflight-cancel');
      harness.orders.seed([buyer]);

      harness.daemon.startOrderListenerForTesting();
      harness.orders.source.add(buyer);
      await verificationStarted.future;

      final escrowCancel = _escrowOrder(
        tradeId: 'trade-inflight-cancel',
        stage: OrderStage.cancel,
        createdAt: 500,
      );
      harness.orders.add(escrowCancel);
      releaseVerification.complete();

      await _waitUntil(
        () => _noticesOf(harness, 'order_cancelled').length == 1,
        reason: 'daemon did not process queued cancellation',
      );

      expect(harness.verifiedTradeIds, ['trade-inflight-cancel']);
      expect(harness.orders.confirmed, isEmpty);
      expect(_noticesOf(harness, 'order_placed'), isEmpty);
      expect(_noticesOf(harness, 'order_cancelled').single.recipientPubkeys, [
        MockKeys.guest.publicKey,
      ]);
    });
  });
}
