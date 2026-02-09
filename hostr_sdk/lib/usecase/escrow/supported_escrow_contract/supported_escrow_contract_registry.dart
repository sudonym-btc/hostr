import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import 'multi_escrow.dart';
import 'supported_escrow_contract.dart';

class SupportedEscrowContractRegistry {
  static final Map<
    String,
    SupportedEscrowContract Function(Web3Client client, EthereumAddress address)
  >
  _registry = {
    'MultiEscrow': (client, address) =>
        MultiEscrowWrapper(client: client, address: address),
  };

  static SupportedEscrowContract? getSupportedContract(
    String contractName,
    Web3Client client,
    EthereumAddress address,
  ) {
    final constructor = _registry[contractName];
    if (constructor != null) {
      return constructor(client, address);
    }
    return null;
  }
}
