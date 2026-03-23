import 'package:models/main.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;

import '../../../datasources/boltz/boltz.dart';
import '../../../datasources/boltz/boltz_chain_info.dart';
import '../../../datasources/contracts/boltz/ERC20Swap.g.dart';
import '../../../datasources/contracts/boltz/EtherSwap.g.dart';
import '../../../datasources/swagger_generated/boltz.swagger.dart';
import '../../../util/custom_logger.dart';
import '../../../util/token_amount_ext.dart';
import '../chain/evm_chain.dart';

/// Per-chain Boltz swap capability.
///
/// Wraps a [BoltzClient] + discovered [BoltzChainInfo] so callers don't
/// need to know about currency strings or contract addresses.
class BoltzSwapProvider {
  final BoltzClient boltzClient;
  final BoltzChainInfo chainInfo;
  final EvmChain chain;
  final CustomLogger _logger;

  BoltzSwapProvider({
    required this.boltzClient,
    required this.chainInfo,
    required this.chain,
    required CustomLogger logger,
  }) : _logger = logger;

  /// The Boltz currency string for the native asset on this chain
  /// (e.g. 'RBTC', 'arbitrumETH').
  String get currency => chainInfo.currency;

  /// Whether this chain's swap currency is an ERC-20 token (vs native asset).
  bool get isErc20 => chainInfo.tokens.containsKey(chainInfo.currency);

  /// The ERC-20 token address for swap operations, or null for native.
  EthereumAddress? get tokenAddress => chainInfo.tokens[chainInfo.currency];

  /// Live [EtherSwap] contract on this chain.
  EtherSwap getEtherSwapContract() =>
      EtherSwap(address: chainInfo.etherSwap, client: chain.client);

  /// Live [ERC20Swap] contract on this chain.
  ERC20Swap getERC20SwapContract() =>
      ERC20Swap(address: chainInfo.erc20Swap, client: chain.client);

  /// Fetch reverse-swap pair info for this chain's currency.
  Future<ReversePair> getReversePair() =>
      boltzClient.getReversePair(from: 'BTC', to: currency);

  /// Fetch submarine-swap pair info for this chain's currency.
  Future<SubmarinePair> getSubmarinePair() =>
      boltzClient.getSubmarinePair(from: currency, to: 'BTC');

  /// Reverse-swap limits (in the chain's native token denomination).
  Future<({TokenAmount min, TokenAmount max})> getSwapInLimits() =>
      _logger.span('getSwapInLimits', () async {
        final pair = await getReversePair();
        return (
          min: rbtcFromSatsInt(pair.limits.minimal.ceil()),
          max: rbtcFromSatsInt(pair.limits.maximal.floor()),
        );
      });

  /// Submarine-swap limits.
  Future<({TokenAmount min, TokenAmount max})> getSwapOutLimits() =>
      _logger.span('getSwapOutLimits', () async {
        final pair = await getSubmarinePair();
        return (
          min: rbtcFromSatsInt(pair.limits.minimal.ceil()),
          max: rbtcFromSatsInt(pair.limits.maximal.floor()),
        );
      });

  /// Compute the Lightning invoice amount needed so that after Boltz fees
  /// the recipient receives at least [desiredOnchainAmount].
  Future<({TokenAmount invoiceAmount, TokenAmount feeOverhead})>
  computeInvoiceForDesiredOnchain({
    required TokenAmount desiredOnchainAmount,
  }) => boltzClient.computeInvoiceForDesiredOnchain(
    desiredOnchainAmount: desiredOnchainAmount,
    from: 'BTC',
    to: currency,
  );

  /// Create a submarine (swap-out) swap.
  Future<SubmarineResponse> submarine({required String invoice}) =>
      boltzClient.submarine(invoice: invoice, from: currency);

  /// Create a reverse (swap-in) swap.
  Future<ReverseResponse> reverseSubmarine({
    required double invoiceAmount,
    required String preimageHash,
    required String claimAddress,
    String? description,
  }) => boltzClient.reverseSubmarine(
    invoiceAmount: invoiceAmount,
    preimageHash: preimageHash,
    claimAddress: claimAddress,
    description: description,
    to: currency,
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

  /// Request cooperative refund EIP-712 signature from Boltz.
  Future<SwapSubmarineIdRefundGet$Response?> getCooperativeRefundSignature({
    required String id,
  }) => boltzClient.getCooperativeRefundSignature(id: id);

  /// Fetch Boltz contracts for this chain's currency.
  Future<Contracts> contracts() => _logger.span('contracts', () async {
    final res = await boltzClient.gBoltzCli.chainCurrencyContractsGet(
      currency: currency,
    );
    if (res.isSuccessful) return res.body!;
    throw res.error!;
  });
}
