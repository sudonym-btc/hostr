import 'package:models/main.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';

import '../../supported_escrow_contract/supported_escrow_contract.dart';

class EscrowClaimParams {
  final EscrowService? escrowService;
  final String tradeId;

  /// The EVM address that originally deposited funds. Used to resolve
  /// which HD account index to sign the claim transaction with.
  final EthereumAddress? evmAddress;

  EscrowClaimParams({
    required this.escrowService,
    required this.tradeId,
    this.evmAddress,
  });

  ContractClaimEscrowParams toContractParams(EthPrivateKey ethKey) {
    return ContractClaimEscrowParams(tradeId: tradeId, ethKey: ethKey);
  }
}
