import 'package:models/main.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;

import '../../../datasources/boltz/boltz.dart';
import '../../../datasources/boltz/boltz_chain_info.dart';
import '../../../datasources/boltz/boltz_fee_estimate.dart';
import '../../../datasources/contracts/boltz/ERC20Swap.g.dart';
import '../../../datasources/contracts/boltz/EtherSwap.g.dart';
import '../../../datasources/swagger_generated/boltz.swagger.dart';
import '../../../util/custom_logger.dart';
import '../chain/evm_chain.dart';

/// Per-chain Boltz swap capability.
///
/// Wraps a [BoltzClient] + discovered [BoltzChainInfo] so callers don't
/// need to know about currency strings or contract addresses.
///
/// Currency resolution: Boltz uses short string keys (e.g. `RBTC`, `TBTC`)
/// to identify assets in swap-pair endpoints. For the **native** asset on a
/// chain, [nativeCurrency] is supplied by the app config (e.g. `RBTC` on
/// Rootstock). For **ERC-20 tokens**, the currency is the token name from
/// `/chain/contracts` (e.g. `TBTC`). This mapping is performed by
/// [currencyForTokenAddress] at swap-time.
class BoltzSwapProvider {
  final BoltzClient boltzClient;
  final BoltzChainInfo chainInfo;
  final EvmChain chain;
  final CustomLogger _logger;

  /// Boltz currency string for the chain's native asset (e.g. `RBTC`).
  /// Null on chains that only support ERC-20 token swaps (no native pair).
  final String? nativeCurrency;

  BoltzSwapProvider({
    required this.boltzClient,
    required this.chainInfo,
    required this.chain,
    required CustomLogger logger,
    this.nativeCurrency,
  }) : _logger = logger;

  /// Resolve the Boltz currency string for a given token address.
  /// Returns the token name (e.g. `TBTC`) for ERC-20s, or the chain's
  /// [nativeCurrency] (e.g. `RBTC`) when [tokenAddress] is null.
  ///
  /// Throws if [tokenAddress] is null and no [nativeCurrency] is configured,
  /// or if the token address isn't known to Boltz on this chain.
  String currencyForTokenAddress(EthereumAddress? tokenAddress) {
    if (tokenAddress == null) {
      if (nativeCurrency == null) {
        throw StateError(
          'No native Boltz currency configured for chain '
          '${chainInfo.chainKey} (chainId=${chainInfo.chainId}). '
          'This chain only supports ERC-20 token swaps.',
        );
      }
      return nativeCurrency!;
    }
    final tokenName = chainInfo.tokenNameForAddress(tokenAddress);
    if (tokenName != null) return tokenName;
    if (nativeCurrency != null) return nativeCurrency!;
    throw StateError(
      'Token ${tokenAddress.eip55With0x} is not a known Boltz currency '
      'on chain ${chainInfo.chainKey} (chainId=${chainInfo.chainId}). '
      'Known tokens: ${chainInfo.tokens.keys.toList()}',
    );
  }

  bool supportsTokenAddress(EthereumAddress tokenAddress) =>
      chainInfo.supportsTokenAddress(tokenAddress);

  /// Live [EtherSwap] contract on this chain.
  EtherSwap getEtherSwapContract() =>
      EtherSwap(address: chainInfo.etherSwap, client: chain.client);

  /// Live [ERC20Swap] contract on this chain.
  ERC20Swap getERC20SwapContract() =>
      ERC20Swap(address: chainInfo.erc20Swap, client: chain.client);

  /// Fetch reverse-swap pair info for this chain's currency.
  Future<ReversePair> getReversePair({EthereumAddress? tokenAddress}) =>
      boltzClient.getReversePair(
        from: 'BTC',
        to: currencyForTokenAddress(tokenAddress),
      );

  /// Fetch submarine-swap pair info for this chain's currency.
  Future<SubmarinePair> getSubmarinePair({EthereumAddress? tokenAddress}) =>
      boltzClient.getSubmarinePair(
        from: currencyForTokenAddress(tokenAddress),
        to: 'BTC',
      );

