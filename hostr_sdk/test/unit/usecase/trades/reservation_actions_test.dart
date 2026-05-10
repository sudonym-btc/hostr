@Tags(['unit'])
library;

import 'package:hostr_sdk/seed/seed.dart';
import 'package:hostr_sdk/usecase/messaging/thread/state.dart';
import 'package:hostr_sdk/usecase/trades/actions/trade_action_resolver.dart';
import 'package:hostr_sdk/usecase/trades/trade.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/ndk.dart' show Nip01Event, Nip01EventModel, Nip01Utils;
import 'package:test/test.dart';

final _f = EntityFactory();

Listing _listing() => _f.listing(
  signer: MockKeys.hoster,
  dTag: 'listing-trade-actions',
  title: 'Trade Action Listing',
  description: 'A listing for trade action tests',
  images: const ['https://picsum.photos/seed/trade-actions/800/600'],
  priceSats: 100000,
  location: 'test-location',
  type: ListingType.house,
  specifications: Specifications(),
  allowSelfSignedReservation: true,
  instantBook: true,
  createdAt: DateTime(2026, 1, 1).millisecondsSinceEpoch ~/ 1000,
);

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

Reservation _escrowBackedReservation(Listing listing) {
  return Reservation.create(
    pubKey: MockKeys.guest.publicKey,
    dTag: 'trade-message-escrow-invalid',
    listingAnchor: listing.anchor!,
    start: DateTime(2026, 3, 1),
    end: DateTime(2026, 3, 2),
    stage: ReservationStage.commit,
    quantity: 1,
    amount: DenominatedAmount(
      value: BigInt.from(100000),
      denomination: 'BTC',
      decimals: 8,
    ),
    proof: _escrowPaymentProof(listing: listing),
    pTags: [
      PTag.seller(MockKeys.hoster.publicKey),
      PTag.buyer(MockKeys.guest.publicKey),
    ],
    createdAt: DateTime(2026, 1, 3).millisecondsSinceEpoch ~/ 1000,
  ).signAs(MockKeys.guest, Reservation.fromNostrEvent);
}

Reservation _reservationWithEscrowParticipantTag(Listing listing) {
  return Reservation.create(
    pubKey: MockKeys.hoster.publicKey,
    dTag: 'trade-message-escrow-tag-only',
    listingAnchor: listing.anchor!,
    start: DateTime(2026, 3, 1),
    end: DateTime(2026, 3, 2),
    stage: ReservationStage.commit,
    quantity: 1,
    amount: DenominatedAmount(
      value: BigInt.from(100000),
      denomination: 'BTC',
      decimals: 8,
    ),
    pTags: [
      PTag.seller(MockKeys.hoster.publicKey),
      PTag.buyer(MockKeys.guest.publicKey),
      PTag.escrow(MockKeys.escrow.publicKey),
    ],
    createdAt: DateTime(2026, 1, 3).millisecondsSinceEpoch ~/ 1000,
  ).signAs(MockKeys.hoster, Reservation.fromNostrEvent);
}

Reservation _cancelledNegotiationRequest(Listing listing) {
  return Reservation.create(
    pubKey: MockKeys.guest.publicKey,
    dTag: 'trade-cancelled-negotiation',
    listingAnchor: listing.anchor!,
    start: DateTime(2026, 3, 1),
    end: DateTime(2026, 3, 2),
    stage: ReservationStage.cancel,
    quantity: 1,
    amount: DenominatedAmount(
      value: BigInt.from(100000),
      denomination: 'BTC',
      decimals: 8,
    ),
    pTags: [
      PTag.seller(MockKeys.hoster.publicKey),
      PTag.buyer(MockKeys.guest.publicKey),
    ],
    createdAt: DateTime(2026, 1, 3).millisecondsSinceEpoch ~/ 1000,
  ).signAs(MockKeys.guest, Reservation.fromNostrEvent);
}

