import 'package:models/main.dart';
import 'package:web3dart/web3dart.dart';

import '../../evm_call.dart';

class SwapOutParams {
  final EthPrivateKey evmKey;
  final int accountIndex;
  final TokenAmount? amount;

  /// Extra [Call]s to prepend before the lock calls in a single UserOp.
  ///
  /// When non-null the swap operation merges these calls ahead of the
  /// built lock calls (approve + lock) and broadcasts atomically.
  /// For example, an escrow withdraw call is prepended so that
  /// withdraw + lock happen in one transaction.
  ///
  /// Persisted on [SwapOutData] for crash recovery — no callback
  /// reconstruction needed.
  final Map<String, Call>? preLockCalls;

  SwapOutParams({
    required this.evmKey,
    required this.accountIndex,
    required this.amount,
    this.preLockCalls,
  });
}
