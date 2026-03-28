import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:permissionless/permissionless.dart' as permissionless;
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart' show keccak256;

import '../../../../datasources/boltz/boltz_fee_estimate.dart';
import '../../../../util/token_amount_ext.dart';
import '../../capabilities/boltz_call_builder.dart';
import '../../chain/evm_chain.dart';
import '../../models/fee_breakdown.dart';
import 'swap_in_models.dart';

/// Immutable quote describing a swap-in (Lightning → on-chain).
///
/// Produced by [SwapInQuoteService.buildQuote] from gas estimation and a
/// single Boltz pair fetch. Carries all fee line-items plus the resolved
/// swap amount that the swap should be created with.
class SwapInQuote {
  /// Boltz fee estimate (limits + per-swap fee), from one pair fetch.
  final BoltzFeeEstimate boltzEstimate;

  /// EVM gas cost in native token (e.g. RBTC), even when sponsored.
  final TokenAmount gasFee;

  /// Whether the gas fee is covered by a paymaster.
  final bool gasSponsored;

  /// Escrow operator fee (zero for plain swaps).
  final TokenAmount escrowFee;

  /// The swap amount that should be requested from Boltz.
  ///
  /// `max(boltzMin, fundingAmount + gasComponentIfNative)`, rounded to sats.
  final TokenAmount resolvedSwapAmount;

  const SwapInQuote({
    required this.boltzEstimate,
    required this.gasFee,
    required this.gasSponsored,
    required this.escrowFee,
    required this.resolvedSwapAmount,
  });

  /// Boltz swap fee as a [DenominatedAmount] in BTC denomination.
  DenominatedAmount get swapFee => boltzEstimate.feesAsDenominated;

  /// Boltz swap limits as [TokenAmount] in the swap token.
  ({TokenAmount min, TokenAmount max}) limitsIn(Token token) => (
    min: TokenAmount.fromDenominated(boltzEstimate.limitsMin, token),
    max: TokenAmount.fromDenominated(boltzEstimate.limitsMax, token),
  );

  /// Unified fee breakdown for UI display.
  FeeBreakdown get feeBreakdown => FeeBreakdown(
    escrowFee: escrowFee,
    swapFee: swapFee,
    gasFee: gasFee,
    gasSponsored: gasSponsored,
  );
}

/// Stateless service that builds [SwapInQuote]s.
///
/// Owns gas estimation for the full `[claim, ...postClaimCalls]` call
/// sequence, including Boltz lockup storage mocking and Boltz pair maths.
/// Accepts the same [EvmChain] + [SwapInParams] that the swap operation
/// uses, so callers get fee quotes without executing the swap.
@injectable
class SwapInQuoteService {
  /// Build a [SwapInQuote] for the given chain and swap params.
  ///
  /// [chain]     — EVM chain to estimate gas on.
  /// [params]    — swap-in parameters (amount, keys, optional post-claim calls).
  /// [escrowFee] — pass-through for escrow operations; zero for plain swaps.
  Future<SwapInQuote> buildQuote({
    required EvmChain chain,
    required SwapInParams params,
    TokenAmount? escrowFee,
  }) async {
    final tokenAddress = params.amount.token.isERC20
        ? EthereumAddress.fromHex(params.amount.token.address)
        : null;

    // ── 1. Estimate gas for claim + post-claim calls ──
    final builder = BoltzCallBuilder(chain.swaps!);
    final dummyPreimage = Uint8List(32);
    final stateOverrides = await _buildClaimEstimationStateOverrides(
      chain: chain,
      params: params,
      preimage: dummyPreimage,
    );
    final dummyClaim = builder.claim(
      preimage: dummyPreimage,
      amount: params.amount.value,
      refundAddress: params.evmKey.address,
      timelock: BigInt.zero,
      tokenAddress: tokenAddress,
    );
    final estimationCalls = {'claim': dummyClaim, ...?params.postClaimCalls};
    final gasEstimate = await chain.estimateGas(
      params.evmKey,
      calls: estimationCalls,
      stateOverride: stateOverrides,
    );

    final chainId = params.amount.token.chainId;
    final nativeToken = Token.native(chainId);
    final gasFee = TokenAmount(
      value: gasEstimate.gasCostWei,
      token: nativeToken,
    );

    // ── 2. Single Boltz pair fetch → limits + fee rates ──
    final pair = await chain.swaps!.getReversePair(tokenAddress: tokenAddress);

    // ── 3. Compute resolved swap amount ──
    // For ERC-20 tokens gas is paid separately (in native RBTC), so the
    // gas component is zero. For native-token swaps the gas must come from
    // the same amount.
    final isErc20 = tokenAddress != null;
    final gasComponent = isErc20
        ? TokenAmount.zero(params.amount.token)
        : TokenAmount(value: gasFee.value, token: params.amount.token);
    final totalNeeded = params.amount + gasComponent;

    final minSats = BigInt.from(pair.limits.minimal.ceil());
    final neededSats = totalNeeded.inSats;
    final resolvedSats = neededSats < minSats ? minSats : neededSats;

    // Convert back from sats to token units (sats are 8-decimal BTC).
    final resolvedSwapAmount = TokenAmount.fromDenominated(
      DenominatedAmount(denomination: 'BTC', value: resolvedSats, decimals: 8),
      params.amount.token,
    ).roundUpToSats();

    // ── 4. Compute Boltz fees for the resolved amount ──
    final boltzEstimate = BoltzFeeEstimate.reverseSwap(
      pair,
      resolvedSwapAmount.getInSats.toInt(),
    );

    return SwapInQuote(
      boltzEstimate: boltzEstimate,
      gasFee: gasFee,
      gasSponsored: gasEstimate.gasSponsored,
      escrowFee: escrowFee ?? TokenAmount.zero(params.amount.token),
      resolvedSwapAmount: resolvedSwapAmount,
    );
  }

