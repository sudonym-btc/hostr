import 'dart:async';

import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Filter, Nip01EventModel, ZapReceipt;
import 'package:rxdart/rxdart.dart';

class ThreadSubscriptions {
  final Thread thread;
  final CustomLogger logger;
  final Reservations reservations;
  final Zaps zaps;
  final EscrowUseCase escrow;

  ThreadSubscriptions({
    required this.thread,
    required this.logger,
    required this.reservations,
    required this.zaps,
    required this.escrow,
  });

  final BehaviorSubject<ThreadSubscriptionState> state =
      BehaviorSubject<ThreadSubscriptionState>.seeded(
        ThreadSubscriptionState.initial(),
      );

  final PublishSubject<void> _dispose$ = PublishSubject<void>();
  final List<StreamSubscription> _subscriptions = [];
  StreamWithStatus<Reservation>? _reservationStream;
  StreamWithStatus<PaymentEvent>? _paymentEvents;
  StreamWithStatus<Reservation>? _allListingReservationsStream;

  StreamWithStatus<Reservation> get allListingReservationStream =>
      _allListingReservationsStream ??= reservations.subscribe(
        Filter(
          tags: {
            kListingRefTag: [
              MessagingListings.getThreadListing(thread: thread),
            ],
          },
        ),
      );

  StreamWithStatus<Reservation> get reservationStream =>
      _reservationStream ??= reservations.subscribe(
        Filter(
          tags: {
            kListingRefTag: [
              MessagingListings.getThreadListing(thread: thread),
            ],
            kThreadRefTag: [thread.anchor],
          },
        ),
      );

  StreamWithStatus<PaymentEvent> get paymentEvents =>
      _paymentEvents ??= _buildPaymentEvents();

  Future<void> sync() async {
    await unwatch();

    _subscriptions.add(
      Rx.merge([
        reservationStream.status.map((_) => null),
        reservationStream.stream.map((_) => null),
        allListingReservationStream.status.map((_) => null),
        allListingReservationStream.stream.map((_) => null),
        paymentEvents.status.map((_) => null),
        paymentEvents.stream.map((_) => null),
      ]).listen((_) {
        if (state.isClosed) return;
        state.add(
          state.value.copyWith(
            allListingReservations: allListingReservationStream.list.value,
            allListingReservationsStreamStatus:
                allListingReservationStream.status.value,
            reservationStreamStatus: reservationStream.status.value,
            reservations: reservationStream.list.value,
            paymentStreamStatus: paymentEvents.status.value,
            paymentEvents: paymentEvents.list.value,
          ),
        );
      }),
    );
  }

  StreamWithStatus<PaymentEvent> _buildPaymentEvents() {
    final response = DynamicCombinedStreamWithStatus<PaymentEvent>();
    final subscribedEscrowKeys = <String>{};

    StreamWithStatus<EscrowEvent> getSelectedEscrowStream(
      EscrowServiceSelected selectedEscrow,
    ) {
      return escrow.checkEscrowStatus(selectedEscrow, thread.tradeId);
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
    thread.messages.stream
        .where((message) => message.child is EscrowServiceSelected)
        .takeUntil(_dispose$)
        .listen((message) {
          final escrowService = (message.child as EscrowServiceSelected);
          combineIfNew(escrowService);
        });

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

  Future<void> unwatch() async {
    _dispose$.add(null);

    for (final subscription in _subscriptions) {
      await subscription.cancel();
    }
    _subscriptions.clear();

    await _allListingReservationsStream?.close();
    _allListingReservationsStream = null;

    await _reservationStream?.close();
    _reservationStream = null;

    await _paymentEvents?.close();
    _paymentEvents = null;

    if (!state.isClosed) {
      state.add(ThreadSubscriptionState.initial());
    }
  }

  Future<void> close() async {
    await unwatch();
    await _dispose$.close();
    await state.close();
  }
}
