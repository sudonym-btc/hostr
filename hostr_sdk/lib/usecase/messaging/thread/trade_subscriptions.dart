import 'dart:async';

import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Filter, Nip01EventModel, ZapReceipt;
import 'package:rxdart/rxdart.dart';

@injectable
class TradeSubscriptions {
  final Auth auth;
  final Thread thread;
  final CustomLogger logger;
  final Reservations reservations;
  final ReservationPairs reservationPairs;
  final Reviews reviews;
  final Zaps zaps;
  final EscrowUseCase escrow;
  final ReservationTransitions reservationTransitions;

  TradeSubscriptions({
    @factoryParam required this.thread,
    required this.auth,
    required this.logger,
    required this.reservations,
    required this.reservationPairs,
    required this.zaps,
    required this.escrow,
    required this.reviews,
    required this.reservationTransitions,
  });

  final PublishSubject<void> _dispose$ = PublishSubject<void>();
  final List<StreamSubscription> _subscriptions = [];
  bool _started = false;
  ValidatedStreamWithStatus<ReservationPairStatus>? reservationStream;
  ValidatedStreamWithStatus<ReservationPairStatus>? allReservationsStream;
  StreamWithStatus<Review>? myReviewsStream;
  StreamWithStatus<PaymentEvent>? paymentEvents;
  StreamWithStatus<ReservationTransition>? transitionsStream;

  Future<void> start(TradeContext context) async {
    if (_started) return;
    _started = true;

    logger.d(
      'Starting trade subscriptions for thread ${thread.trade!.state.value.tradeId}',
    );

    final listing = context.listing;

    // Only force-validate (on-chain check) the pair belonging to our own
    // trade. All other pairs for the listing are validated at the cheaper
    // Nostr level so we don't trigger unnecessary RPC calls.
    final ownTradeId = thread.trade!.state.value.tradeId;
    allReservationsStream = reservationPairs.subscribeVerified(
      listing: listing,
      forceValidatePredicate: (pair) {
        final pairTradeId =
            pair.sellerReservation?.getDtag() ??
            pair.buyerReservation?.getDtag();
        return pairTradeId == ownTradeId;
      },
    );
    reservationStream = _filterByTradeId(
      source: allReservationsStream!,
      tradeId: thread.trade!.state.value.tradeId,
    );
    myReviewsStream = reviews.subscribe(
      name: 'trade-sub-${thread.trade!.state.value.tradeId}-reviews',
      Filter(
        authors: [auth.getActiveKey().publicKey],
        tags: {
          kListingRefTag: [thread.trade!.getListingAnchor()],
        },
      ),
    );
    transitionsStream = reservationTransitions.subscribeForReservation(
      thread.trade!.state.value.tradeId,
    );
    paymentEvents = await _buildPaymentEvents(listing: listing);
  }

  Future<void> stop() async {
    if (!_started) return;
    _started = false;

    logger.d(
      'Stopping trade subscriptions for thread ${thread.trade!.state.value.tradeId}',
    );

    if (!_dispose$.isClosed) {
      _dispose$.add(null);
    }

    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();

    await allReservationsStream?.close();
    allReservationsStream = null;
    await myReviewsStream?.close();
    myReviewsStream = null;
    await reservationStream?.close();
    reservationStream = null;
    await paymentEvents?.close();
    paymentEvents = null;
    await transitionsStream?.close();
    transitionsStream = null;
  }

