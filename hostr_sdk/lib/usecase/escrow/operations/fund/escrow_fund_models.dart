import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:web3dart/web3dart.dart';

import '../../supported_escrow_contract/supported_escrow_contract.dart';

class EscrowFundParams {
  final EscrowService escrowService;
  final ReservationRequest reservationRequest;
  final ProfileMetadata sellerProfile;
  final Amount amount;

  EscrowFundParams({
    required this.escrowService,
    required this.reservationRequest,
    required this.sellerProfile,
    required this.amount,
  });

  ContractFundEscrowParams toContractParams(EthPrivateKey ethKey) {
    return ContractFundEscrowParams(
      tradeId: reservationRequest.getDtag()!,
      amount: BitcoinAmount.fromAmount(amount),
      sellerEvmAddress: sellerProfile.evmAddress!,
      arbiterEvmAddress: escrowService.parsedContent.evmAddress,
      ethKey: ethKey,
      timelock: 100,
      // escrowFee: escrowService.parsedContent.fee,
    );
  }
}

class EscrowFees {
  final BitcoinAmount estimatedGasFees;
  final SwapInFees estimatedSwapFees;

  EscrowFees({required this.estimatedGasFees, required this.estimatedSwapFees});
}