  // ── State override helpers (moved from EvmSwapInOperation) ──────────

  Future<List<permissionless.StateOverride>?>
  _buildClaimEstimationStateOverrides({
    required EvmChain chain,
    required SwapInParams params,
    required Uint8List preimage,
  }) async {
    final claimAddress =
        params.claimAddress ?? await chain.getAccountAddress(params.evmKey);
    final tokenAddress = params.amount.token.isERC20
        ? EthereumAddress.fromHex(params.amount.token.address)
        : null;
    final swapContractAddress = tokenAddress != null
        ? chain.swaps!.getERC20SwapContract().self.address
        : chain.swaps!.getEtherSwapContract().self.address;

    final swapHash = _computeClaimSwapHash(
      preimage: preimage,
      amount: params.amount.value,
      claimAddress: claimAddress,
      refundAddress: params.evmKey.address,
      timelock: BigInt.zero,
      tokenAddress: tokenAddress,
    );
    final lockupSlot = _computeMappingSlot(
      permissionless.Hex.fromBytes(swapHash),
      BigInt.zero,
    );

    final lockupOverride = permissionless.StateOverride(
      address: swapContractAddress,
      stateDiff: [
        permissionless.StateDiff(
          slot: lockupSlot,
          value: permissionless.Hex.fromBigInt(BigInt.one, byteLength: 32),
        ),
      ],
    );

    final lockedFundsOverride = tokenAddress != null
        ? _buildErc20SwapBalanceOverride(
            chain,
            tokenAddress,
            swapContractAddress,
            params,
          )
        : [
            permissionless.StateOverride(
              address: swapContractAddress,
              balance: params.amount.value,
            ),
          ];

    return permissionless.mergeStateOverrides([
      ...?params.postClaimStateOverrides,
      lockupOverride,
      ...lockedFundsOverride,
    ]);
  }

  List<permissionless.StateOverride> _buildErc20SwapBalanceOverride(
    EvmChain chain,
    EthereumAddress tokenAddress,
    EthereumAddress swapContractAddress,
    SwapInParams params,
  ) {
    final tokenConfig = chain.config.tokenByAddress(
      params.amount.token.address,
    );
    final balanceSlot = BigInt.from(tokenConfig?.balanceStorageSlot ?? 0);
    return permissionless.erc20BalanceOverride(
      token: tokenAddress,
      owner: swapContractAddress,
      slot: balanceSlot,
      balance: params.amount.value,
    );
  }

  Uint8List _computeClaimSwapHash({
    required Uint8List preimage,
    required BigInt amount,
    required EthereumAddress claimAddress,
    required EthereumAddress refundAddress,
    required BigInt timelock,
    EthereumAddress? tokenAddress,
  }) {
    final preimageHash = sha256.convert(preimage).bytes;
    final encoded = permissionless.Hex.concat([
      permissionless.Hex.fromBytes(Uint8List.fromList(preimageHash)),
      permissionless.AbiEncoder.encodeUint256(amount),
      if (tokenAddress != null)
        permissionless.AbiEncoder.encodeAddress(tokenAddress),
      permissionless.AbiEncoder.encodeAddress(claimAddress),
      permissionless.AbiEncoder.encodeAddress(refundAddress),
      permissionless.AbiEncoder.encodeUint256(timelock),
    ]);
    return keccak256(permissionless.Hex.decode(encoded));
  }

  String _computeMappingSlot(String key, BigInt slot) {
    final encoded = permissionless.Hex.concat([
      key,
      permissionless.AbiEncoder.encodeUint256(slot),
    ]);
    return permissionless.Hex.fromBytes(
      keccak256(permissionless.Hex.decode(encoded)),
    );
  }
}
