@Tags(['unit'])
library;

import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart';
import 'package:hostr_sdk/usecase/listings/listings.dart';
import 'package:hostr_sdk/usecase/messaging/thread/state.dart';
import 'package:hostr_sdk/usecase/messaging/thread/thread.dart';
import 'package:hostr_sdk/usecase/messaging/threads.dart';
import 'package:hostr_sdk/usecase/metadata/metadata.dart';
import 'package:hostr_sdk/usecase/requests/expandable_subscription.dart';
import 'package:hostr_sdk/usecase/reservations/reservations.dart';
import 'package:hostr_sdk/usecase/trades/payment_proof_orchestrator.dart';
import 'package:hostr_sdk/usecase/user_subscriptions/user_subscriptions.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:mockito/mockito.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:rxdart/rxdart.dart';
import 'package:test/test.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;

class _FakeAuth extends Fake implements Auth {
  @override
  KeyPair? activeKeyPair = MockKeys.guest;

  @override
  KeyPair getActiveKey() => activeKeyPair!;
}

class _FakeExpandableSubscription<T extends Event> extends Fake
    implements ExpandableSubscription<T> {
  @override
  final StreamWithStatus<T> stream = StreamWithStatus<T>();
}

class _FakeUserSubscriptions extends Fake implements UserSubscriptions {
  final _reservations = _FakeExpandableSubscription<Reservation>();

  @override
  ExpandableSubscription<Reservation> get allMyReservations$ => _reservations;

  @override
  final StreamWithStatus<PaymentEvent> paymentEvents$ =
      StreamWithStatus<PaymentEvent>();
}

class _FakeThread extends Fake implements Thread {
  @override
  final String anchor;

  @override
  final BehaviorSubject<ThreadState> state;

  _FakeThread({required this.anchor, required ThreadState state})
    : state = BehaviorSubject<ThreadState>.seeded(state);
}

class _FakeThreads extends Fake implements Threads {
  @override
  final Map<String, Thread> threads;

  _FakeThreads(this.threads);
}

class _FakeReservations extends Fake implements Reservations {
  final List<Reservation> queriedReservations;
  final Duration getByTradeIdDelay;
  int getByTradeIdCount = 0;
  int createSelfSignedCount = 0;
  int activeGetByTradeIdCount = 0;
  int maxActiveGetByTradeIdCount = 0;
  final List<String> queriedTradeIds = [];

  _FakeReservations(
    this.queriedReservations, {
    this.getByTradeIdDelay = Duration.zero,
  });

  @override
  Future<List<Reservation>> getByTradeId(String tradeId) async {
    getByTradeIdCount++;
    queriedTradeIds.add(tradeId);
    activeGetByTradeIdCount++;
    if (activeGetByTradeIdCount > maxActiveGetByTradeIdCount) {
      maxActiveGetByTradeIdCount = activeGetByTradeIdCount;
    }
    try {
      if (getByTradeIdDelay > Duration.zero) {
        await Future<void>.delayed(getByTradeIdDelay);
      }
      return queriedReservations
          .where((reservation) => reservation.getDtag() == tradeId)
          .toList();
    } finally {
      activeGetByTradeIdCount--;
    }
  }

  @override
  Future<Reservation> createSelfSigned({
    required KeyPair activeKeyPair,
    required Reservation negotiateReservation,
    required PaymentProof proof,
  }) async {
    createSelfSignedCount++;
    return negotiateReservation;
  }
}

class _FakeListings extends Fake implements Listings {}

class _FakeMetadataUseCase extends Fake implements MetadataUseCase {}

Reservation _reservation({
  required String tradeId,
  required String listingAnchor,
  required String pubkey,
  required ReservationStage stage,
  int createdAt = 100,
}) {
  return Reservation.create(
    id: '$tradeId-$pubkey-${stage.name}',
    pubKey: pubkey,
    dTag: tradeId,
    listingAnchor: listingAnchor,
    start: DateTime.utc(2026, 1, 1),
    end: DateTime.utc(2026, 1, 2),
    stage: stage,
    pTags: [
      PTag.seller(MockKeys.hoster.publicKey),
      PTag.buyer(MockKeys.guest.publicKey),
    ],
    createdAt: createdAt,
  );
}

Message _reservationMessage({
  required String tradeId,
  required Reservation reservation,
}) {
  return Message(
    id: 'message-$tradeId',
    pubKey: MockKeys.guest.publicKey,
    child: reservation,
    createdAt: reservation.createdAt,
    tags: MessageTags([
      ['p', MockKeys.hoster.publicKey],
      [kConversationTag, tradeId],
    ]),
  );
}

EscrowFundedEvent _fundedEvent(String tradeId) {
  return EscrowFundedEvent(
    tradeId: tradeId,
    transactionHash: '0xabc',
    blockNum: 1,
    block: null,
    chainId: 30,
    contractAddress: '0x0000000000000000000000000000000000000001',
    transactionIndex: 0,
    logIndex: 0,
    amount: TokenAmount(value: BigInt.one, token: Token.native(30)),
    unlockAt: 0,
    buyer: EthereumAddress.fromHex(
      '0x000000000000000000000000000000000000b0b0',
    ),
    seller: EthereumAddress.fromHex(
      '0x000000000000000000000000000000000000cafe',
    ),
    arbiter: EthereumAddress.fromHex(
      '0x000000000000000000000000000000000000bEEF',
    ),
    tokenAddress: EthereumAddress.fromHex(
      '0x0000000000000000000000000000000000000000',
    ),
    escrowFee: TokenAmount(value: BigInt.zero, token: Token.native(30)),
  );
}

