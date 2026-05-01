@Tags(['unit'])
library;

import 'dart:async';

import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/escrow/escrow_verification.dart';
import 'package:hostr_sdk/usecase/escrow_daemon/escrow_daemon.dart';
import 'package:hostr_sdk/usecase/escrows/escrows.dart';
import 'package:hostr_sdk/usecase/evm/evm.dart';
import 'package:hostr_sdk/usecase/listings/listings.dart';
import 'package:hostr_sdk/usecase/messaging/messaging.dart';
import 'package:hostr_sdk/usecase/messaging/thread.dart';
import 'package:hostr_sdk/usecase/messaging/threads.dart';
import 'package:hostr_sdk/usecase/metadata/metadata.dart';
import 'package:hostr_sdk/usecase/requests/requests.dart';
import 'package:hostr_sdk/usecase/reservations/reservations.dart';
import 'package:hostr_sdk/usecase/user_subscriptions/user_subscriptions.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:mockito/mockito.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart';
import 'package:ndk/ndk.dart' show Filter, Metadata, Nip01Event;
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

final _listingAnchor =
    '32121:${MockKeys.hoster.publicKey}:daemon-processing-listing';

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
  @override
  KeyPair? activeKeyPair = MockKeys.escrow;
}

class _FakeEvm extends Fake implements Evm {}

class _FakeEscrows extends Fake implements Escrows {}

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

  _FakeMessaging(this.fakeThreads);

  @override
  Threads get threads => fakeThreads;

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
    return const [];
  }
}

class _FakeRequests extends Fake implements Requests {
  final broadcasts = <Nip01Event>[];

  @override
  Future<List<RelayBroadcastResponse>> broadcast({
    required Nip01Event event,
    List<String>? relays,
  }) async {
    broadcasts.add(event);
    return const [];
  }
}

class _FakeReservations extends Fake implements Reservations {
  final StreamWithStatus<Reservation> source = StreamWithStatus<Reservation>();
  final Map<String, List<Reservation>> _byTradeId = {};
  final confirmed = <Reservation>[];
  final cancelled = <Reservation>[];
  final queriedTradeIds = <String>[];
  final Duration queryDelay;

  _FakeReservations({this.queryDelay = Duration.zero});

  void seed(Iterable<Reservation> reservations) {
    for (final reservation in reservations) {
      add(reservation, emit: false);
    }
  }

  void add(Reservation reservation, {bool emit = true}) {
    final tradeId = reservation.getDtag()!;
    _byTradeId.putIfAbsent(tradeId, () => []);
    _byTradeId[tradeId]!.removeWhere((r) => r.pubKey == reservation.pubKey);
    _byTradeId[tradeId]!.add(reservation);
    if (emit) source.add(reservation);
  }

  @override
  StreamWithStatus<Reservation> subscribe(Filter f, {String? name}) => source;

  @override
  Future<List<Reservation>> getByTradeId(String tradeId) async {
    queriedTradeIds.add(tradeId);
    if (queryDelay > Duration.zero) {
      await Future<void>.delayed(queryDelay);
    }
    return [...?_byTradeId[tradeId]];
  }

  @override
  Future<Reservation> confirm(
    ReservationGroup reservationGroup,
    KeyPair keyPair,
  ) async {
    final reservation = _escrowReservation(
      tradeId: reservationGroup.tradeId,
      stage: ReservationStage.commit,
      createdAt: reservationGroup.reservations.length + 1000,
    );
    confirmed.add(reservation);
    add(reservation, emit: false);
    return reservation;
  }

  @override
  Future<Reservation> cancel(
    ReservationGroup reservationGroup,
    KeyPair keyPair,
  ) async {
    final reservation = _escrowReservation(
      tradeId: reservationGroup.tradeId,
      stage: ReservationStage.cancel,
      createdAt: reservationGroup.reservations.length + 2000,
    );
    cancelled.add(reservation);
    add(reservation, emit: false);
    return reservation;
  }

  Future<void> close() => source.close();
}

class _Harness {
  final _FakeThreads threads;
  final _FakeMessaging messaging;
  final _FakeRequests requests;
  final _FakeReservations reservations;
  final EscrowDaemon daemon;
  FutureOr<Validation<ReservationGroup>> Function(ReservationGroup group)
  verifier;
  final verifiedTradeIds = <String>[];

