import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:permissionless/permissionless.dart' as permissionless;
import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart' show keccak256;

import '../../../datasources/boltz/boltz_fee_estimate.dart';
import '../../../datasources/contracts/boltz/IERC20.g.dart';
import '../../../util/token_amount_ext.dart';
import '../capabilities/boltz_call_builder.dart';
import '../chain/evm_chain.dart';
import '../evm_call.dart';
import '../models/swap_quote.dart';
import 'swap_in/swap_in_models.dart';
import 'swap_out/swap_out_models.dart';

/// Unified swap quoting service — replaces the former `SwapInQuoteService`
/// and `SwapOutQuoteService` with one injectable that exposes both directions.
///
/// Follows the Boltz web app pattern: one service, two methods, same return
/// type ([SwapQuote]).
@injectable
class SwapQuoteService {
  // ═══════════════════════════════════════════════════════════════════════
  //  Swap-In (Reverse Swap: Lightning → on-chain)
  // ═══════════════════════════════════════════════════════════════════════

  /// Build a [SwapQuote] for a swap-in (reverse swap).
  ///
  /// [chain]     — EVM chain to estimate gas on.
  /// [params]    — swap-in parameters (amount, keys, optional post-claim calls).
  /// [escrowFee] — pass-through for escrow operations; zero for plain swaps.
  Future<SwapQuote> buildSwapInQuote({
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
    final isErc20 = tokenAddress != null;
    final gasComponent = isErc20
        ? TokenAmount.zero(params.amount.token)
        : TokenAmount(value: gasFee.value, token: params.amount.token);
    final totalNeeded = params.amount + gasComponent;

    final minSats = BigInt.from(pair.limits.minimal.ceil());
    final neededSats = totalNeeded.inSats;
    final resolvedSats = neededSats < minSats ? minSats : neededSats;

    final resolvedSwapAmount = TokenAmount.fromDenominated(
      DenominatedAmount(denomination: 'BTC', value: resolvedSats, decimals: 8),
      params.amount.token,
    ).roundUpToSats();

    // ── 4. Compute Boltz fees for the resolved amount ──
    final boltzEstimate = BoltzFeeEstimate.reverseSwap(
      pair,
      resolvedSwapAmount.getInSats.toInt(),
    );

    return SwapQuote(
      boltzEstimate: boltzEstimate,
      gasFee: gasFee,
      gasSponsored: gasEstimate.gasSponsored,
      escrowFee: escrowFee ?? TokenAmount.zero(params.amount.token),
      sendAmount: resolvedSwapAmount,
      receiveAmount: params.amount,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  Swap-Out (Submarine Swap: on-chain → Lightning)
  // ═══════════════════════════════════════════════════════════════════════

  /// Build a [SwapQuote] for a swap-out (submarine swap).
  ///
  /// [chain]  — EVM chain to fetch balance and estimate gas on.
  /// [params] — swap-out parameters (keys, optional requested amount).
  ///
  /// Throws [StateError] when balance is insufficient or the requested amount
  /// falls outside Boltz limits.
  Future<SwapQuote> buildSwapOutQuote({
    required EvmChain chain,
    required SwapOutParams params,
  }) async {
    final tokenAddress = params.amount?.token.isERC20 == true
        ? EthereumAddress.fromHex(params.amount!.token.address)
        : null;

    final balance =
        params.amount ?? await _getSwapBalance(chain, params, tokenAddress);
    final gasEstimate = await _estimateLockGasFee(chain, params, tokenAddress);
    final gasFee = gasEstimate.gasSponsored
        ? rbtcFromWei(BigInt.zero, chainId: chain.config.chainId)
        : rbtcFromWei(gasEstimate.gasCostWei, chainId: chain.config.chainId);

    final balanceRounded = TokenAmountEvmExt(balance).roundDownToSats();
    final gasFeeRounded = TokenAmountEvmExt(gasFee).roundUpToSats();

    final pair = await chain.swaps!.getSubmarinePair(
      tokenAddress: tokenAddress,
    );

    final minInvoice = tokenAmountFromSats(
      balance.token,
      BigInt.from(pair.limits.minimal.ceil()),
    );
    final maxInvoiceByPair = tokenAmountFromSats(
      balance.token,
      BigInt.from(pair.limits.maximal.floor()),
    );

    final percentage = pair.fees.percentage;
    final minerFeesSatsRoundedUp = pair.fees.minerFees.ceil();
    final spendableAfterGasSats =
        balanceRounded.getInSats.toDouble() -
        gasFeeRounded.getInSats.toDouble();

    if (spendableAfterGasSats <= 0) {
      throw StateError(
        'Balance ${TokenAmountEvmExt(balance).getInSats} sats is not enough to cover estimated gas '
        '${TokenAmountEvmExt(gasFee).getInSats} sats.',
      );
    }

    final denom = 1 + (percentage / 100.0);
    final maxInvoiceByBalanceSats =
        ((spendableAfterGasSats - minerFeesSatsRoundedUp) / denom).floor();

    if (maxInvoiceByBalanceSats <= 0) {
      throw StateError(
        'Balance after gas cannot cover submarine swap fees. '
        'Spendable: ${spendableAfterGasSats.floor()} sats, '
        'fixed miner fee: $minerFeesSatsRoundedUp sats.',
      );
    }

    final maxInvoiceByBalance = tokenAmountFromSats(
      balance.token,
      BigInt.from(maxInvoiceByBalanceSats),
    );
    final maxInvoice = TokenAmount.max(
      TokenAmount.zero(balance.token),
      maxInvoiceByBalance < maxInvoiceByPair
          ? maxInvoiceByBalance
          : maxInvoiceByPair,
    );

    final invoiceAmount = TokenAmountEvmExt(maxInvoice).roundDownToSats();

    if (invoiceAmount < minInvoice) {
      throw StateError(
        'Invoice amount ${TokenAmountEvmExt(invoiceAmount).getInSats} sats is below Boltz minimum '
        '${TokenAmountEvmExt(minInvoice).getInSats} sats.',
      );
    }

    final estimatedGasFee = gasFeeRounded.toDenominated().rescale(8);

    final boltzEstimate = BoltzFeeEstimate.submarineSwap(
      pair,
      TokenAmountEvmExt(invoiceAmount).getInSats.toInt(),
    );

    return SwapQuote(
      boltzEstimate: boltzEstimate,
      gasFee: TokenAmount.fromDenominated(
        estimatedGasFee,
        Token.native(balance.token.chainId),
      ),
      gasSponsored: gasEstimate.gasSponsored,
      escrowFee: TokenAmount.zero(balance.token),
      sendAmount: balanceRounded,
      receiveAmount: invoiceAmount,
    );
  }

  // ═══════════════════════════════════════════════════════════════════════
  //  Swap-In helpers (state overrides for gas estimation)
  // ═══════════════════════════════════════════════════════════════════════

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

  // ═══════════════════════════════════════════════════════════════════════
  //  Swap-Out helpers (balance + gas estimation)
  // ═══════════════════════════════════════════════════════════════════════

  Future<TokenAmount> _getSwapBalance(
    EvmChain chain,
    SwapOutParams params,
    EthereumAddress? tokenAddress,
  ) async {
    if (tokenAddress == null) {
      return chain.getBalance(params.evmKey.address);
    }
    final token = IERC20(address: tokenAddress, client: chain.client);
    final raw = await token.balanceOf((account: params.evmKey.address));
    final decimals = await chain.resolveTokenDecimals(tokenAddress.eip55With0x);
    return tokenAmountFromEvm(
      tokenAddress.eip55With0x,
      raw,
      chainId: chain.config.chainId,
      tokenDecimals: decimals,
    );
  }

  Future<({BigInt gasCostWei, bool gasSponsored})> _estimateLockGasFee(
    EvmChain chain,
    SwapOutParams params,
    EthereumAddress? tokenAddress,
  ) {
    return chain.estimateGas(
      params.evmKey,
      calls: _buildEstimationLockCalls(chain, params, tokenAddress),
    );
  }

  Map<String, Call> _buildEstimationLockCalls(
    EvmChain chain,
    SwapOutParams params,
    EthereumAddress? tokenAddress,
  ) {
    final builder = BoltzCallBuilder(chain.swaps!);
    final dummyHash = Uint8List(32);
    final dummyAddress = params.evmKey.address;
    final Map<String, Call> lockCalls;
    if (tokenAddress != null) {
      lockCalls = builder.erc20Lock(
        preimageHash: dummyHash,
        amountWei: BigInt.one,
        tokenAddress: tokenAddress,
        claimAddress: dummyAddress,
        timeoutBlockHeight: 1,
      );
    } else {
      lockCalls = {
        'EtherSwap.lock': builder.nativeLock(
          preimageHash: dummyHash,
          amountWei: BigInt.one,
          claimAddress: dummyAddress,
          timeoutBlockHeight: 1,
        ),
      };
    }
    return {...?params.preLockCalls, ...lockCalls};
  }
}
