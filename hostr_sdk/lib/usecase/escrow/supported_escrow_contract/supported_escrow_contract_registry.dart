import 'package:crypto/crypto.dart';
import 'package:wallet/wallet.dart';
import '../../evm/chain/evm_chain.dart';
import 'multi_escrow.dart';
import 'supported_escrow_contract.dart';

class SupportedEscrowContractRegistry {
  static final Map<
    String,
    SupportedEscrowContract Function(EvmChain chain, EthereumAddress address)
  >
  _registry = {
    'MultiEscrow': (chain, address) => MultiEscrowWrapper(
      chain: chain,
      address: address,
      logger: chain.logger,
    ),
  };

  static SupportedEscrowContract? getSupportedContract(
    String contractName,
    EvmChain chain,
    EthereumAddress address,
  ) {
    final constructor = _registry[contractName];
    if (constructor != null) {
      return constructor(chain, address);
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
    EvmChain chain,
    EthereumAddress address,
  ) async {
    final runtimeCode = await chain.getCode(address);
    return sha256.convert(runtimeCode).toString();
  }
}