  DenominatedAmount _swapAmountFromSats(int sats) {
    return DenominatedAmount(
      denomination: 'BTC',
      value: BigInt.from(sats),
      decimals: 8,
    );
  }

  /// Reverse-swap limits in Boltz's BTC denomination.
  Future<({DenominatedAmount min, DenominatedAmount max})> getSwapInLimits({
    EthereumAddress? tokenAddress,
  }) => _logger.span('getSwapInLimits', () async {
    final pair = await getReversePair(tokenAddress: tokenAddress);
    return (
      min: _swapAmountFromSats(pair.limits.minimal.ceil()),
      max: _swapAmountFromSats(pair.limits.maximal.floor()),
    );
  });

  /// Submarine-swap limits in Boltz's BTC denomination.
  Future<({DenominatedAmount min, DenominatedAmount max})> getSwapOutLimits({
    EthereumAddress? tokenAddress,
  }) => _logger.span('getSwapOutLimits', () async {
    final pair = await getSubmarinePair(tokenAddress: tokenAddress);
    return (
      min: _swapAmountFromSats(pair.limits.minimal.ceil()),
      max: _swapAmountFromSats(pair.limits.maximal.floor()),
    );
  });

  /// Estimate reverse-swap (swap-in) fees for a given on-chain amount.
  ///
  /// Returns `null` if the reverse pair is not available for this token
  /// on the current chain (e.g. TBTC on production Boltz).
  Future<BoltzFeeEstimate?> estimateSwapInFees({
    required int onchainAmountSat,
    EthereumAddress? tokenAddress,
  }) async {
    try {
      final pair = await getReversePair(tokenAddress: tokenAddress);
      return BoltzFeeEstimate.reverseSwap(pair, onchainAmountSat);
    } catch (e) {
      _logger.w('Could not estimate swap-in fees: $e');
      return null;
    }
  }

  /// Estimate submarine-swap (swap-out) fees for a given invoice amount.
  ///
  /// Returns `null` if the submarine pair is not available for this token
  /// on the current chain.
  Future<BoltzFeeEstimate?> estimateSwapOutFees({
    required int invoiceAmountSat,
    EthereumAddress? tokenAddress,
  }) async {
    try {
      final pair = await getSubmarinePair(tokenAddress: tokenAddress);
      return BoltzFeeEstimate.submarineSwap(pair, invoiceAmountSat);
    } catch (e) {
      _logger.w('Could not estimate swap-out fees: $e');
      return null;
    }
  }

  /// Create a submarine (swap-out) swap.
  Future<SubmarineResponse> submarine({
    required String invoice,
    EthereumAddress? tokenAddress,
  }) => boltzClient.submarine(
    invoice: invoice,
    from: currencyForTokenAddress(tokenAddress),
  );

  /// Create a reverse (swap-in) swap.
  Future<ReverseResponse> reverseSubmarine({
    double? invoiceAmount,
    double? onchainAmount,
    required String preimageHash,
    required String claimAddress,
    String? description,
    EthereumAddress? tokenAddress,
  }) => boltzClient.reverseSubmarine(
    invoiceAmount: invoiceAmount,
    onchainAmount: onchainAmount,
    preimageHash: preimageHash,
    claimAddress: claimAddress,
    description: description,
    to: currencyForTokenAddress(tokenAddress),
  );

  /// Subscribe to swap status updates via WebSocket / HTTP fallback.
  Stream<SwapStatus> subscribeToSwap({
    required String id,
    int maxReconnectAttempts = 5,
  }) => boltzClient.subscribeToSwap(
    id: id,
    maxReconnectAttempts: maxReconnectAttempts,
  );

  /// Fetch current swap status.
  Future<SwapStatus> getSwap({required String id}) =>
      boltzClient.getSwap(id: id);

  /// Fetch the preimage for a completed submarine swap.
  Future<String> getSubmarinePreimage({required String id}) =>
      boltzClient.getSubmarinePreimage(id: id);

  /// Request cooperative refund EIP-712 signature from Boltz.
  Future<SwapSubmarineIdRefundGet$Response?> getCooperativeRefundSignature({
    required String id,
  }) => boltzClient.getCooperativeRefundSignature(id: id);
}
