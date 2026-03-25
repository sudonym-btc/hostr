import 'package:wallet/wallet.dart' show EthereumAddress;

/// Static chain info from Boltz `GET /chain/contracts`.
///
/// This is purely topology — which contracts live on which chain and what
/// tokens are supported. It does NOT attempt to resolve swap-pair
/// availability (reverse/submarine); that is looked up at swap-time.
class BoltzChainInfo {
  /// The chain key from `GET /chain/contracts` (e.g. `rsk`, `arbitrum`).
  final String chainKey;

  /// Numeric EVM chain ID.
  final int chainId;

  /// Deployed EtherSwap contract address on this chain.
  final EthereumAddress etherSwap;

  /// Deployed ERC20Swap contract address on this chain.
  final EthereumAddress erc20Swap;

  /// ERC-20 token addresses supported on this chain (token name → address).
  /// For Arbitrum this is e.g. `{ "TBTC": 0x6c84… }`.
  /// Empty on chains that only support the native asset (e.g. Rootstock).
  final Map<String, EthereumAddress> tokens;

  const BoltzChainInfo({
    required this.chainKey,
    required this.chainId,
    required this.etherSwap,
    required this.erc20Swap,
    this.tokens = const {},
  });

  /// Whether [tokenAddress] is a known ERC-20 on this Boltz chain.
  bool supportsTokenAddress(EthereumAddress tokenAddress) =>
      tokenNameForAddress(tokenAddress) != null;

  /// Returns the Boltz token name (e.g. `"TBTC"`) for a given on-chain
  /// ERC-20 address, or `null` if not found.
  String? tokenNameForAddress(EthereumAddress tokenAddress) {
    for (final entry in tokens.entries) {
      if (entry.value.eip55With0x.toLowerCase() ==
          tokenAddress.eip55With0x.toLowerCase()) {
        return entry.key;
      }
    }
    return null;
  }
}
