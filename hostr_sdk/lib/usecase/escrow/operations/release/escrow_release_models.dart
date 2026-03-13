import 'package:models/main.dart';
import 'package:web3dart/web3dart.dart';

import '../../supported_escrow_contract/supported_escrow_contract.dart';

class EscrowReleaseParams {
  final EscrowService? escrowService;
  final String tradeId;

  EscrowReleaseParams({required this.escrowService, required this.tradeId});

  ContractReleaseEscrowParams toContractParams(EthPrivateKey ethKey) {
    return ContractReleaseEscrowParams(tradeId: tradeId, ethKey: ethKey);
  }
}