  _Harness._({
    required this.threads,
    required this.messaging,
    required this.requests,
    required this.reservations,
    required this.daemon,
    required this.verifier,
  });

  factory _Harness({
    _FakeReservations? reservations,
    FutureOr<Validation<ReservationGroup>> Function(ReservationGroup group)?
    verifier,
  }) {
    final threads = _FakeThreads();
    final messaging = _FakeMessaging(threads);
    final requests = _FakeRequests();
    late _Harness harness;
    final fakeReservations = reservations ?? _FakeReservations();
    harness = _Harness._(
      threads: threads,
      messaging: messaging,
      requests: requests,
      reservations: fakeReservations,
      verifier: verifier ?? ((group) => Valid(group)),
      daemon: EscrowDaemon(
        auth: _FakeAuth(),
        evm: _FakeEvm(),
        listings: _FakeListings(),
        metadata: _FakeMetadata(),
        messaging: messaging,
        requests: requests,
        escrows: _FakeEscrows(),
        reservations: fakeReservations,
        userSubscriptions: _FakeUserSubscriptions(),
        escrowVerification: _FakeEscrowVerification(),
        logger: CustomLogger(),
        verifyReservationGroup:
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
    await reservations.close();
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
    ['d', '0x0000000000000000000000000000000000000001'],
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
      ['a', 'BTC', Token.native(30).tagId],
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

Reservation _buyerReservation({required String tradeId, int createdAt = 100}) =>
    Reservation.create(
      id: '$tradeId-buyer',
      pubKey: MockKeys.guest.publicKey,
      dTag: tradeId,
      listingAnchor: _listingAnchor,
      pTags: _participants(),
      stage: ReservationStage.commit,
      start: DateTime.utc(2026, 6, 1),
      end: DateTime.utc(2026, 6, 3),
      proof: _paymentProof(),
      createdAt: createdAt,
    );

Reservation _escrowReservation({
  required String tradeId,
  required ReservationStage stage,
  int createdAt = 200,
}) => Reservation.create(
  id: '$tradeId-escrow-${stage.name}-$createdAt',
  pubKey: MockKeys.escrow.publicKey,
  dTag: tradeId,
  listingAnchor: _listingAnchor,
  pTags: _participants(),
  stage: stage,
  start: DateTime.utc(2026, 6, 1),
  end: DateTime.utc(2026, 6, 3),
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

void main() {
  group('EscrowDaemon reservation processing', () {
    late _Harness harness;

    tearDown(() async {
      await harness.close();
    });

    test(
      'confirms a valid buyer reservation and notifies buyer and seller',
      () async {
        harness = _Harness();
        final buyer = _buyerReservation(tradeId: 'trade-valid');
        harness.reservations.seed([buyer]);

        harness.daemon.startReservationListenerForTesting();
        harness.reservations.source.add(buyer);

        await _waitUntil(
          () => harness.reservations.confirmed.length == 1,
          reason: 'daemon did not publish escrow confirmation',
        );
        await _waitUntil(
          () => _noticesOf(harness, 'reservation_placed').length == 2,
          reason: 'daemon did not send reservation placed notices',
        );

        expect(harness.reservations.cancelled, isEmpty);
        expect(harness.verifiedTradeIds, ['trade-valid']);
        expect(
          _noticesOf(
            harness,
            'reservation_placed',
          ).map((notice) => notice.recipientPubkeys.single).toSet(),
          {MockKeys.guest.publicKey, MockKeys.hoster.publicKey},
        );
        expect(
          harness.requests.broadcasts.where(
            (e) => e.kind == kNostrKindLegacyDM,
          ),
          hasLength(2),
        );
      },
    );

    test(
      'cancels an invalid buyer reservation and notifies only the buyer',
      () async {
        harness = _Harness(
          verifier: (group) => Invalid(group, 'mock invalid escrow proof'),
        );
        final buyer = _buyerReservation(tradeId: 'trade-invalid');
        harness.reservations.seed([buyer]);

        harness.daemon.startReservationListenerForTesting();
        harness.reservations.source.add(buyer);

        await _waitUntil(
          () => harness.reservations.cancelled.length == 1,
          reason: 'daemon did not publish escrow cancellation',
        );
        await _waitUntil(
          () => _noticesOf(harness, 'reservation_cancelled').length == 1,
          reason: 'daemon did not send cancellation notice',
        );

        expect(harness.reservations.confirmed, isEmpty);
        expect(harness.verifiedTradeIds, ['trade-invalid']);
        expect(
          _noticesOf(harness, 'reservation_cancelled').single.recipientPubkeys,
          [MockKeys.guest.publicKey],
        );
        expect(_noticesOf(harness, 'reservation_placed'), isEmpty);
        expect(
          harness.requests.broadcasts.where(
            (e) => e.kind == kNostrKindLegacyDM,
          ),
          hasLength(1),
        );
      },
    );

    test('drains queued startup reservations sequentially', () async {
      final reservations = _FakeReservations(
        queryDelay: const Duration(milliseconds: 20),
      );
      harness = _Harness(reservations: reservations);
      final queued = [
        _buyerReservation(tradeId: 'trade-startup-1', createdAt: 101),
        _buyerReservation(tradeId: 'trade-startup-2', createdAt: 102),
        _buyerReservation(tradeId: 'trade-startup-3', createdAt: 103),
        _buyerReservation(tradeId: 'trade-startup-4', createdAt: 104),
      ];
      reservations.seed(queued);
      for (final reservation in queued) {
        reservations.source.add(reservation);
      }

      harness.daemon.startReservationListenerForTesting();

      await _waitUntil(
        () => reservations.confirmed.length == queued.length,
        reason: 'daemon did not drain queued startup reservations',
      );

      expect(
        reservations.confirmed.map((reservation) => reservation.getDtag()),
        [
          'trade-startup-1',
          'trade-startup-2',
          'trade-startup-3',
          'trade-startup-4',
        ],
      );
      expect(
        _noticesOf(harness, 'reservation_placed'),
        hasLength(queued.length * 2),
      );
    });

    test(
      'sends queued startup cancellation notices without re-verifying',
      () async {
        harness = _Harness();
        final buyer = _buyerReservation(tradeId: 'trade-startup-cancel');
        final escrowCancel = _escrowReservation(
          tradeId: 'trade-startup-cancel',
          stage: ReservationStage.cancel,
        );
        harness.reservations.seed([buyer, escrowCancel]);
        harness.reservations.source.add(escrowCancel);

        harness.daemon.startReservationListenerForTesting();

        await _waitUntil(
          () => _noticesOf(harness, 'reservation_cancelled').length == 1,
          reason: 'daemon did not send queued startup cancellation notice',
        );

        expect(harness.verifiedTradeIds, isEmpty);
        expect(harness.reservations.confirmed, isEmpty);
        expect(harness.reservations.cancelled, isEmpty);
        expect(
          _noticesOf(harness, 'reservation_cancelled').single.recipientPubkeys,
          [MockKeys.guest.publicKey],
        );
      },
    );

    test(
      'processes in-flight cancellation after current reservation work',
      () async {
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
        final buyer = _buyerReservation(tradeId: 'trade-inflight-cancel');
        harness.reservations.seed([buyer]);

        harness.daemon.startReservationListenerForTesting();
        harness.reservations.source.add(buyer);
        await verificationStarted.future;

        final escrowCancel = _escrowReservation(
          tradeId: 'trade-inflight-cancel',
          stage: ReservationStage.cancel,
          createdAt: 500,
        );
        harness.reservations.add(escrowCancel);
        releaseVerification.complete();

        await _waitUntil(
          () => _noticesOf(harness, 'reservation_cancelled').length == 1,
          reason: 'daemon did not process queued cancellation',
        );

        expect(harness.verifiedTradeIds, ['trade-inflight-cancel']);
        expect(harness.reservations.confirmed, isEmpty);
        expect(_noticesOf(harness, 'reservation_placed'), isEmpty);
        expect(
          _noticesOf(harness, 'reservation_cancelled').single.recipientPubkeys,
          [MockKeys.guest.publicKey],
        );
      },
    );
  });
}
