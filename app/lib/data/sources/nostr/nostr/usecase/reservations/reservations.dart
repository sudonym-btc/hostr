import 'package:hostr/data/sources/nostr/nostr/usecase/auth/auth.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart';
import 'package:ndk/ndk.dart';
import 'package:rxdart/rxdart.dart';

import '../crud.usecase.dart';
import '../messaging/messaging.dart';

@Singleton()
class Reservations extends CrudUseCase<Reservation> {
  final Messaging messaging;
  final Auth auth;
  Stream<Reservation>? _myReservationsStream;
  Reservations({
    required super.requests,
    required this.messaging,
    required this.auth,
  }) : super(kind: Reservation.kinds[0]);

  Future<List<Reservation>> getListingReservations({
    required String listingAnchor,
  }) {
    logger.d('Fetching reservations for listing: $listingAnchor');
    return list(
      Filter(
        kinds: Reservation.kinds,
        tags: {
          REFERENCE_LISTING_TAG: [listingAnchor],
        },
      ),
    ).then((reservations) {
      logger.d('Found ${reservations.length} reservations');
      return reservations;
    });
  }

  Stream<Reservation> subscribeToMyReservations() {
    if (_myReservationsStream != null) {
      return _myReservationsStream!;
    }

    _myReservationsStream = messaging.threads.messageStream
        .where((message) => message.child is ReservationRequest)
        .map((message) => message.child as ReservationRequest)
        .asyncMap((reservationRequest) async {
          logger.d(
            'Processing reservation request: $reservationRequest, ${reservationRequest.getFirstTag('a')}',
          );
          final reservations = await getListingReservations(
            listingAnchor: reservationRequest.listingAnchor,
          );
          logger.d('Found reservations: $reservations');
          return reservations.firstWhere(
            (reservation) =>
                reservation.commitmentHash ==
                GuestParticipationProof.computeCommitmentHash(
                  auth.activeKeyPair!.publicKey,
                  reservationRequest.parsedContent.salt,
                ),
            orElse: () => throw Exception('Reservation not found'),
          );
        })
        .publishReplay()
        .refCount();

    return _myReservationsStream!;
  }

  Future<List<RelayBroadcastResponse>> accept(
    Message message,
    ReservationRequest request,
    String guestPubkey,
  ) {
    final reservation = Reservation.fromNostrEvent(
      Nip01Event(
        kind: NOSTR_KIND_RESERVATION,
        tags: [
          [REFERENCE_LISTING_TAG, request.listingAnchor],
          [THREAD_ANCHOR_TAG, message.threadAnchor!],
        ],
        content: ReservationContent(
          start: request.parsedContent.start,
          end: request.parsedContent.end,
          guestCommitmentHash: GuestParticipationProof.computeCommitmentHash(
            guestPubkey,
            request.parsedContent.salt,
          ),
        ).toString(),
        pubKey: auth.activeKeyPair!.publicKey,
      ),
    );
    logger.d('Accepting reservation request: $request');
    return create(reservation);
  }
}
