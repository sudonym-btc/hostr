import 'package:crypto/crypto.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart';

import '../../../injection.dart';
import '../../../util/custom_logger.dart';
import 'multi_escrow.dart';
import 'supported_escrow_contract.dart';

class SupportedEscrowContractRegistry {
  static final Map<
    String,
    SupportedEscrowContract Function(Web3Client client, EthereumAddress address)
  >
  _registry = {
    'MultiEscrow': (client, address) => MultiEscrowWrapper(
      client: client,
      address: address,
      logger: getIt<CustomLogger>(),
    ),
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

  /// Fetches the runtime bytecode deployed at [address] and returns its
  /// lowercase hex SHA-256 hash — the canonical contract identity used in
  /// NIP escrow-method `"c"` tags.
  ///
  /// This is the single authoritative place for bytecode-hash calculation so
  /// that the daemon, the SDK, and any tooling all produce identical values.
  static Future<String> bytecodeHashForAddress(
    Web3Client client,
    EthereumAddress address,
  ) async {
    final runtimeCode = await client.getCode(address);
    return sha256.convert(runtimeCode).toString();
  }
}
