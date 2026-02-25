import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:web3dart/web3dart.dart';

import '../../supported_escrow_contract/supported_escrow_contract.dart';

class EscrowFundParams {
  final EscrowService escrowService;
  final ReservationRequest reservationRequest;
  final ProfileMetadata sellerProfile;
  final Amount amount;
  final String? listingName;

  EscrowFundParams({
    required this.escrowService,
    required this.reservationRequest,
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

  ContractFundEscrowParams toContractParams(EthPrivateKey ethKey) {
    final unlockAt =
        reservationRequest.parsedContent.end.millisecondsSinceEpoch ~/ 1000;
    return ContractFundEscrowParams(
      tradeId: reservationRequest.getDtag()!,
      amount: BitcoinAmount.fromAmount(amount),
      sellerEvmAddress: sellerProfile.evmAddress!,
      arbiterEvmAddress: escrowService.parsedContent.evmAddress,
      ethKey: ethKey,
      unlockAt: unlockAt,
      // escrowFee: escrowService.parsedContent.fee,
    );
  }
}

class EscrowFundFees {
  final BitcoinAmount estimatedGasFees;
  final SwapInFees estimatedSwapFees;

  EscrowFundFees({
    required this.estimatedGasFees,
    required this.estimatedSwapFees,
  });
}
