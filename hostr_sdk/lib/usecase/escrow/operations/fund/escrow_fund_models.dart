import 'package:models/main.dart';

import '../../../evm/operations/swap_in/swap_in_models.dart';

class EscrowFundParams {
  final EscrowService escrowService;
  final Order negotiateOrder;
  final ProfileMetadata sellerProfile;
  final String sellerEvmAddress;
  final DenominatedAmount amount;

  /// The seller's escrow-method event, used to determine which on-chain token
  /// to fund the escrow with for the listing's denomination (e.g. USDT for
  /// USD-priced listings). When null, falls back to the Boltz bridge token.
  final EscrowMethod? sellerEscrowMethod;

  /// Optional security deposit from the listing. When present, the on-chain
  /// trade will include a `bondAmount` in addition to the payment amount.
  final DenominatedAmount? securityDeposit;

  /// Maximum time in seconds after the order end date that the escrow
  /// unlocks at. When null the default (2 weeks) is used.
  final int? maxDisputePeriod;

  final String? listingName;

  /// DEX input buffer forwarded to swap-in funding when escrow funding needs a
  /// bridge-token -> escrow-token DEX hop. Defaults to the normal swap-in
  /// buffer; pass [SwapInDexBuffer.zero] for exact zero-dust tests.
  final SwapInDexBuffer dexInputBuffer;

  EscrowFundParams({
    required this.escrowService,
    required this.negotiateOrder,
    required this.sellerProfile,
    required this.sellerEvmAddress,
    required this.amount,
    this.sellerEscrowMethod,
    this.securityDeposit,
    this.maxDisputePeriod,
    this.listingName,
    this.dexInputBuffer = SwapInDexBuffer.standard,
  });

  String get swapInvoiceDescription {
    final trimmed = listingName?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return 'Hostr Order';
    }
    return 'Hostr Order: $trimmed';
  }
}
