import 'package:models/main.dart';
import 'package:wallet/wallet.dart';

import '../../../util/custom_logger.dart';
import '../../escrow/supported_escrow_contract/multi_escrow.dart';
import '../../escrow/supported_escrow_contract/supported_escrow_contract.dart';
import '../../escrow/supported_escrow_contract/supported_escrow_contract_registry.dart';
import '../chain/evm_chain.dart';

/// Per-chain escrow capability.
///
/// Provides escrow contract lookup with a generation-aware cache that
/// invalidates whenever the underlying [Web3Client] is rebuilt.
class EscrowCapability {
  final EvmChain chain;
  final CustomLogger _logger;

  final Map<String, SupportedEscrowContract> _cache = {};
  int _cacheGeneration = -1;

  EscrowCapability({required this.chain, required CustomLogger logger})
    : _logger = logger;

  /// Look up an escrow contract for the given [escrowService].
  SupportedEscrowContract getSupportedEscrowContract(
    EscrowService escrowService,
  ) {
    return getSupportedEscrowContractByName(
      'MultiEscrow',
      EthereumAddress.fromHex(escrowService.contractAddress),
    );
  }

  /// Look up an escrow contract by name and address.
  ///
  /// Caches instances keyed by `$contractName:$address` and invalidates
  /// the whole cache when the chain's client generation changes (e.g.
  /// after a [Web3Client] rebuild due to RPC failures).
  SupportedEscrowContract getSupportedEscrowContractByName(
    String contractName,
    EthereumAddress address,
  ) {
    if (_cacheGeneration != chain.clientGeneration) {
      _cache.clear();
      _cacheGeneration = chain.clientGeneration;
    }

    final cacheKey = '$contractName:${address.eip55With0x}';
    return _cache.putIfAbsent(cacheKey, () {
      if (contractName == 'MultiEscrow') {
        return MultiEscrowWrapper(
          chain: chain,
          address: address,
          logger: _logger,
        );
      }

      return SupportedEscrowContractRegistry.getSupportedContract(
        contractName,
        chain,
        address,
      )!;
    });
  }
}
