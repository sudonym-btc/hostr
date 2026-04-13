import 'package:models/main.dart';
import 'package:permissionless/permissionless.dart' as permissionless;
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';

import '../../evm_call.dart';

class SwapInParams {
  final EthPrivateKey evmKey;
  final int accountIndex;
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
    required this.amount,
    this.minAmount,
    this.maxAmount,
    this.invoiceDescription,
    this.claimAddress,
    this.claimDestination,
    this.parentOperationId,
    this.postClaimCalls,
    this.postClaimStateOverrides,
  });
}
