import 'package:models/main.dart';

class ThreadScenario {
  final String id;
  final String description;
  final Listing listing;
  final ReservationRequest reservationRequest;
  final Message<ReservationRequest> requestMessage;
  final List<Reservation> reservations;
  final bool paid;
  final bool refunded;
  final bool cancelled;

  const ThreadScenario({
    required this.id,
    required this.description,
    required this.listing,
    required this.reservationRequest,
    required this.requestMessage,
    required this.reservations,
    required this.paid,
    required this.refunded,
    required this.cancelled,
  });

  String get threadAnchor => reservationRequest.anchor!;
}
