import 'dart:typed_data';

import 'package:wallet/wallet.dart' show EtherAmount, EthereumAddress;

import '../../../datasources/contracts/boltz/IERC20.g.dart';
import '../../../util/evm_signature.dart';
import '../call_intent.dart';
import 'boltz_swap_provider.dart';

/// Builds [CallIntent]s for Boltz swap contract interactions.
///
/// Centralises all ABI-level encoding so operation classes can focus on
/// orchestration. Every method returns one or more [CallIntent]s — the
/// caller decides how to broadcast them (AA batched or EOA sequential).
class BoltzIntentBuilder {
  final BoltzSwapProvider swaps;

  const BoltzIntentBuilder(this.swaps);

  // ── Lock ────────────────────────────────────────────────────────────

  /// Build a native EtherSwap.lock intent (payable).
  CallIntent nativeLock({
    required Uint8List preimageHash,
    required BigInt amountWei,
    required EthereumAddress claimAddress,
    required int timeoutBlockHeight,
  }) {
    final contract = swaps.getEtherSwapContract();
    final lockFn = contract.self.abi.functions.firstWhere(
      (f) => f.name == 'lock' && f.parameters.length == 3,
    );
    return CallIntent(
      to: contract.self.address,
      data: lockFn.encodeCall([
        preimageHash,
        claimAddress,
        BigInt.from(timeoutBlockHeight),
      ]),
      value: EtherAmount.inWei(amountWei),
      methodName: 'EtherSwap.lock',
    );
  }

  /// Build ERC-20 approve + ERC20Swap.lock intents.
  List<CallIntent> erc20Lock({
    required Uint8List preimageHash,
    required BigInt amountWei,
    required EthereumAddress tokenAddress,
    required EthereumAddress claimAddress,
    required int timeoutBlockHeight,
  }) {
    final erc20Swap = swaps.getERC20SwapContract();

    final approveIntent = erc20Approve(
      tokenAddress: tokenAddress,
      spender: erc20Swap.self.address,
      amount: amountWei,
    );

    final lockFn = erc20Swap.self.abi.functions.firstWhere(
      (f) => f.name == 'lock' && f.parameters.length == 5,
    );
    final lockIntent = CallIntent(
      to: erc20Swap.self.address,
      data: lockFn.encodeCall([
        preimageHash,
        amountWei,
        tokenAddress,
        claimAddress,
        BigInt.from(timeoutBlockHeight),
      ]),
      value: EtherAmount.zero(),
      methodName: 'ERC20Swap.lock',
    );

    return [approveIntent, lockIntent];
  }

  // ── Claim ───────────────────────────────────────────────────────────

  /// Build a native EtherSwap.claim intent.
  CallIntent nativeClaim({
    required Uint8List preimage,
    required BigInt amount,
    required EthereumAddress refundAddress,
    required BigInt timelock,
  }) {
    final contract = swaps.getEtherSwapContract();
    final claimFn = contract.self.abi.functions.firstWhere(
      (f) => f.name == 'claim' && f.parameters.length == 4,
    );
    return CallIntent(
      to: contract.self.address,
      data: claimFn.encodeCall([preimage, amount, refundAddress, timelock]),
      value: EtherAmount.zero(),
      methodName: 'EtherSwap.claim',
    );
  }

  /// Build an ERC20Swap.claim intent.
  CallIntent erc20Claim({
    required Uint8List preimage,
    required BigInt amount,
    required EthereumAddress tokenAddress,
    required EthereumAddress refundAddress,
    required BigInt timelock,
  }) {
    final contract = swaps.getERC20SwapContract();
    final claimFn = contract.self.abi.functions.firstWhere(
      (f) => f.name == 'claim' && f.parameters.length == 5,
    );
    return CallIntent(
      to: contract.self.address,
      data: claimFn.encodeCall([
        preimage,
        amount,
        tokenAddress,
        refundAddress,
        timelock,
      ]),
      value: EtherAmount.zero(),
      methodName: 'ERC20Swap.claim',
    );
  }

  /// Build a claim intent for either native or ERC-20.
  CallIntent claimIntent({
    required Uint8List preimage,
    required BigInt amount,
    required EthereumAddress refundAddress,
    required BigInt timelock,
    EthereumAddress? tokenAddress,
  }) {
    if (tokenAddress != null) {
      return erc20Claim(
        preimage: preimage,
        amount: amount,
        tokenAddress: tokenAddress,
        refundAddress: refundAddress,
        timelock: timelock,
      );
    }
    return nativeClaim(
      preimage: preimage,
      amount: amount,
      refundAddress: refundAddress,
      timelock: timelock,
    );
  }

  // ── Refund ──────────────────────────────────────────────────────────

  /// Build a native EtherSwap.refund intent (timelock-based).
  CallIntent nativeRefund({
    required Uint8List preimageHash,
    required BigInt amountWei,
    required EthereumAddress claimAddress,
    required int timeoutBlockHeight,
  }) {
    final contract = swaps.getEtherSwapContract();
    final refundFn = contract.self.abi.functions.firstWhere(
      (f) => f.name == 'refund' && f.parameters.length == 4,
    );
    return CallIntent(
      to: contract.self.address,
      data: refundFn.encodeCall([
        preimageHash,
        amountWei,
        claimAddress,
        BigInt.from(timeoutBlockHeight),
      ]),
      value: EtherAmount.zero(),
      methodName: 'EtherSwap.refund',
    );
  }

