/// Shared interface for fields common to both [SwapInData] and [SwapOutData].
///
/// Allows code that handles either swap direction (e.g. notifications,
/// persistence helpers, UI progress indicators) to depend on a single type
/// without knowing the swap direction.
mixin BoltzSwapData {
  /// Boltz's unique identifier for this swap.
  String get boltzId;

  /// Block height at which the swap's HTLC expires.
  int get timeoutBlockHeight;

  /// EVM chain ID.
  int get chainId;

  /// HD wallet account index that owns this swap.
  int get accountIndex;

  /// Block height at which the swap was created. Null before lockup.
  int? get creationBlockHeight;

  /// Last Boltz WebSocket status string (e.g. `"transaction.mempool"`).
  String? get lastBoltzStatus;

  /// Human-readable error message, when the swap is in a failed state.
  String? get errorMessage;

  /// ERC-20 token address, or null for native (EtherSwap).
  String? get tokenAddress;
}
