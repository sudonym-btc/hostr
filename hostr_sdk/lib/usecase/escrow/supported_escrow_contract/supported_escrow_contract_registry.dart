import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../../../injection.dart';
import '../../../util/custom_logger.dart';
import '../../evm/chain/rootstock/rif_relay/rif_relay.dart';
import 'multi_escrow.dart';
import 'supported_escrow_contract.dart';

class SupportedEscrowContractRegistry {
  static final Map<
    String,
    SupportedEscrowContract Function(
      Web3Client client,
      EthereumAddress address,
      RifRelay? rifRelay,
    )
  >
  _registry = {
    'MultiEscrow': (client, address, rifRelay) => MultiEscrowWrapper(
      client: client,
      address: address,
      rifRelay: rifRelay,
      logger: getIt<CustomLogger>(),
    ),
  };

  static SupportedEscrowContract? getSupportedContract(
    String contractName,
    Web3Client client,
    EthereumAddress address, {
    RifRelay? rifRelay,
  }) {
    final constructor = _registry[contractName];
    if (constructor != null) {
      return constructor(client, address, rifRelay);
    }
    return null;
  }
}
