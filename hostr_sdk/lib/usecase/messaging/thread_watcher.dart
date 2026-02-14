import 'dart:async';

import 'package:hostr_sdk/usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart';
import 'package:hostr_sdk/usecase/main.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' hide Zaps;
import 'package:rxdart/rxdart.dart';

@Injectable()
class ThreadWatcher {
  final CustomLogger logger;
  final Thread thread;
  final Reservations reservations;
  final Zaps zaps;
  final Listings listings;
  final EscrowUseCase escrow;
  final MetadataUseCase metadata;
  final PublishSubject<void> _dispose$ = PublishSubject<void>();
  bool _isWatching = false;

  Completer<Listing?>? _listingCompleter;
  Completer<ProfileMetadata?>? _listingProfileCompleter;

  Future<Listing?> get listing => getListing();

  Future<ProfileMetadata?> get listingProfile => getListingProfile();

  StreamWithStatus<Reservation>? _reservationStream;
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

  StreamWithStatus<PaymentEvent>? paymentEvents =
      StreamWithStatus<PaymentEvent>();

  ThreadWatcher(
    @factoryParam this.thread, {
    required this.logger,
    required this.reservations,
    required this.listings,
    required this.metadata,
    required this.escrow,
    required this.zaps,
  });

  void watch() {
    if (_isWatching) {
      logger.e('Already watching thread ${thread.anchor}, skipping');
      return;
    }
    _isWatching = true;
    paymentEvents = getPaymentEvents();
    listenForPaymentProofAfterReservations();
  }

  // Necessarily awaits fetching of reservations
  // If no reservations exist, listens for the next payment proof and creates a self-signed reservation
  void listenForPaymentProofAfterReservations() async {
    try {
      await reservationStream.status
          .whereType<StreamStatusLive>()
          .takeUntil(_dispose$)
          .first;
      if (reservationStream.list.value.isEmpty) {
        final proof = await paymentEvents!.stream
            .whereType<PaymentFundedEvent>()
            .takeUntil(_dispose$)
            .asyncMap((event) async {
              return SelfSignedProof(
                listing: (await getListing())!,
                hoster: (await getListingProfile())!,
                zapProof: event is ZapFundedEvent
                    ? ZapProof(receipt: Nip01EventModel.fromEntity(event.event))
                    : null,
                escrowProof: event is EscrowFundedEvent
                    ? EscrowProof(
                        txHash: event.transactionHash,
                        hostsTrustedEscrows:
                            event.escrowService!.parsedContent.sellerTrusts,
                        hostsEscrowMethods:
                            event.escrowService!.parsedContent.sellerMethods,
                        escrowService:
                            event.escrowService!.parsedContent.service,
                      )
                    : null,
              );
            })
            .first;
        logger.d(
          'No reservations yet, creating self-signed reservation on payment proof when payment is seen',
        );
        logger.d(
          'Payment completed, creating reservation on thread ${proof.escrowProof}, proof: ${proof.zapProof}',
        );

        final reservation = await reservations.createSelfSigned(
          threadId: thread.anchor,
          reservationRequest: thread.lastReservationRequest,
          proof: proof,
        );
        logger.d("Created self-signed reservation: ${reservation.id}");
      }
    } catch (e) {
      logger.d('listenForPaymentProof cancelled: $e');
    }
  }

  Future<Listing?> getListing() {
    if (_listingCompleter != null) {
      return _listingCompleter!.future;
    }

    _listingCompleter = Completer<Listing?>();
    listings
        .getOneByDTag(
          getDTagFromAnchor(MessagingListings.getThreadListing(thread: thread)),
        )
        .then(_listingCompleter!.complete)
        .catchError(_listingCompleter!.completeError);
    return _listingCompleter!.future;
  }

  Future<ProfileMetadata?> getListingProfile() {
    if (_listingProfileCompleter != null) {
      return _listingProfileCompleter!.future;
    }

    _listingProfileCompleter = Completer<ProfileMetadata?>();
    getListing()
        .then((listing) async {
          if (listing == null) return null;
          return metadata.getOne(Filter(authors: [listing.pubKey]));
        })
        .then(_listingProfileCompleter!.complete)
        .catchError(_listingProfileCompleter!.completeError);
    return _listingProfileCompleter!.future;
  }

  StreamWithStatus<PaymentEvent> getPaymentEvents() {
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

    // Set to live in case there are no selected escrows or zaps, so that the stream doesn't get stuck on loading status without emitting anything
    // response.addStatus(StreamStatusLive());
    for (final escrowService in thread.selectedEscrows) {
      combineIfNew(escrowService);
    }
    thread.messages.stream
        .where((message) => message.child is EscrowServiceSelected)
        .takeUntil(_dispose$)
        .listen((message) {
          final escrowService = (message.child as EscrowServiceSelected);
          combineIfNew(escrowService);
        });

    response.combine(
      zaps
          .subscribeZapReceipts(
            pubkey: thread.counterpartyPubkeys.first,
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
    return response;
  }

  Future<void> removeSubscriptions() async {
    // Cancel all takeUntil(_dispose$) listeners created during watch().
    _dispose$.add(null);

    await _reservationStream?.close();
    _reservationStream = null;
    await paymentEvents?.close();
    paymentEvents = null;
    _isWatching = false;
  }

  Future<void> close() async {
    await removeSubscriptions();
    await _dispose$.close();
  }
}
