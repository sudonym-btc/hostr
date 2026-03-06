import 'package:models/main.dart';
import 'package:web3dart/web3dart.dart';

import '../../../../util/bitcoin_amount.dart';
import '../../../evm/operations/swap_in/swap_in_models.dart';
import '../../supported_escrow_contract/supported_escrow_contract.dart';

class EscrowFundParams {
  final EscrowService escrowService;
  final Reservation negotiateReservation;
  final ProfileMetadata sellerProfile;
  final Amount amount;
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

  ContractFundEscrowParams toContractParams(EthPrivateKey ethKey) {
    final unlockAt = negotiateReservation.end.millisecondsSinceEpoch ~/ 1000;
    return ContractFundEscrowParams(
      tradeId: negotiateReservation.getDtag()!,
      amount: BitcoinAmount.fromAmount(amount),
      sellerEvmAddress: sellerProfile.evmAddress!,
      arbiterEvmAddress: escrowService.evmAddress,
      ethKey: ethKey,
      unlockAt: unlockAt,
      escrowFee: BitcoinAmount.fromInt(
        BitcoinUnit.sat,
        escrowService.escrowFee(
          BitcoinAmount.fromAmount(amount).getInSats.toInt(),
        ),
      ),
    );
  }
}

class EscrowFundFees {
  final BitcoinAmount estimatedGasFees;
  final SwapInFees estimatedSwapFees;
  final BitcoinAmount estimatedEscrowFees;

  EscrowFundFees({
    required this.estimatedGasFees,
    required this.estimatedSwapFees,
    required this.estimatedEscrowFees,
  });

  BitcoinAmount get networkFees =>
      estimatedGasFees + estimatedSwapFees.totalFees;
}
