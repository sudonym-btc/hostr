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

  DynamicCombinedStreamWithStatus<SelfSignedProof>? _paymentStream;
  StreamWithStatus<SelfSignedProof> get paymentStream => _paymentStream!;

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
    _paymentStream = DynamicCombinedStreamWithStatus<SelfSignedProof>();
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
        _paymentStream!.combine(getPaymentProof());
        logger.d(
          'No reservations yet, creating self-signed reservation on payment proof when payment is seen',
        );
        final proof = await paymentStream.replay.takeUntil(_dispose$).first;
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

  StreamWithStatus<SelfSignedProof> getPaymentProof() {
    final response = DynamicCombinedStreamWithStatus<SelfSignedProof>();

    StreamWithStatus<SelfSignedProof> selfSignedProofForService(
      EscrowServiceSelected selectedEscrow,
    ) {
      return escrow
          .checkEscrowStatus(selectedEscrow, thread.tradeId)
          .whereType<FundedEvent>()
          .map(
            (fundedEvent) => EscrowProof(
              txHash: fundedEvent.transactionHash,
              hostsTrustedEscrows: selectedEscrow.parsedContent.sellerTrusts,
              hostsEscrowMethods: selectedEscrow.parsedContent.sellerMethods,
              escrowService: selectedEscrow.parsedContent.service,
            ),
          )
          .asyncMap(
            (proof) async => SelfSignedProof(
              listing: (await getListing())!,
              hoster: (await getListingProfile())!,
              escrowProof: proof,
              zapProof: null,
            ),
          );
    }

    // Set to live in case there are no selected escrows or zaps, so that the stream doesn't get stuck on loading status without emitting anything
    // response.addStatus(StreamStatusLive());
    for (final escrowService in thread.selectedEscrows) {
      response.combine(selfSignedProofForService(escrowService));
    }
    thread.messages.stream
        .where((message) => message.child is EscrowServiceSelected)
        .takeUntil(_dispose$)
        .listen((message) {
          final escrowService = (message.child as EscrowServiceSelected);
          response.combine(selfSignedProofForService(escrowService));
        });

    response.combine(
      zaps
          .subscribeZapReceipts(
            pubkey: thread.counterpartyPubkeys.first,
            addressableId: thread.anchor,
          )
          .map(
            (receipt) => ZapProof(receipt: Nip01EventModel.fromEntity(receipt)),
          )
          .asyncMap(
            (proof) async => SelfSignedProof(
              listing: (await listing)!,
              hoster: (await listingProfile)!,
              zapProof: proof,
              escrowProof: null,
            ),
          ),
    );

    return response;
  }

  Future<void> removeSubscriptions() async {
    await _paymentStream?.close();
    _paymentStream = null;
    await _reservationStream?.close();
    _reservationStream = null;
  }

  Future<void> close() async {
    await removeSubscriptions();
    _dispose$.add(null);
    await _dispose$.close();
  }
}
