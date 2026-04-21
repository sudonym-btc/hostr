import 'package:models/main.dart';
import 'package:permissionless/permissionless.dart' as permissionless;
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';

import '../../evm_call.dart';
import '../../models/amount_spec.dart';

/// Input-side buffer applied to DEX-assisted swap-ins.
///
/// For a Lightning -> bridge-token -> DEX -> requested-token flow, the DEX
/// calldata still enforces the requested output as `amountOutMin`; this buffer
/// only asks Boltz to deliver a little more bridge token so the DEX leg has room
/// for small quote movement or satoshi rounding.
class SwapInDexBuffer {
  static const standard = SwapInDexBuffer(basisPoints: 10, minSats: 2);
  static const zero = SwapInDexBuffer(basisPoints: 0, minSats: 0);

  /// Percentage buffer in basis points. 10 bps = 0.1%.
  final int basisPoints;

  /// Minimum buffer in satoshis of the Boltz bridge token.
  final int minSats;

  const SwapInDexBuffer({required this.basisPoints, required this.minSats})
    : assert(basisPoints >= 0),
      assert(minSats >= 0);

  bool get isZero => basisPoints == 0 && minSats == 0;

  BigInt applyToSats(BigInt baseSats) {
    if (isZero || baseSats <= BigInt.zero) return baseSats;

    final percentage = _ceilDiv(
      baseSats * BigInt.from(basisPoints),
      BigInt.from(10000),
    );
    final minimum = BigInt.from(minSats);
    final buffer = percentage > minimum ? percentage : minimum;
    return baseSats + buffer;
  }

  static BigInt _ceilDiv(BigInt numerator, BigInt denominator) {
    if (numerator == BigInt.zero) return BigInt.zero;
    return ((numerator - BigInt.one) ~/ denominator) + BigInt.one;
  }
}

class SwapInParams {
  final EthPrivateKey evmKey;
  final int accountIndex;

  /// Declares which side of the swap the user-specified amount refers to.
  ///
  /// - [AmountSide.output] — "deliver exactly X on-chain" (e.g. escrow fund).
  ///   Boltz API receives `onchainAmount`.
  /// - [AmountSide.input] — "spend exactly X from Lightning".
  ///   Boltz API receives `invoiceAmount`.
  final AmountSpec amountSpec;

  /// Working amount — initialised from [amountSpec.amount].
  ///
  /// [SwapQuoteService.buildSwapInQuote] may mutate this to the bridge-token
  /// equivalent when a DEX hop is needed (e.g. USDT → tBTC).
  TokenAmount amount;

  TokenAmount? minAmount;
  TokenAmount? maxAmount;
  final String? invoiceDescription;
  final EthereumAddress? claimAddress;
  final EthereumAddress? claimDestination;

  /// When this swap is nested inside a parent operation (e.g. escrow-fund),
  /// set this to the parent's operation ID so that progress notifications
  /// update the same OS notification as the parent.
  final String? parentOperationId;

  /// Additional calls to append after the claim call, broadcast atomically
  /// as a single UserOperation.
  ///
  /// For escrow-fund this holds the `{approve?, createTrade}` calls so that
  /// `[claim, ...postClaimCalls]` executes in one UserOp. The calls are
  /// persisted on [SwapInData] so recovery is automatic — no callback
  /// reconstruction needed.
  ///
  /// Non-final so that [SwapQuoteService] can prepend DEX swap calls when
  /// the requested token is not Boltz-supported (e.g. USDT).
  Map<String, Call>? postClaimCalls;

  /// Buffer applied to the DEX input for non-bridge-token swap-ins.
  ///
  /// Defaults to `max(0.1%, 2 sats)` of the bridge-token input. Tests and
  /// flows that require exact zero dust can pass [SwapInDexBuffer.zero].
  final SwapInDexBuffer dexInputBuffer;

  /// ERC-4337 state overrides applied when estimating gas for the
  /// `[claim, ...postClaimCalls]` UserOperation.
  ///
  /// The representative claim call and fund calls reference token balances
  /// and allowances that don't exist yet (the Boltz lockup hasn't happened
  /// and the smart account has no tokens). These overrides fake enough
  /// balance/allowance so the bundler simulation succeeds.
  final List<permissionless.StateOverride>? postClaimStateOverrides;

  SwapInParams({
    required this.evmKey,
    required this.accountIndex,
    required this.amountSpec,
    this.minAmount,
    this.maxAmount,
    this.invoiceDescription,
    this.claimAddress,
    this.claimDestination,
    this.parentOperationId,
    this.postClaimCalls,
    this.dexInputBuffer = SwapInDexBuffer.standard,
    this.postClaimStateOverrides,
  }) : amount = amountSpec.amount;
}
