import 'package:models/main.dart';
import 'package:wallet/wallet.dart' show EthereumAddress;

import '../../../../util/custom_logger.dart';
import '../../../../util/token_amount_ext.dart';
import '../../../auth/auth.dart';
import '../../../evm/main.dart';
import '../../../nwc/nwc.dart';
import '../../../payments/payments.dart';
import '../../../trade_account_allocator/trade_account_allocator.dart';
import '../../supported_escrow_contract/supported_escrow_contract.dart';
import 'escrow_withdraw_models.dart';

/// Thin orchestrator that wires an escrow withdraw into a [SwapOutOperation].
///
/// This is **not** a state machine or an [OnchainOperation]. It is a factory
/// that:
/// 1. Resolves the HD account, reads the pending withdrawal amount.
/// 2. Builds the escrow `withdraw` [Call].
/// 3. Creates a [SwapOutOperation] with `preLockCalls` containing the
///    withdraw call. The swap merges these before the Boltz lock calls,
///    broadcasting everything as a single atomic UserOperation.
///
/// Once [prepare] returns, the caller owns the [SwapOutOperation] and drives
/// it (`execute()`, `stream`, etc.). The escrow withdraw operation has no
/// further role — no persistence, no recovery, no state machine.
class EscrowWithdrawOperation {
  final Auth auth;
  final TradeAccountAllocator tradeAccountAllocator;
  final Evm evm;
  final Nwc nwc;
  final Payments payments;
  final SwapQuoteService quoteService;
  final CustomLogger logger;
  final EscrowWithdrawParams params;

  EscrowWithdrawOperation({
    required this.auth,
    required this.tradeAccountAllocator,
    required this.evm,
    required this.nwc,
    required this.payments,
    required this.quoteService,
    required this.logger,
    required this.params,
  });

  /// Resolve account, read pending amount, and build a pre-wired
  /// [SwapOutOperation] that atomically withdraws from escrow and locks
  /// into the Boltz submarine swap contract.
  ///
  /// Returns the swap-out operation ready to be driven by the caller.
  /// Throws if no pending withdrawal exists.
  Future<SwapOutOperation> prepare() => logger.span(
    'EscrowWithdrawOperation.prepare',
    () async {
      final configuredChain = evm.getChainForEscrowService(
        params.escrowService,
      );
      final contract = configuredChain.escrow.getSupportedEscrowContract(
        params.escrowService,
      );

      // ── Resolve HD account ──
      final accountIndex = 0;
      final evmKey = await auth.hd.getActiveEvmKey(accountIndex: accountIndex);
      final beneficiary = EthereumAddress.fromHex(params.beneficiaryEvmAddress);
      final smartWallet = await configuredChain.getAccountAddress(evmKey);

      // ── Read pending balance for the native token ──
      final nativeToken = EthereumAddress.fromHex(
        '0x0000000000000000000000000000000000000000',
      );
      final pendingAmountWei = await contract.balanceOf(
        beneficiary: beneficiary,
        token: nativeToken,
      );
      if (pendingAmountWei <= BigInt.zero) {
        throw StateError(
          'No pending withdrawal for '
          'beneficiary ${beneficiary.eip55With0x}',
        );
      }

      // ── Resolve withdrawn amount as TokenAmount ──
      // Use the bridge token — the escrow contract always holds the Boltz
      // ERC-20 (or native), regardless of listing denomination.
      final escrowToken = await configuredChain.resolveBridgeToken();
      final withdrawAmount = TokenAmount(
        value: pendingAmountWei,
        token: escrowToken,
      );

      logger.i(
        'EscrowWithdraw: pending=$pendingAmountWei '
        '(${withdrawAmount.getInSats} sats) for '
        'beneficiary ${beneficiary.eip55With0x}',
      );

      // ── Build the escrow withdraw intent ──
      final withdrawIntent = contract.withdraw(
        WithdrawArgs(
          token: nativeToken,
          ethKey: evmKey,
          beneficiary: beneficiary,
          destination: smartWallet,
        ),
      );

      // ── Create swap-out with preLockCalls ──
      return configuredChain.swapOut(
        auth: auth,
        logger: logger,
        nwc: nwc,
        payments: payments,
        quoteService: quoteService,
        params: SwapOutParams(
          evmKey: evmKey,
          accountIndex: accountIndex,
          amount: withdrawAmount,
          preLockCalls: {'withdraw': withdrawIntent},
        ),
      );
    },
  );
}
