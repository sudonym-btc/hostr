import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart' show EthPrivateKey, Transaction;

import '../../../util/custom_logger.dart';
import '../../auth/auth.dart';
import '../../nwc/nwc.dart';
import '../../payments/payments.dart';
import '../call_intent.dart';
import '../chain/evm_chain.dart';
import '../chain/operations/swap_in/swap_in_operation.dart';
import '../chain/operations/swap_out/swap_out_operation.dart';
import '../config/evm_config.dart';
import '../operations/swap_in/swap_in_models.dart';
import '../operations/swap_in/swap_in_operation.dart' show SwapInOperation;
import '../operations/swap_out/swap_out_models.dart';
import '../operations/swap_out/swap_out_quote_service.dart';
import '../operations/swap_out/swap_out_state.dart';
import 'aa_capability.dart';
import 'boltz_swap_provider.dart';
import 'escrow_capability.dart';

/// Fully assembled EVM chain with all discovered/configured capabilities.
///
/// This is the main entry point that the rest of the SDK interacts with.
/// An [EvmChain] is the transport layer; capabilities are attached based
/// on what the deployment config + Boltz discovery indicate.
class ConfiguredEvmChain {
  /// The underlying EVM transport (RPC, blocks, balances, HD keys).
  final EvmChain chain;

  /// The per-chain config this was built from.
  EvmChainConfig get config => chain.config;

  /// ERC-4337 Account Abstraction — `null` if the chain has no AA config.
  final AACapability? aa;

  /// Boltz swap provider — `null` if Boltz doesn't support this chain.
  final BoltzSwapProvider? swaps;

  /// Escrow contract lookup — always present.
  final EscrowCapability escrow;

  ConfiguredEvmChain({
    required this.chain,
    this.aa,
    this.swaps,
    required this.escrow,
  });

  /// Whether this chain uses ERC-4337 Account Abstraction.
  bool get hasAA => aa != null;

  // ── Account address resolution ────────────────────────────────────

  /// Returns the address that should receive funds on this chain.
  ///
  /// When AA is configured, this is the counterfactual smart-account
  /// address. Otherwise it is the plain EOA address derived from the key.
  Future<EthereumAddress> getAccountAddress(EthPrivateKey signer) async {
    if (aa != null) {
      return aa!.getSmartAccountAddress(signer);
    }
    return signer.address;
  }

  // ── Transaction sending ───────────────────────────────────────────

  /// Send one or more [CallIntent]s as a single atomic operation.
  ///
  /// When AA is configured, the intents are batched into a single
  /// UserOperation. Otherwise each intent is sent as a plain EOA
  /// transaction (sequentially).
  ///
  /// Returns the on-chain transaction hash.
  Future<String> sendCalls(
    EthPrivateKey signer,
    List<CallIntent> intents,
  ) async {
    if (aa != null) {
      return aa!.sendUserOp(signer, intents);
    }
    return _sendEoaCalls(signer, intents);
  }

  // ── Gas estimation ────────────────────────────────────────────────

  /// Estimate gas fee for the given call intents (or a baseline if omitted).
  ///
  /// Delegates to AA when available; otherwise uses `eth_estimateGas`.
  Future<({BigInt gasCostWei, bool gasSponsored})> estimateGas(
    EthPrivateKey signer, {
    List<CallIntent>? intents,
  }) async {
    if (aa != null) {
      return aa!.estimateGasFee(signer, intents: intents);
    }
    return _estimateEoaGas(signer, intents: intents);
  }

  // ── EOA internals ─────────────────────────────────────────────────

  Future<String> _sendEoaCalls(
    EthPrivateKey signer,
    List<CallIntent> intents,
  ) async {
    String? lastTxHash;
    for (final intent in intents) {
      final estimatedGas = await chain.client.estimateGas(
        sender: signer.address,
        to: intent.to,
        value: intent.value,
        data: intent.data,
      );
      final bufferedGas =
          (estimatedGas * BigInt.from(12) ~/ BigInt.from(10)) +
          BigInt.from(10000);
      final txHash = await chain.client.sendTransaction(
        signer,
        Transaction(
          from: signer.address,
          to: intent.to,
          value: intent.value,
          data: intent.data,
          maxGas: bufferedGas.toInt(),
        ),
        chainId: config.chainId,
      );
      lastTxHash = txHash;
    }
    return lastTxHash!;
  }

  Future<({BigInt gasCostWei, bool gasSponsored})> _estimateEoaGas(
    EthPrivateKey signer, {
    List<CallIntent>? intents,
  }) async {
    if (intents == null || intents.isEmpty) {
      // Baseline estimate for contract interactions when the exact calldata is
      // not known yet (for example during swap-out quoting before Boltz has
      // returned the concrete lock parameters).
      final gasPrice = await chain.client.getGasPrice();
      return (
        gasCostWei: BigInt.from(150000) * gasPrice.getInWei,
        gasSponsored: false,
      );
    }

    BigInt totalGas = BigInt.zero;
    final gasPrice = await chain.client.getGasPrice();
    for (final intent in intents) {
      final gas = await chain.client.estimateGas(
        sender: signer.address,
        to: intent.to,
        value: intent.value,
        data: intent.data,
      );
      totalGas += gas;
    }
    return (gasCostWei: totalGas * gasPrice.getInWei, gasSponsored: false);
  }

  // ── Swap factories ──────────────────────────────────────────────────

  /// Create a swap-in (reverse submarine swap) operation for this chain.
  SwapInOperation swapIn({
    required SwapInParams params,
    required Auth auth,
    required CustomLogger logger,
  }) {
    return EvmSwapInOperation(
      configuredChain: this,
      auth: auth,
      logger: logger,
      params: params,
    );
  }

  /// Create a swap-out (submarine swap) operation for this chain.
  EvmSwapOutOperation swapOut({
    required SwapOutParams params,
    required Auth auth,
    required CustomLogger logger,
    required Nwc nwc,
    required Payments payments,
    required SwapOutQuoteService quoteService,
    SwapOutState? initialState,
  }) {
    return EvmSwapOutOperation(
      configuredChain: this,
      auth: auth,
      logger: logger,
      nwc: nwc,
      payments: payments,
      quoteService: quoteService,
      params: params,
      initialState: initialState,
    );
  }
}