  /// Build an ERC20Swap.refund intent (timelock-based).
  CallIntent erc20Refund({
    required Uint8List preimageHash,
    required BigInt amountWei,
    required EthereumAddress tokenAddress,
    required EthereumAddress claimAddress,
    required int timeoutBlockHeight,
  }) {
    final contract = swaps.getERC20SwapContract();
    final refundFn = contract.self.abi.functions.firstWhere(
      (f) => f.name == 'refund' && f.parameters.length == 5,
    );
    return CallIntent(
      to: contract.self.address,
      data: refundFn.encodeCall([
        preimageHash,
        amountWei,
        tokenAddress,
        claimAddress,
        BigInt.from(timeoutBlockHeight),
      ]),
      value: EtherAmount.zero(),
      methodName: 'ERC20Swap.refund',
    );
  }

  /// Build a timelock refund intent for either native or ERC-20.
  CallIntent refundIntent({
    required Uint8List preimageHash,
    required BigInt amountWei,
    required EthereumAddress claimAddress,
    required int timeoutBlockHeight,
    EthereumAddress? tokenAddress,
  }) {
    if (tokenAddress != null) {
      return erc20Refund(
        preimageHash: preimageHash,
        amountWei: amountWei,
        tokenAddress: tokenAddress,
        claimAddress: claimAddress,
        timeoutBlockHeight: timeoutBlockHeight,
      );
    }
    return nativeRefund(
      preimageHash: preimageHash,
      amountWei: amountWei,
      claimAddress: claimAddress,
      timeoutBlockHeight: timeoutBlockHeight,
    );
  }

  // ── Cooperative Refund ──────────────────────────────────────────────

  /// Build a native EtherSwap.refundCooperative intent.
  CallIntent nativeCooperativeRefund({
    required Uint8List preimageHash,
    required BigInt amountWei,
    required EthereumAddress claimAddress,
    required int timeoutBlockHeight,
    required EvmSignature sig,
  }) {
    final contract = swaps.getEtherSwapContract();
    final fn = contract.self.abi.functions.firstWhere(
      (f) => f.name == 'refundCooperative' && f.parameters.length == 7,
    );
    return CallIntent(
      to: contract.self.address,
      data: fn.encodeCall([
        preimageHash,
        amountWei,
        claimAddress,
        BigInt.from(timeoutBlockHeight),
        sig.v,
        sig.r,
        sig.s,
      ]),
      value: EtherAmount.zero(),
      methodName: 'EtherSwap.refundCooperative',
    );
  }

  /// Build an ERC20Swap.refundCooperative intent.
  CallIntent erc20CooperativeRefund({
    required Uint8List preimageHash,
    required BigInt amountWei,
    required EthereumAddress tokenAddress,
    required EthereumAddress claimAddress,
    required int timeoutBlockHeight,
    required EvmSignature sig,
  }) {
    final contract = swaps.getERC20SwapContract();
    final fn = contract.self.abi.functions.firstWhere(
      (f) => f.name == 'refundCooperative' && f.parameters.length == 8,
    );
    return CallIntent(
      to: contract.self.address,
      data: fn.encodeCall([
        preimageHash,
        amountWei,
        tokenAddress,
        claimAddress,
        BigInt.from(timeoutBlockHeight),
        sig.v,
        sig.r,
        sig.s,
      ]),
      value: EtherAmount.zero(),
      methodName: 'ERC20Swap.refundCooperative',
    );
  }

  /// Build a cooperative refund intent for either native or ERC-20.
  CallIntent cooperativeRefundIntent({
    required Uint8List preimageHash,
    required BigInt amountWei,
    required EthereumAddress claimAddress,
    required int timeoutBlockHeight,
    required EvmSignature sig,
    EthereumAddress? tokenAddress,
  }) {
    if (tokenAddress != null) {
      return erc20CooperativeRefund(
        preimageHash: preimageHash,
        amountWei: amountWei,
        tokenAddress: tokenAddress,
        claimAddress: claimAddress,
        timeoutBlockHeight: timeoutBlockHeight,
        sig: sig,
      );
    }
    return nativeCooperativeRefund(
      preimageHash: preimageHash,
      amountWei: amountWei,
      claimAddress: claimAddress,
      timeoutBlockHeight: timeoutBlockHeight,
      sig: sig,
    );
  }

  // ── ERC-20 Approve ──────────────────────────────────────────────────

  /// Build an ERC-20 approve intent.
  CallIntent erc20Approve({
    required EthereumAddress tokenAddress,
    required EthereumAddress spender,
    required BigInt amount,
  }) {
    final token = IERC20(address: tokenAddress, client: swaps.chain.client);
    final approveFn = token.self.abi.functions.firstWhere(
      (f) => f.name == 'approve',
    );
    return CallIntent(
      to: tokenAddress,
      data: approveFn.encodeCall([spender, amount]),
      value: EtherAmount.zero(),
      methodName: 'ERC20.approve',
    );
  }
}
