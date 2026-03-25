import 'package:models/main.dart';

class EscrowFundParams {
  final EscrowService escrowService;
  final Reservation negotiateReservation;
  final ProfileMetadata sellerProfile;
  final DenominatedAmount amount;
  final String? listingName;

  EscrowFundParams({
    required this.escrowService,
    required this.negotiateReservation,
    required this.sellerProfile,
    required this.amount,
    this.listingName,
  });

  String get swapInvoiceDescription {
    final trimmed = listingName?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return 'Hostr Reservation';
    }
    return 'Hostr Reservation: $trimmed';
  }
}
