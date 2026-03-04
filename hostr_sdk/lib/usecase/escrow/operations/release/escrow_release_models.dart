import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';

import '../../supported_escrow_contract/supported_escrow_contract.dart';

class EscrowReleaseParams {
  final EscrowService? escrowService;
  final String tradeId;

  /// The EVM address that originally deposited funds. Used to resolve
  /// which HD account index to sign the release transaction with.
  final EthereumAddress? evmAddress;

  EscrowReleaseParams({
    required this.escrowService,
    required this.tradeId,
    this.evmAddress,
  });

  ContractReleaseEscrowParams toContractParams(EthPrivateKey ethKey) {
    return ContractReleaseEscrowParams(tradeId: tradeId, ethKey: ethKey);
  }
}

class EscrowReleaseFees {
  final BitcoinAmount estimatedGasFees;
  final SwapInFees estimatedSwapFees;

  EscrowReleaseFees({
    required this.estimatedGasFees,
    required this.estimatedSwapFees,
  });

  BitcoinAmount get networkFees =>
      estimatedGasFees + estimatedSwapFees.totalFees;
}
