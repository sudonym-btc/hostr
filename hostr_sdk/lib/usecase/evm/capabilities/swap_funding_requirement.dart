import 'package:models/main.dart';

import '../../../util/token_amount_ext.dart';

/// Token-aware lock-amount computation and affordability validation for
/// submarine (swap-out) swaps.
///
/// Fixes the bug where `rbtcFromSatsInt` was used for all swaps — including
/// ERC-20 tokens — producing an RBTC TokenAmount that could never match the
/// actual token balance.
///
/// Usage:
/// ```dart
/// final req = SwapFundingRequirement.fromBoltzExpectedAmount(
///   expectedAmountSat: swap.expectedAmount.ceil(),
///   fundingToken: quote.balance.token,
///   balance: quote.balance,
///   gasFee: gasFee,
/// );
/// req.validate(); // throws StateError if insufficient balance
/// ```
class SwapFundingRequirement {
  /// The lock amount expressed in the correct funding token.
  final TokenAmount lockAmount;

  /// The gas fee (always in the chain's native token).
  final TokenAmount gasFee;

  /// The user's balance in the funding token.
  final TokenAmount balance;

  const SwapFundingRequirement({
    required this.lockAmount,
    required this.gasFee,
    required this.balance,
  });

  /// Build from Boltz's sats-denominated `expectedAmount`.
  ///
  /// [fundingToken] is the actual on-chain token being locked (native or
  /// ERC-20). For native tokens the lock amount is sats → wei (×10^10).
  /// For ERC-20 tokens the scaling respects the token's decimals.
  factory SwapFundingRequirement.fromBoltzExpectedAmount({
    required int expectedAmountSat,
    required Token fundingToken,
    required TokenAmount balance,
    required TokenAmount gasFee,
  }) {
    // Scale from 8-decimal sats to the token's native precision.
    final sats = BigInt.from(expectedAmountSat);
    final scaleFactor = fundingToken.decimals - 8;
    final rawValue = scaleFactor > 0
        ? sats * BigInt.from(10).pow(scaleFactor)
        : sats;

    final lockAmount = TokenAmount(
      value: rawValue,
      token: fundingToken,
    ).roundUpToSats();

    return SwapFundingRequirement(
      lockAmount: lockAmount,
      gasFee: gasFee,
      balance: balance,
    );
  }

  /// The lock amount in wei for use in contract calls.
  BigInt get lockAmountWei => lockAmount.getInWei;

  /// Whether the funding token is an ERC-20 (not the chain's native asset).
  bool get isErc20 => lockAmount.token.isERC20;

  /// Validate that the user's balance covers the lock amount (and gas for
  /// native swaps).
  ///
  /// For **native** swaps: `lockAmount + gasFee ≤ balance` (same token).
  /// For **ERC-20** swaps: `lockAmount ≤ balance` (gas is in native token,
  /// validated separately or covered by a paymaster).
  ///
  /// Throws [StateError] with a detailed message on failure.
  void validate() {
    final lockRounded = lockAmount.roundUpToSats();
    final balRounded = balance.roundDownToSats();

    if (isErc20) {
      // ERC-20: lock amount must fit within the token balance.
      // Gas is in native token — checked separately or sponsored.
      if (lockRounded > balRounded) {
        throw StateError(
          'Insufficient ${lockAmount.token.tagId} balance to lock swap. '
          'Need ${lockRounded.getInSats} sats '
          '(${lockRounded.getInWei} smallest-unit), '
          'have ${balRounded.getInSats} sats '
          '(${balRounded.getInWei} smallest-unit).',
        );
      }
    } else {
      // Native: lock + gas must fit within the same balance.
      final gasRounded = TokenAmount(
        value: gasFee.getInWei,
        token: lockAmount.token,
      ).roundUpToSats();
      final totalRequired = lockRounded + gasRounded;

      if (totalRequired > balRounded) {
        throw StateError(
          'Insufficient balance to lock swap. '
          'Need ${lockRounded.getInSats} sats + '
          '${gasRounded.getInSats} sats gas, '
          'total of ${totalRequired.getInSats} sats, '
          'have ${balRounded.getInSats} sats.',
        );
      }
    }
  }
}
