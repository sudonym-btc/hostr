import 'package:models/main.dart';

class ReservationScenario {
  final String id;
  final String description;
  final Listing listing;
  final ReservationRequest request;
  final Reservation reservation;
  final bool isValid;
  final String? expectedError;

  const ReservationScenario({
    required this.id,
    required this.description,
    required this.listing,
    required this.request,
    required this.reservation,
    required this.isValid,
    this.expectedError,
  });
}
