import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart';
import 'package:ndk/ndk.dart';

import '../../util/main.dart';
import '../auth/auth.dart';
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
    required super.logger,
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

  static Reservation? seniorReservations(
    List<Reservation> reservations,
    Listing listing,
  ) {
    return Reservation.getSeniorReservation(
      reservations: reservations,
      listing: listing,
    );
  }

  static List<Reservation> filterCancelled(List<Reservation> reservations) {
    return reservations.where((e) => !e.parsedContent.cancelled).toList();
  }

  Map<String, ({Reservation? sellerReservation, Reservation? buyerReservation})>
  groupByThread(List<Reservation> reservations) {
    final temp =
        <
          String,
          ({Reservation? sellerReservation, Reservation? buyerReservation})
        >{};

    for (final reservation in reservations) {
      final threadAnchor = reservation.threadAnchor;
      final thread = messaging.threads.threads[threadAnchor];
      if (thread == null) continue;

      final sellerPubKey = getPubKeyFromAnchor(
        thread.lastReservationRequest.listingAnchor,
      );

      final current =
          temp[threadAnchor] ??
          (sellerReservation: null, buyerReservation: null);

      if (reservation.pubKey == sellerPubKey) {
        temp[threadAnchor] = (
          sellerReservation: reservation,
          buyerReservation: current.buyerReservation,
        );
      } else {
        temp[threadAnchor] = (
          sellerReservation: current.sellerReservation,
          buyerReservation: reservation,
        );
      }
    }
    return temp;
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
                ParticipationProof.computeCommitmentHash(
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
        commitmentHash: ParticipationProof.computeCommitmentHash(
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
    required SelfSignedProof proof,
  }) async {
    String commitment = ParticipationProof.computeCommitmentHash(
      auth.activeKeyPair!.publicKey,
      reservationRequest.parsedContent.salt,
    );

    final randomKeyPair = Bip340.generatePrivateKey();

    Reservation reservation = Reservation(
      content: ReservationContent(
        start: reservationRequest.parsedContent.start,
        end: reservationRequest.parsedContent.end,
        commitmentHash: commitment,
        proof: proof,
      ),
      pubKey: randomKeyPair.publicKey,
      tags: [
        [kListingRefTag, proof.listing.anchor!],
        [kThreadRefTag, threadId],
        [kCommitmentHashTag, commitment],
      ],
    );

    await create(reservation.signAs(randomKeyPair, Reservation.fromNostrEvent));
    logger.d(reservation);
    return reservation;
  }

  void dispose() {
    _myReservations?.close();
    _myReservationsSubscription?.cancel();
  }
}
