import 'dart:async';

import 'package:hostr/core/util/stream_status.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/auth/auth.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart';
import 'package:ndk/ndk.dart';

import '../crud.usecase.dart';
import '../messaging/messaging.dart';

@Singleton()
class Reservations extends CrudUseCase<Reservation> {
  final Messaging messaging;
  final Auth auth;
  StreamWithStatus<Reservation>? _myReservations;
  StreamSubscription<Reservation>? _myReservationsSubscription;
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
          kListingRefTag: [listingAnchor],
        },
      ),
    ).then((reservations) {
      logger.d('Found ${reservations.length} reservations');
      return reservations;
    });
  }

  StreamWithStatus<Reservation> subscribeToMyReservations() {
    if (_myReservations != null) {
      return _myReservations!;
    }

    final response = StreamWithStatus<Reservation>();
    response.addStatus(StreamStatusLive());

    _myReservations = response;

    final reservationsStream = messaging.threads.subscription!.replay
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
        .distinct((a, b) => a.id == b.id);

    _myReservationsSubscription?.cancel();
    _myReservationsSubscription = reservationsStream.listen(
      response.add,
      onError: response.addError,
    );

    return response;
  }

  Future<List<RelayBroadcastResponse>> accept(
    Message message,
    ReservationRequest request,
    String guestPubkey,
  ) {
    final reservation = Reservation(
      tags: [
        ['a', request.listingAnchor],
        ['a', message.threadAnchor],
      ],
      content: ReservationContent(
        start: request.parsedContent.start,
        end: request.parsedContent.end,
        guestCommitmentHash: GuestParticipationProof.computeCommitmentHash(
          guestPubkey,
          request.parsedContent.salt,
        ),
      ),
      pubKey: auth.activeKeyPair!.publicKey,
    );
    logger.d('Accepting reservation request: $request');
    return create(reservation);
  }

  Future<Reservation> createSelfSigned({
    required String threadId,
    required ReservationRequest reservationRequest,
    required Listing listing,
    required ProfileMetadata hoster,
    ZapProof? zapProof,
    EscrowProof? escrowProof,
  }) async {
    if (zapProof == null && escrowProof == null) {
      throw Exception('Must provide payment proof');
    }
    String commitment = GuestParticipationProof.computeCommitmentHash(
      auth.activeKeyPair!.publicKey,
      reservationRequest.parsedContent.salt,
    );

    final randomKeyPair = Bip340.generatePrivateKey();

    Reservation reservation = Reservation(
      content: ReservationContent(
        start: reservationRequest.parsedContent.start,
        end: reservationRequest.parsedContent.end,
        guestCommitmentHash: commitment,
        proof: SelfSignedProof(
          hoster: hoster,
          listing: listing,
          zapProof: zapProof,
          escrowProof: escrowProof,
        ),
      ),
      pubKey: randomKeyPair.publicKey,
      tags: [
        [kListingRefTag, listing.anchor!],
        [kThreadRefTag, threadId],
      ],
    )..commitmentHash = commitment;
    reservation.signAs(randomKeyPair, Reservation.fromNostrEvent);
    await create(reservation);
    logger.d(reservation);
    return reservation;
  }

  void dispose() {
    _myReservations?.close();
    _myReservationsSubscription?.cancel();
  }
}