  Future<StreamWithStatus<PaymentEvent>> _buildPaymentEvents({
    required Listing? listing,
  }) async {
    final response = DynamicCombinedStreamWithStatus<PaymentEvent>();
    final subscribedEscrowKeys = <String>{};

    StreamWithStatus<EscrowEvent> getSelectedEscrowStream(
      EscrowServiceSelected selectedEscrow,
    ) {
      return escrow.checkEscrowStatus(selectedEscrow, thread.anchor);
    }

    String escrowKey(EscrowServiceSelected selectedEscrow) {
      final service = selectedEscrow.parsedContent.service;
      return service.id;
    }

    void combineIfNew(EscrowServiceSelected selectedEscrow) {
      final key = escrowKey(selectedEscrow);
      if (!subscribedEscrowKeys.add(key)) {
        logger.d('Skipping duplicate selected escrow subscription: $key');
        return;
      }
      response.combine(getSelectedEscrowStream(selectedEscrow));
    }

    for (final escrowService in thread.state.value.selectedEscrows) {
      combineIfNew(escrowService);
    }
    _subscriptions.add(
      Rx.merge([
        reservationStream!.stream
            .expand((items) => items)
            .map((validation) => validation.event)
            .expand((pair) => [pair.sellerReservation, pair.buyerReservation])
            .whereType<Reservation>()
            .where(
              (reservation) =>
                  reservation.parsedContent.proof?.escrowProof != null,
            )
            .doOnData((reservation) {
              logger.d(
                'Found reservation with escrow proof, adding escrow subscription for thread ${thread.anchor}',
              );
            })
            .map((reservation) => reservation.parsedContent.proof!.escrowProof!)
            .map(
              (proof) => EscrowServiceSelected(
                content: EscrowServiceSelectedContent(
                  service: proof.escrowService,
                  sellerTrusts: proof.hostsTrustedEscrows,
                  sellerMethods: proof.hostsEscrowMethods,
                ),
                pubKey: '',
                tags: EscrowServiceSelectedTags([]),
              ),
            ),
        thread.messages.stream
            .where((message) => message.child is EscrowServiceSelected)
            .takeUntil(_dispose$)
            .map((event) => event.child as EscrowServiceSelected),
      ]).listen(combineIfNew),
    );

    final sellerPubkey = listing?.pubKey;
    if (sellerPubkey != null && sellerPubkey.isNotEmpty) {
      logger.d(
        'Subscribing to zap receipts for thread ${thread.anchor} and seller $sellerPubkey',
      );
      response.combine(
        zaps
            .subscribeZapReceipts(
              pubkey: sellerPubkey,
              eventId: thread.trade!.state.value.tradeId,
            )
            .asyncMap((event) async {
              try {
                final receipt = ZapReceipt.fromEvent(event);
                final amountSats = receipt.amountSats;
                if (amountSats == null) {
                  logger.w(
                    'Skipping zap receipt without parsable amount for thread ${thread.anchor}: ${event.id}',
                  );
                  return null;
                }

                return ZapFundedEvent(
                  event: Nip01EventModel.fromEntity(event),
                  zapReceipt: receipt,
                  amount: BitcoinAmount.fromInt(BitcoinUnit.sat, amountSats),
                );
              } catch (e) {
                logger.w(
                  'Skipping invalid zap receipt for thread ${thread.anchor}: ${event.id}, error: $e',
                );
                return null;
              }
            })
            .whereType<PaymentEvent>(),
      );
    } else {
      logger.w(
        'Skipping zap receipt subscription for thread ${thread.anchor}: listing/seller pubkey unavailable',
      );
    }
    return response;
  }

  ValidatedStreamWithStatus<ReservationPairStatus> _filterByTradeId({
    required ValidatedStreamWithStatus<ReservationPairStatus> source,
    required String tradeId,
  }) {
    late final StreamSubscription<StreamStatus> statusSub;
    late final StreamSubscription<List<Validation<ReservationPairStatus>>>
    listSub;

    final filtered = ValidatedStreamWithStatus<ReservationPairStatus>(
      onClose: () async {
        await statusSub.cancel();
        await listSub.cancel();
      },
    );

    statusSub = source.status.listen(
      filtered.addStatus,
      onError: filtered.addError,
    );

    listSub = source.stream.listen((items) {
      filtered.setSnapshot(
        items.where((item) {
          final pair = item.event;
          final pairTradeId =
              pair.sellerReservation?.getDtag() ??
              pair.buyerReservation?.getDtag();
          return pairTradeId == tradeId;
        }).toList(),
      );
    }, onError: filtered.addError);

    return filtered;
  }

  Future<void> close() async {
    await stop();
    if (!_dispose$.isClosed) {
      await _dispose$.close();
    }
  }
}
