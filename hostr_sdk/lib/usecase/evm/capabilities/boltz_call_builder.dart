import 'dart:typed_data';

import 'package:wallet/wallet.dart' show EthereumAddress;

import '../../../datasources/contracts/boltz/IERC20.g.dart';
import '../../../util/evm_signature.dart';
import '../evm_call.dart';
import 'boltz_swap_provider.dart';

/// Builds [Call]s for Boltz swap contract interactions.
///
/// Centralises all ABI-level encoding so operation classes can focus on
/// orchestration. Every method returns one or more [Call]s — the
/// caller decides how to broadcast them (AA batched or EOA sequential).
class BoltzCallBuilder {
  final BoltzSwapProvider swaps;

  const BoltzCallBuilder(this.swaps);

  // ── Lock ────────────────────────────────────────────────────────────

  /// Build a native EtherSwap.lock call (payable).
  Call nativeLock({
    required Uint8List preimageHash,
    required BigInt amountWei,
    required EthereumAddress claimAddress,
    required int timeoutBlockHeight,
  }) {
    final contract = swaps.getEtherSwapContract();
    final lockFn = contract.self.abi.functions.firstWhere(
      (f) => f.name == 'lock' && f.parameters.length == 3,
    );
    return callFromEncoded(
      to: contract.self.address,
      data: lockFn.encodeCall([
        preimageHash,
        claimAddress,
        BigInt.from(timeoutBlockHeight),
      ]),
      value: amountWei,
    );
  }

  /// Build ERC-20 approve + ERC20Swap.lock calls.
  Map<String, Call> erc20Lock({
    required Uint8List preimageHash,
    required BigInt amountWei,
    required EthereumAddress tokenAddress,
    required EthereumAddress claimAddress,
    required int timeoutBlockHeight,
  }) {
    final erc20Swap = swaps.getERC20SwapContract();

    final approveCall = erc20Approve(
      tokenAddress: tokenAddress,
      spender: erc20Swap.self.address,
      amount: amountWei,
    );

    final lockFn = erc20Swap.self.abi.functions.firstWhere(
      (f) => f.name == 'lock' && f.parameters.length == 5,
    );
    final lockCall = callFromEncoded(
      to: erc20Swap.self.address,
      data: lockFn.encodeCall([
        preimageHash,
        amountWei,
        tokenAddress,
        claimAddress,
        BigInt.from(timeoutBlockHeight),
      ]),
    );

    return {'ERC20.approve': approveCall, 'ERC20Swap.lock': lockCall};
  }

  // ── Claim ───────────────────────────────────────────────────────────

  /// Build a native EtherSwap.claim call.
  Call nativeClaim({
    required Uint8List preimage,
    required BigInt amount,
    required EthereumAddress refundAddress,
    required BigInt timelock,
  }) {
    final contract = swaps.getEtherSwapContract();
    final claimFn = contract.self.abi.functions.firstWhere(
      (f) => f.name == 'claim' && f.parameters.length == 4,
    );
    return callFromEncoded(
      to: contract.self.address,
      data: claimFn.encodeCall([preimage, amount, refundAddress, timelock]),
    );
  }

  /// Build an ERC20Swap.claim call.
  Call erc20Claim({
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
    return callFromEncoded(
      to: contract.self.address,
      data: claimFn.encodeCall([
        preimage,
        amount,
        tokenAddress,
        refundAddress,
        timelock,
      ]),
    );
  }

  /// Build a claim call for either native or ERC-20.
  Call claim({
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

  /// Build a native EtherSwap.refund call (timelock-based).
  Call nativeRefund({
    required Uint8List preimageHash,
    required BigInt amountWei,
    required EthereumAddress claimAddress,
    required int timeoutBlockHeight,
  }) {
    final contract = swaps.getEtherSwapContract();
    final refundFn = contract.self.abi.functions.firstWhere(
      (f) => f.name == 'refund' && f.parameters.length == 4,
    );
    return callFromEncoded(
      to: contract.self.address,
      data: refundFn.encodeCall([
        preimageHash,
        amountWei,
        claimAddress,
        BigInt.from(timeoutBlockHeight),
      ]),
    );
  }

  /// Build an ERC20Swap.refund call (timelock-based).
  Call erc20Refund({
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
    return callFromEncoded(
      to: contract.self.address,
      data: refundFn.encodeCall([
        preimageHash,
        amountWei,
        tokenAddress,
        claimAddress,
        BigInt.from(timeoutBlockHeight),
      ]),
    );
  }

  /// Build a timelock refund call for either native or ERC-20.
  Call refund({
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

  /// Build a native EtherSwap.refundCooperative call.
  Call nativeCooperativeRefund({
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
    return callFromEncoded(
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
    );
  }

  /// Build an ERC20Swap.refundCooperative call.
  Call erc20CooperativeRefund({
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
    return callFromEncoded(
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
    );
  }

  /// Build a cooperative refund call for either native or ERC-20.
  Call cooperativeRefund({
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

  /// Build an ERC-20 approve call.
  Call erc20Approve({
    required EthereumAddress tokenAddress,
    required EthereumAddress spender,
    required BigInt amount,
  }) {
    final token = IERC20(address: tokenAddress, client: swaps.chain.client);
    final approveFn = token.self.abi.functions.firstWhere(
      (f) => f.name == 'approve',
    );
    return callFromEncoded(
      to: tokenAddress,
      data: approveFn.encodeCall([spender, amount]),
    );
  }
}
