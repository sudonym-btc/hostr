import 'package:models/main.dart';
import 'package:web3dart/web3dart.dart';

import '../../supported_escrow_contract/supported_escrow_contract.dart';

class EscrowClaimParams {
  final EscrowService? escrowService;
  final String tradeId;

  EscrowClaimParams({required this.escrowService, required this.tradeId});

  ContractClaimEscrowParams toContractParams(EthPrivateKey ethKey) {
    return ContractClaimEscrowParams(tradeId: tradeId, ethKey: ethKey);
  }
}
