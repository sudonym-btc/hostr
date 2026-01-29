import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

import '../crud.usecase.dart';
import '../messaging/messaging.dart';

@Singleton()
class Reservations extends CrudUseCase<Reservation> {
  final Messaging messaging;
  Reservations({required super.requests, required this.messaging})
    : super(kind: Reservation.kinds[0]);

  Future<List<Reservation>> getListingReservations({
    required String listingAnchor,
  }) {
    return list(Filter(aTags: [listingAnchor]));
  }

  Stream<Reservation> subscribeToMyReservations() {
    // First fetch all messages
    // Filter by reservation requests
    // Optional: needed to check wether Reservation is ours, but not if we're going through own messages anyway. Decrypt the commitmentHashPreimageEnc with auth keys
    // Then fetch Reservations by commitmentHash
    return messaging.threads.messageStream
        .where((message) => message.content is ReservationRequest)
        .map((message) => message.content as ReservationRequest)
        .asyncMap((reservationRequest) async {
          final reservations = await getListingReservations(
            listingAnchor: reservationRequest.tags.firstWhere(
              (tag) => tag[0] == 'commitmentHash',
            )[1],
          );
          return reservations.firstWhere(
            (reservation) =>
                reservation.getCommitmentHash() ==
                reservationRequest.parsedContent.commitmentHash,
            orElse: () => throw Exception('Reservation not found'),
          );
        });
    ;
  }
}
