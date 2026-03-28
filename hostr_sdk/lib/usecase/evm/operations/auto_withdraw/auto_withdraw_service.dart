/// Service that automatically withdraws on-chain EVM balances back to
/// Lightning via swap-out when all safety gates pass.
///
/// See `TODO_AUTO_WITHDRAW.md` for the full design document.
///
/// Gate checks (evaluated in order):
/// 1. **Enabled** — user preference (`HostrUserConfig.autoWithdrawEnabled`).
/// 2. **No escrow fund ops** — `OperationStateStore` has no non-terminal
///    `escrow_fund` entries.
/// 3. **No active swaps** — no non-terminal `swap_in` or `swap_out` entries.
/// 4. **Minimum balance** — on-chain balance ≥ configured minimum sats.
/// 5. **Fee ratio** — estimated fees / balance ≤ [maxFeeRatio].
class AutoWithdrawService {
  /// Maximum acceptable fee ratio (fees / balance).
  ///
  /// If the estimated swap-out fees exceed this fraction of the balance,
  /// auto-withdrawal is skipped to avoid burning funds on fees.
  static const double maxFeeRatio = 0.10;

  /// Debounce applied to balance change events before evaluating gates.
  static const Duration debounceDuration = Duration(seconds: 5);

  /// Cooldown after a successful (or failed) swap-out before the next attempt.
  static const Duration cooldownDuration = Duration(seconds: 300);
}
