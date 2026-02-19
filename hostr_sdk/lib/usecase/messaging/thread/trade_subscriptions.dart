import 'dart:async';

import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Filter, Nip01EventModel, ZapReceipt;
import 'package:rxdart/rxdart.dart';

@injectable
class TradeSubscriptions {
  final Thread thread;
  final CustomLogger logger;
  final Reservations reservations;
  final Reviews reviews;
  final Zaps zaps;
  final EscrowUseCase escrow;

  TradeSubscriptions({
    @factoryParam required this.thread,
    required this.logger,
    required this.reservations,
    required this.zaps,
    required this.escrow,
    required this.reviews,
  });

  final PublishSubject<void> _dispose$ = PublishSubject<void>();
  final List<StreamSubscription> _subscriptions = [];
  bool _started = false;
  StreamWithStatus<Reservation>? reservationStream;
  StreamWithStatus<PaymentEvent>? paymentEventsStream;
  StreamWithStatus<Reservation>? allReservationsStream;
  StreamWithStatus<Review>? myReviewsStream;
  StreamWithStatus<PaymentEvent>? paymentEvents;

  Future<void> start() async {
    if (_started) return;
    _started = true;

    logger.d('Starting trade subscriptions for thread ${thread.anchor}');

    // Explicit initialization so callers can control lifecycle clearly.
    allReservationsStream = reservations.subscribe(
      Filter(
        tags: {
          kListingRefTag: [thread.trade!.getListingAnchor()],
        },
      ),
    );
    // @todo, just filter all reservations for the listing above
    reservationStream = reservations.subscribe(
      Filter(
        tags: {
          kListingRefTag: [thread.trade!.getListingAnchor()],
          kCommitmentHashTag: [thread.anchor],
        },
      ),
    );
    myReviewsStream = reviews.subscribe(
      Filter(
        tags: {
          kListingRefTag: [thread.trade!.getListingAnchor()],
          kCommitmentHashTag: [thread.anchor],
        },
      ),
    );
    ;
    paymentEvents = _buildPaymentEvents();
  }

  Future<void> stop() async {
    if (!_started) return;
    _started = false;

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
  }

  StreamWithStatus<PaymentEvent> _buildPaymentEvents() {
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
      thread.messages.stream
          .where((message) => message.child is EscrowServiceSelected)
          .takeUntil(_dispose$)
          .listen((message) {
            final escrowService = (message.child as EscrowServiceSelected);
            combineIfNew(escrowService);
          }),
    );

    if (thread.state.value.counterpartyPubkeys.isNotEmpty) {
      response.combine(
        zaps
            .subscribeZapReceipts(
              pubkey: thread.state.value.counterpartyPubkeys.first,
              addressableId: thread.anchor,
            )
            .map(
              (event) => ZapFundedEvent(
                event: Nip01EventModel.fromEntity(event),
                zapReceipt: ZapReceipt.fromEvent(event),
                amount: BitcoinAmount.fromInt(
                  BitcoinUnit.sat,
                  ZapReceipt.fromEvent(event).amountSats!,
                ),
              ),
            ),
      );
    }
    return response;
  }

  Future<void> close() async {
    await stop();
    if (!_dispose$.isClosed) {
      await _dispose$.close();
    }
  }
}
