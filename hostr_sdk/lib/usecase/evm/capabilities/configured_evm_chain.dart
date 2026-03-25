import '../../../util/custom_logger.dart';
import '../../auth/auth.dart';
import '../../nwc/nwc.dart';
import '../../payments/payments.dart';
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
