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
  final DenominatedAmount estimatedEscrowFees;

  EscrowFundFees({
    required this.estimatedGasFees,
    required this.estimatedSwapFees,
    required this.estimatedEscrowFees,
  });

  /// Total network fees (gas + swap) normalized to BTC sats (8 decimals).
  DenominatedAmount get networkFees {
    final gasDA = estimatedGasFees.toDenominated();
    // Gas fees may be in 18-decimal native (RBTC wei) while swap fees
    // are always in 8-decimal BTC sats. Rescale to 8 before summing.
    final gasNormalized = gasDA.decimals != 8 ? gasDA.rescale(8) : gasDA;
    return gasNormalized + estimatedSwapFees.totalFees;
  }
}
