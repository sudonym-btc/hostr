import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:models/main.dart';

import '../../util/main.dart';
import '../auth/auth.dart';
import '../escrow/supported_escrow_contract/supported_escrow_contract.dart';
import '../evm/evm.dart';
import '../messaging/threads.dart';
import '../trade_account_allocator/trade_account_allocator.dart';
import '../user_subscriptions/user_subscriptions.dart';

/// Long-running singleton that watches for settled escrow trades and
/// automatically withdraws pending funds to the beneficiary's smart-wallet.
///
/// After the pull-pattern change, settlement (claim / release / arbitrate)
/// only records pending withdrawals inside the contract. This orchestrator
/// detects those pending amounts and executes `withdraw(tradeId, beneficiary,
/// destination, signature)` — sending tokens to the smart-account address
/// derived from the same EOA key that was hardcoded as buyer/seller in the
/// trade.
@Singleton()
class WithdrawalOrchestrator {
  final UserSubscriptions _userSubs;
  final Threads _threads;
  final Auth _auth;
  final Evm _evm;
  final TradeAccountAllocator _tradeAccountAllocator;
  final CustomLogger _logger;

  /// Trade IDs for which withdrawal has already been completed or is known
  /// to have nothing pending.
  final Set<String> _withdrawnTradeIds = {};

  /// Trade IDs currently being processed (prevents concurrent attempts).
  final Set<String> _inFlightTradeIds = {};

  final List<StreamSubscription> _subscriptions = [];
  bool _started = false;

  WithdrawalOrchestrator({
    required UserSubscriptions userSubs,
    required Threads threads,
    required Auth auth,
    required Evm evm,
    required TradeAccountAllocator tradeAccountAllocator,
    required CustomLogger logger,
  }) : _userSubs = userSubs,
       _threads = threads,
       _auth = auth,
       _evm = evm,
       _tradeAccountAllocator = tradeAccountAllocator,
       _logger = logger.scope('withdrawal');

  // ── Lifecycle ───────────────────────────────────────────────────────────

  void start() => _logger.spanSync('start', () {
    if (_started) return;
    _started = true;
    _logger.d('WithdrawalOrchestrator starting');

    // React to every payment event — settlement events trigger withdrawal.
    _subscriptions.add(
      _userSubs.paymentEvents$.replayStream.listen(_onPaymentEvent),
    );
  });

  // ── Event handling ──────────────────────────────────────────────────────

  void _onPaymentEvent(PaymentEvent event) =>
      _logger.spanSync('_onPaymentEvent', () {
        // Only settlement events imply pending withdrawals.
        if (event is EscrowReleasedEvent ||
            event is EscrowClaimedEvent ||
            event is EscrowArbitratedEvent) {
          _handleSettlementEvent(event as EscrowEvent);
        }
      });

  Future<void> _handleSettlementEvent(EscrowEvent event) => _logger.span(
    '_handleSettlementEvent',
    () async {
      final tradeId = event.tradeId;
      if (_withdrawnTradeIds.contains(tradeId)) return;
      if (_inFlightTradeIds.contains(tradeId)) return;

      _inFlightTradeIds.add(tradeId);
      try {
        await _tryWithdraw(tradeId, event.escrowService);
      } catch (e, st) {
        _logger.e('WithdrawalOrchestrator: withdrawal failed for $tradeId: $e');
        _logger.d('$st');
      } finally {
        _inFlightTradeIds.remove(tradeId);
      }
    },
  );

  // ── Core withdrawal logic ───────────────────────────────────────────────

  Future<void> _tryWithdraw(
    String tradeId,
    EscrowServiceSelected? escrowService,
  ) => _logger.span('_tryWithdraw', () async {
    final resolved = escrowService ?? _resolveEscrowService(tradeId);
    if (resolved == null) {
      _logger.w('WithdrawalOrchestrator: no escrow service for trade $tradeId');
      return;
    }

    final configuredChain = _evm.getChainForEscrowService(resolved.service);
    final contract = configuredChain.escrow.getSupportedEscrowContract(
      resolved.service,
    );

    // Resolve the HD account index for this trade so we derive the
    // same EOA key that was used when the trade was created.
    final accountIndex =
        await _tradeAccountAllocator.tryFindTradeAccountIndexByTradeId(
          tradeId,
        ) ??
        0;

    final ethKey = await _auth.hd.getActiveEvmKey(accountIndex: accountIndex);
    final eoa = ethKey.address;

    // The smart-wallet address is where we want the funds delivered.
    final smartWallet = await configuredChain.getAccountAddress(ethKey);

    // Check pending amount for the EOA address (the address stored in the
    // trade as buyer/seller).
    final pendingForEoa = await contract.pendingWithdrawal(
      tradeId: tradeId,
      beneficiary: eoa,
    );

    if (pendingForEoa > BigInt.zero) {
      _logger.d(
        'WithdrawalOrchestrator: withdrawing $pendingForEoa for '
        'EOA ${eoa.eip55With0x} → smart-wallet '
        '${smartWallet.eip55With0x} (trade $tradeId)',
      );

      final intent = contract.withdraw(
        WithdrawArgs(
          tradeId: tradeId,
          ethKey: ethKey,
          beneficiary: eoa,
          destination: smartWallet,
        ),
      );

      await contract.ensureDeployed();
      final txHash = await configuredChain.sendCalls(ethKey, [intent]);
      _logger.d(
        'WithdrawalOrchestrator: withdraw tx=$txHash for trade $tradeId',
      );
      _withdrawnTradeIds.add(tradeId);
      return;
    }

    // Nothing pending for this address — mark as done so we don't retry.
    _logger.d(
      'WithdrawalOrchestrator: nothing pending for $tradeId '
      '(eoa=${eoa.eip55With0x})',
    );
    _withdrawnTradeIds.add(tradeId);
  });

  // ── Helpers ─────────────────────────────────────────────────────────────

  /// Try to find the [EscrowServiceSelected] for a trade by scanning threads.
  EscrowServiceSelected? _resolveEscrowService(String tradeId) {
    final thread = _threads.threads[tradeId];
    if (thread == null) return null;

    final state = thread.state.valueOrNull;
    if (state == null) return null;

    final escrows = state.selectedEscrows;
    return escrows.isNotEmpty ? escrows.first : null;
  }

  // ── Manual trigger ──────────────────────────────────────────────────────

  /// Scan all known threads for settled trades with pending withdrawals.
  ///
  /// Call this on app startup (after subscriptions are live) to catch any
  /// trades that were settled while the app was offline.
  Future<void> scanAll() => _logger.span('scanAll', () async {
    final threads = _threads.threads;
    for (final entry in threads.entries) {
      final tradeId = entry.key;
      if (_withdrawnTradeIds.contains(tradeId)) continue;
      if (_inFlightTradeIds.contains(tradeId)) continue;

      final escrowService = _resolveEscrowService(tradeId);
      if (escrowService == null) continue;

      try {
        await _tryWithdraw(tradeId, escrowService);
      } catch (e) {
        _logger.w('WithdrawalOrchestrator.scanAll: failed for $tradeId: $e');
      }
    }
  });

  // ── Cleanup ─────────────────────────────────────────────────────────────

  Future<void> reset() => _logger.span('reset', () async {
    if (!_started) return;
    _started = false;
    _logger.d('WithdrawalOrchestrator resetting');

    for (final sub in _subscriptions) {
      await sub.cancel();
    }
    _subscriptions.clear();
    _withdrawnTradeIds.clear();
    _inFlightTradeIds.clear();
  });

  Future<void> dispose() => _logger.span('dispose', () async {
    await reset();
  });
}