void main() {
  group('TradeActionResolver', () {
    test(
      'keeps messageEscrow action for invalid escrow-backed reservations',
      () {
        final listing = _listing();
        final reservation = _escrowBackedReservation(listing);
        final invalidGroup = Invalid(
          ReservationGroup(reservations: [reservation]),
          'on-chain verification failed',
        );

        final result = TradeActionResolver.resolve(
          threadState: ThreadState.initial(
            ourPubkey: MockKeys.guest.publicKey,
            anchor: 'thread-anchor',
          ),
          listing: listing,
          role: TradeRole.guest,
          tradeId: reservation.getDtag()!,
          start: reservation.start,
          end: reservation.end,
          amount: null,
          ourPubkey: MockKeys.guest.publicKey,
          allReservations: const [],
          allReservationsStatus: StreamStatusLive(),
          ownReservations: [invalidGroup],
          ownReservationsStatus: StreamStatusLive(),
          payments: const [],
          paymentsStatus: StreamStatusLive(),
        );

        expect(result.availability, TradeAvailability.invalidReservation);
        expect(result.actions, contains(TradeAction.messageEscrow));
        expect(result.actions, isNot(contains(TradeAction.cancel)));
      },
    );

    test('shows messageEscrow action when escrow is known from p tag', () {
      final listing = _listing();
      final reservation = _reservationWithEscrowParticipantTag(listing);
      final group = Valid(ReservationGroup(reservations: [reservation]));

      final result = TradeActionResolver.resolve(
        threadState: ThreadState.initial(
          ourPubkey: MockKeys.hoster.publicKey,
          anchor: 'thread-anchor',
        ),
        listing: listing,
        role: TradeRole.host,
        tradeId: reservation.getDtag()!,
        start: reservation.start,
        end: reservation.end,
        amount: null,
        ourPubkey: MockKeys.hoster.publicKey,
        allReservations: const [],
        allReservationsStatus: StreamStatusLive(),
        ownReservations: [group],
        ownReservationsStatus: StreamStatusLive(),
        payments: const [],
        paymentsStatus: StreamStatusLive(),
      );

      expect(result.actions, contains(TradeAction.messageEscrow));
    });

    test('marks negotiate-only cancelled trades as unavailable', () {
      final listing = _listing();
      final request = _cancelledNegotiationRequest(listing);

      final result = TradeActionResolver.resolve(
        threadState: ThreadState(
          ourPubkey: MockKeys.guest.publicKey,
          anchor: 'thread-anchor',
          events: [
            Message<Reservation>(
              pubKey: request.pubKey,
              tags: MessageTags(const []),
              child: request,
              createdAt: request.createdAt,
            ),
          ],
          counterpartyPubkeys: [MockKeys.hoster.publicKey],
          participantPubkeys: [
            MockKeys.guest.publicKey,
            MockKeys.hoster.publicKey,
          ],
        ),
        listing: listing,
        role: TradeRole.guest,
        tradeId: request.getDtag()!,
        start: request.start,
        end: request.end,
        amount: null,
        ourPubkey: MockKeys.guest.publicKey,
        allReservations: const [],
        allReservationsStatus: StreamStatusLive(),
        ownReservations: const [],
        ownReservationsStatus: StreamStatusLive(),
        payments: const [],
        paymentsStatus: StreamStatusLive(),
      );

      expect(result.availability, TradeAvailability.cancelled);
      expect(result.actions, isEmpty);
    });

    test('reports availability loading while overlap reservations load', () {
      final listing = _listing();

      final result = TradeActionResolver.resolve(
        threadState: ThreadState.initial(
          ourPubkey: MockKeys.guest.publicKey,
          anchor: 'thread-anchor',
        ),
        listing: listing,
        role: TradeRole.guest,
        tradeId: 'trade-loading-overlap',
        start: DateTime(2026, 3, 1),
        end: DateTime(2026, 3, 2),
        amount: null,
        ourPubkey: MockKeys.guest.publicKey,
        allReservations: const [],
        allReservationsStatus: StreamStatusQuerying(),
        ownReservations: const [],
        ownReservationsStatus: StreamStatusQuerying(),
        payments: const [],
        paymentsStatus: StreamStatusLive(),
      );

      expect(result.availability, TradeAvailability.loading);
    });
  });
}
