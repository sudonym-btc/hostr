import 'package:models/main.dart';

class EscrowFundParams {
  final EscrowService escrowService;
  final Reservation negotiateReservation;
  final ProfileMetadata sellerProfile;
  final DenominatedAmount amount;

  /// Optional security deposit from the listing. When present, the on-chain
  /// trade will include a `bondAmount` in addition to the payment amount.
  final DenominatedAmount? securityDeposit;

  final String? listingName;

  EscrowFundParams({
    required this.escrowService,
    required this.negotiateReservation,
    required this.sellerProfile,
    required this.amount,
    this.securityDeposit,
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
