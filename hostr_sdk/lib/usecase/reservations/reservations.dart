import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

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
      final thread =
          messaging.threads.threads[reservation.parsedTags.commitmentHash];
      if (thread == null) continue;

      final sellerPubKey = getPubKeyFromAnchor(
        thread.state.value.lastReservationRequest.parsedTags.listingAnchor,
      );

      final current =
          temp[reservation.parsedTags.commitmentHash] ??
          (sellerReservation: null, buyerReservation: null);

      if (reservation.pubKey == sellerPubKey) {
        temp[reservation.parsedTags.commitmentHash] = (
          sellerReservation: reservation,
          buyerReservation: current.buyerReservation,
        );
      } else {
        temp[reservation.parsedTags.commitmentHash] = (
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
            listingAnchor: reservationRequest.parsedTags.listingAnchor,
          );
          logger.d('Found reservations: $reservations');
          return reservations.firstWhere(
            (reservation) =>
                reservation.parsedTags.commitmentHash ==
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
    String anchor,
    ReservationRequest request,
    String guestPubkey,
    String saltedPubkey,
  ) {
    final reservation = Reservation(
      tags: ReservationTags([
        ['p', saltedPubkey],
        [kListingRefTag, request.parsedTags.listingAnchor],
        [kThreadRefTag, anchor],
        [
          kCommitmentHashTag,
          ParticipationProof.computeCommitmentHash(
            guestPubkey,
            request.parsedContent.salt,
          ),
        ],
      ]),
      content: ReservationContent(
        start: request.parsedContent.start,
        end: request.parsedContent.end,
      ),
      pubKey: auth.activeKeyPair!.publicKey,
    );
    logger.d('Accepting reservation request: $request');
    return create(reservation);
  }

  Future<Reservation> createSelfSigned({
    required KeyPair activeKeyPair,
    required ReservationRequest reservationRequest,
    required PaymentProof proof,
  }) async {
    String commitment = ParticipationProof.computeCommitmentHash(
      auth.activeKeyPair!.publicKey,
      reservationRequest.parsedContent.salt,
    );

    Reservation reservation = Reservation(
      content: ReservationContent(
        start: reservationRequest.parsedContent.start,
        end: reservationRequest.parsedContent.end,
        proof: proof,
      ),
      pubKey: activeKeyPair.publicKey,
      tags: ReservationTags([
        [kListingRefTag, proof.listing.anchor!],
        [kCommitmentHashTag, commitment],
      ]),
    );

    await create(reservation.signAs(activeKeyPair, Reservation.fromNostrEvent));
    logger.d('Created self-signed reservation: $reservation');
    return reservation;
  }

  Future<Reservation> cancel(Reservation reservation) async {
    if (reservation.parsedContent.cancelled) {
      throw Exception('Reservation is already cancelled');
    }
    final updated = reservation.copy(
      createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      id: null,
      content: reservation.parsedContent.copyWith(cancelled: true),
      pubKey: null,
    );
    logger.d('Cancelling reservation: $updated');
    await update(updated);
    return updated;
  }

  Future<Reservation> createBlocked({
    required String listingAnchor,
    required DateTime start,
    required DateTime end,
  }) async {
    final reservation = Reservation(
      content: ReservationContent(start: start, end: end),
      pubKey: auth.activeKeyPair!.publicKey,
      tags: ReservationTags([
        [kListingRefTag, listingAnchor],
        [
          kCommitmentHashTag,
          ParticipationProof.computeCommitmentHash(
            auth.activeKeyPair!.publicKey,
            Reservation.getSaltForBlockedReservation(
              start: start,
              end: end,
              hostKey: auth.activeKeyPair!,
            ),
          ),
        ],
      ]),
    );

    await create(reservation);
    logger.d('Created blocked reservation: $reservation');
    return reservation;
  }

  void dispose() {
    _myReservations?.close();
    _myReservationsSubscription?.cancel();
  }
}
