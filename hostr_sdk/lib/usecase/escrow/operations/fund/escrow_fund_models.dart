import 'package:models/main.dart';

import '../../../evm/operations/swap_in/swap_in_models.dart';

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

class EscrowFundFees {
  final TokenAmount estimatedGasFees;
  final SwapInFees estimatedSwapFees;
  final TokenAmount estimatedEscrowFees;

  EscrowFundFees({
    required this.estimatedGasFees,
    required this.estimatedSwapFees,
    required this.estimatedEscrowFees,
  });

  TokenAmount get networkFees => estimatedGasFees + estimatedSwapFees.totalFees;
}
