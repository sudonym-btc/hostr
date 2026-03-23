import 'package:wallet/wallet.dart' show EthereumAddress;

/// Discovered Boltz chain info from `GET /chain/contracts`.
class BoltzChainInfo {
  /// The Boltz currency symbol (e.g. 'RBTC', 'tBTC', 'arbitrumETH').
  final String currency;

  /// Numeric EVM chain ID.
  final int chainId;

  /// Deployed EtherSwap contract address on this chain.
  final EthereumAddress etherSwap;

  /// Deployed ERC20Swap contract address on this chain.
  final EthereumAddress erc20Swap;

  /// ERC-20 token addresses supported on this chain (token name → address).
  final Map<String, EthereumAddress> tokens;

  const BoltzChainInfo({
    required this.currency,
    required this.chainId,
    required this.etherSwap,
    required this.erc20Swap,
    this.tokens = const {},
  });
}