Thread _threadFor({required String tradeId, required Reservation negotiate}) {
  return _FakeThread(
    anchor: 'thread-$tradeId',
    state: ThreadState(
      ourPubkey: MockKeys.guest.publicKey,
      anchor: 'thread-$tradeId',
      events: [_reservationMessage(tradeId: tradeId, reservation: negotiate)],
      counterpartyPubkeys: [MockKeys.hoster.publicKey],
      participantPubkeys: [MockKeys.guest.publicKey, MockKeys.hoster.publicKey],
    ),
  );
}

Future<void> _waitUntil(bool Function() test) async {
  for (var i = 0; i < 100; i++) {
    if (test()) return;
    await Future<void>.delayed(const Duration(milliseconds: 10));
  }
  fail('Timed out waiting for condition');
}

void main() {
  test(
    'does not republish self-signed reservation found by one-off trade query '
    'after restart',
    () async {
      const tradeId = 'trade-already-booked';
      final listingAnchor = '30402:${MockKeys.hoster.publicKey}:listing';
      final negotiate = _reservation(
        tradeId: tradeId,
        listingAnchor: listingAnchor,
        pubkey: MockKeys.guest.publicKey,
        stage: ReservationStage.negotiate,
      );
      final existingCommit = _reservation(
        tradeId: tradeId,
        listingAnchor: listingAnchor,
        pubkey: MockKeys.guest.publicKey,
        stage: ReservationStage.commit,
        createdAt: 200,
      );
      final thread = _threadFor(tradeId: tradeId, negotiate: negotiate);
      final userSubscriptions = _FakeUserSubscriptions()
        ..paymentEvents$.add(_fundedEvent(tradeId));
      final reservations = _FakeReservations([existingCommit]);
      final orchestrator = PaymentProofOrchestrator(
        userSubs: userSubscriptions,
        threads: _FakeThreads({'thread-$tradeId': thread}),
        auth: _FakeAuth(),
        reservations: reservations,
        listings: _FakeListings(),
        metadata: _FakeMetadataUseCase(),
        logger: CustomLogger(),
      );

      await orchestrator.start();
      await _waitUntil(() => reservations.getByTradeIdCount == 1);
      await orchestrator.reset();
      await orchestrator.start();
      await _waitUntil(() => reservations.getByTradeIdCount == 2);

      expect(reservations.getByTradeIdCount, 2);
      expect(reservations.createSelfSignedCount, 0);

      await orchestrator.dispose();
      await thread.state.close();
      await userSubscriptions._reservations.stream.close();
      await userSubscriptions.paymentEvents$.close();
    },
  );

  test('processes replayed payment events one at a time', () async {
    const tradeIds = ['trade-1', 'trade-2', 'trade-3'];
    final listingAnchor = '30402:${MockKeys.hoster.publicKey}:listing';

    final threads = <String, Thread>{};
    final existingCommits = <Reservation>[];
    for (final tradeId in tradeIds) {
      final negotiate = _reservation(
        tradeId: tradeId,
        listingAnchor: listingAnchor,
        pubkey: MockKeys.guest.publicKey,
        stage: ReservationStage.negotiate,
      );
      threads['thread-$tradeId'] = _threadFor(
        tradeId: tradeId,
        negotiate: negotiate,
      );
      existingCommits.add(
        _reservation(
          tradeId: tradeId,
          listingAnchor: listingAnchor,
          pubkey: MockKeys.guest.publicKey,
          stage: ReservationStage.commit,
          createdAt: 200,
        ),
      );
    }

    final userSubscriptions = _FakeUserSubscriptions();
    for (final tradeId in tradeIds) {
      userSubscriptions.paymentEvents$.add(_fundedEvent(tradeId));
    }

    final reservations = _FakeReservations(
      existingCommits,
      getByTradeIdDelay: const Duration(milliseconds: 25),
    );
    final orchestrator = PaymentProofOrchestrator(
      userSubs: userSubscriptions,
      threads: _FakeThreads(threads),
      auth: _FakeAuth(),
      reservations: reservations,
      listings: _FakeListings(),
      metadata: _FakeMetadataUseCase(),
      logger: CustomLogger(),
    );

    await orchestrator.start();
    await _waitUntil(() => reservations.getByTradeIdCount == tradeIds.length);

    expect(reservations.maxActiveGetByTradeIdCount, 1);
    expect(reservations.queriedTradeIds, tradeIds);
    expect(reservations.createSelfSignedCount, 0);

    await orchestrator.dispose();
    for (final thread in threads.values) {
      await thread.state.close();
    }
    await userSubscriptions._reservations.stream.close();
    await userSubscriptions.paymentEvents$.close();
  });
}
