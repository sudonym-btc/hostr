import 'package:models/main.dart';
import 'package:web3dart/web3dart.dart';

import '../../call_intent.dart';

/// Callback that overrides the default lock broadcast.
///
/// Receives the pre-built lock [CallIntent]s (for ERC-20: `[approve, lock]`,
/// for native: `[lock]`). The implementer can prepend its own intents
/// (e.g. an escrow withdraw) and broadcast the combined list atomically.
/// Must return the on-chain transaction hash.
typedef SwapOutLockCallback =
    Future<String> Function(List<CallIntent> lockIntents);

class SwapOutParams {
  final EthPrivateKey evmKey;
  final int accountIndex;
  final TokenAmount? amount;

  /// Optional override for the swap lock execution.
  ///
  /// When set, the swap operation will call this callback during the lock
  /// step instead of broadcasting the lock intents directly. The callback
  /// receives the fully prepared lock [CallIntent]s and must return the
  /// broadcast transaction hash.
  ///
  /// This is the swap-out counterpart of [SwapInParams.onClaim].
  final SwapOutLockCallback? onLock;

  SwapOutParams({
    required this.evmKey,
    required this.accountIndex,
    required this.amount,
    this.onLock,
  });
}
