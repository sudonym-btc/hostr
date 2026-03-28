import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:rxdart/rxdart.dart';
import 'package:wallet/wallet.dart';

import '../../../../config.dart';
import '../../../../injection.dart';
import '../../../../util/custom_logger.dart';
import '../../../../util/token_amount_ext.dart';
import '../../../auth/auth.dart';
import '../../../escrow/supported_escrow_contract/supported_escrow_contract.dart';
import '../../../nwc/nwc.dart';
import '../../../payments/payments.dart';
import '../../../trade_account_allocator/trade_account_allocator.dart';
import '../../../user_config/user_config_store.dart';
import '../../../user_subscriptions/user_subscriptions.dart';
import '../../chain/evm_balance_types.dart';
import '../../evm.dart';
import '../operation_state_store.dart';
import '../swap_out/swap_out_models.dart';
import '../swap_out/swap_out_quote_service.dart';
import '../swap_out/swap_out_state.dart';
import 'funds_item.dart';

/// Combined balance monitor and auto-withdrawal service.
///
/// Replaces both [AutoWithdrawService] and [WithdrawalOrchestrator].
///
/// ## Streams
///
/// - **[fundsStream$]** — all currently sweepable [FundsItem]s across all
///   chains. Items with [FundsItem.contract] != null represent escrow-locked
///   funds that need a pre-lock `withdraw()` call bundled into the swap-out.
///
/// - **[displayBalance$]** — per-token sums derived from [fundsStream$], for
///   display in the UI.
///
/// ## Sweep path
///
/// [fundsStream$] is debounced and each item that passes all gates is swept
/// to Lightning via a [SwapOutOperation]. Escrow items include `withdraw()`
/// as a `preLockCalls` entry so the on-chain withdraw and lockup are atomic.
@Singleton()
class FundsMonitorService {
  /// How long to wait after a balance change before checking gates.
  static const debounceDuration = Duration(seconds: 5);

  /// How long to wait after a swap-out attempt before trying again.
  static const cooldownDuration = Duration(seconds: 300);

  /// Maximum fee-to-balance ratio tolerated for an auto-withdrawal.
  static const double maxFeeRatio = 0.10;

  // ── Dependencies ────────────────────────────────────────────────────────

  final Evm _evm;
  final UserSubscriptions _userSubs;
  final Auth _auth;
  final TradeAccountAllocator _tradeAccountAllocator;
  final OperationStateStore _stateStore;
  final UserConfigStore _userConfigStore;
  final HostrConfig _hostrConfig;
  final SwapOutQuoteService _quoteService;
  final CustomLogger _logger;

  // ── Observable state ────────────────────────────────────────────────────

  /// All currently sweepable funds across all chains.
  ///
  /// Items where [FundsItem.contract] is non-null are escrow-locked and
  /// require `preLockCalls` in the corresponding swap-out operation.
  late final Stream<List<FundsItem>> fundsStream$;

  /// Display-only: per-token totals collapsed from [fundsStream$].
  late final Stream<List<TokenAmount>> displayBalance$;

  // ── Internal state ───────────────────────────────────────────────────────

  /// Live EOA/smart-wallet balances keyed by (addressLower, tokenAddressLower).
  final Map<(String, String), FundsItem> _eoaItems = {};
  final BehaviorSubject<List<FundsItem>> _eoaSubject = BehaviorSubject.seeded(
    [],
  );

  /// Pending escrow withdrawals keyed by tradeId.
  final Map<String, FundsItem> _escrowItems = {};
  final BehaviorSubject<List<FundsItem>> _escrowSubject =
      BehaviorSubject.seeded([]);

  /// Address → account index (populated during seeding + new address tracking).
  final Map<String, int> _addressToAccountIndex = {};

  /// Track in-flight escrow items to prevent concurrent retries.
  final Set<String> _inFlightEscrowTradeIds = {};

  bool _swapInProgress = false;
  Timer? _cooldownTimer;

  StreamSubscription? _balanceSub;
  StreamSubscription? _eventSub;
  StreamSubscription? _sweepSub;

  bool _started = false;

  FundsMonitorService(
    this._evm,
    this._userSubs,
    this._auth,
    this._tradeAccountAllocator,
    this._stateStore,
    this._userConfigStore,
    this._hostrConfig,
    this._quoteService,
    CustomLogger logger,
  ) : _logger = logger.scope('funds-monitor');

  // ── Lifecycle ────────────────────────────────────────────────────────────

  /// Start the service.
  ///
  /// 1. Seeds each chain's [EvmBalanceMonitor] with currently-funded addresses.
  /// 2. Subscribes to monitor updates → [fundsStream$].
  /// 3. Subscribes to escrow settlement events → [fundsStream$].
  /// 4. Starts sweep listener.
  ///
  /// Idempotent.
  void start() => _logger.spanSync('start', () {
    if (_started) return;
    _started = true;

    _buildFundsStream();
    _unawaited(_seedMonitors());
    _startEventListener();
    _startSweepListener();
  });

  /// Stop the service. Safe to call when not started.
  Future<void> stop() => _logger.span('stop', () async {
    if (!_started) return;
    _started = false;

    await _balanceSub?.cancel();
    _balanceSub = null;
    await _eventSub?.cancel();
    _eventSub = null;
    await _sweepSub?.cancel();
    _sweepSub = null;
    _cooldownTimer?.cancel();
    _cooldownTimer = null;
    _swapInProgress = false;

    _logger.d('FundsMonitorService stopped');
  });

  /// Reset state and restart (e.g. after user logs out → log in).
  Future<void> reset() => _logger.span('reset', () async {
    await stop();
    _eoaItems.clear();
    _eoaSubject.add([]);
    _escrowItems.clear();
    _escrowSubject.add([]);
    _addressToAccountIndex.clear();
    _inFlightEscrowTradeIds.clear();
  });

  /// Force an immediate sweep check (skips debounce).
  Future<void> checkNow() => _logger.span('checkNow', () async {
    final items = await fundsStream$.first;
    await _sweep(items);
  });

  /// Register an address → account index mapping and start tracking it.
  ///
  /// Call this whenever a new address becomes relevant (e.g. after
  /// [SwapInOperation] completes with a specific EOA address).
  void trackAddress(
    EthereumAddress address,
    int accountIndex, {
    required String chain,
    String? reason,
  }) {
    final key = address.eip55With0x.toLowerCase();
    _addressToAccountIndex[key] = accountIndex;

    final evmChain = _evm.getChainById(chain);
    if (evmChain == null) return;
    evmChain.balanceMonitor.trackAddress(address, reason: reason);
  }

  // ── Stream construction ──────────────────────────────────────────────────

  void _buildFundsStream() {
    // Merge BalanceUpdate streams from all chain monitors.
    _balanceSub =
        Rx.merge(
          _evm.configuredChains.map(
            (c) => c.balanceMonitor.balanceUpdates.stream,
          ),
        ).listen(
          _onBalanceUpdate,
          onError: (Object e) => _logger.w('Balance update error: $e'),
        );

    // Combined stream: latest EOA snapshot + latest escrow snapshot.
    fundsStream$ = Rx.combineLatest2(
      _eoaSubject.stream,
      _escrowSubject.stream,
      (eoaItems, escrowItems) => [...eoaItems, ...escrowItems],
    );

    displayBalance$ = fundsStream$.map(_groupByToken).distinct();
  }

  void _onBalanceUpdate(BalanceUpdate update) {
    final addrKey = update.address.eip55With0x.toLowerCase();
    final tokenKey = update.token.address.toLowerCase();
    final mapKey = (addrKey, tokenKey);

    final accountIndex = _addressToAccountIndex[addrKey];
    if (accountIndex == null) {
      // Address not registered — ignore (shouldn't happen after seeding).
      return;
    }

    if (update.balance.value == BigInt.zero) {
      _eoaItems.remove(mapKey);
    } else {
      // Resolve keypair lazily — use a placeholder for the stream update
      // and populate asynchronously.
      _unawaited(_resolveAndUpsertEoaItem(update, accountIndex, mapKey));
      return;
    }

    _eoaSubject.add(_eoaItems.values.toList());
  }

  Future<void> _resolveAndUpsertEoaItem(
    BalanceUpdate update,
    int accountIndex,
    (String, String) mapKey,
  ) async {
    try {
      final keypair = await _auth.hd.getActiveEvmKey(
        accountIndex: accountIndex,
      );

      // Find the chain for this update.
      final chain = _evm.configuredChains.firstWhere(
        (c) => c.balanceMonitor.trackedAddresses.any(
          (a) =>
              a.address.eip55With0x.toLowerCase() ==
              update.address.eip55With0x.toLowerCase(),
        ),
        orElse: () => _evm.configuredChains.first,
      );

      _eoaItems[mapKey] = FundsItem(
        address: update.address,
        keypair: keypair,
        accountIndex: accountIndex,
        token: update.token,
        balance: update.balance,
        chain: chain,
        blockNumber: update.blockNumber,
      );
      _eoaSubject.add(_eoaItems.values.toList());
    } catch (e) {
      _logger.w('Failed to resolve keypair for EOA item: $e');
    }
  }

  // ── Settlement event → escrow FundsItem ─────────────────────────────────

  void _startEventListener() {
    _eventSub = _userSubs.paymentEvents$.replayStream
        .whereType<EscrowEvent>()
        .where(
          (e) =>
              e is EscrowReleasedEvent ||
              e is EscrowClaimedEvent ||
              e is EscrowArbitratedEvent,
        )
        .listen(
          _onSettlementEvent,
          onError: (Object e) => _logger.w('Settlement event error: $e'),
        );
  }

  Future<void> _onSettlementEvent(EscrowEvent event) async {
    final chain = event.chain;
    final contract = event.contract;
    if (chain == null || contract == null) return;

    final tradeId = event.tradeId;
    if (_escrowItems.containsKey(tradeId)) return;
    if (_inFlightEscrowTradeIds.contains(tradeId)) return;

    _inFlightEscrowTradeIds.add(tradeId);
    try {
      final accountIndex =
          await _tradeAccountAllocator.tryFindTradeAccountIndexByTradeId(
            tradeId,
          ) ??
          0;
      final keypair = await _auth.hd.getActiveEvmKey(
        accountIndex: accountIndex,
      );

      final pending = await contract.pendingWithdrawal(
        tradeId: tradeId,
        beneficiary: keypair.address,
      );
      if (pending == BigInt.zero) return;

      final item = FundsItem(
        address: keypair.address,
        keypair: keypair,
        accountIndex: accountIndex,
        token: Token.native(chain.config.chainId),
        balance: rbtcFromWei(pending),
        chain: chain,
        blockNumber:
            0, // BlockInformation carries no block number; 0 is a safe placeholder
        contract: contract,
        tradeId: tradeId,
      );

      _escrowItems[tradeId] = item;
      _escrowSubject.add(_escrowItems.values.toList());
    } catch (e) {
      _logger.e('Failed to build escrow FundsItem for $tradeId: $e');
    } finally {
      _inFlightEscrowTradeIds.remove(tradeId);
    }
  }

  // ── Seeding ──────────────────────────────────────────────────────────────

  Future<void> _seedMonitors() => _logger.span('_seedMonitors', () async {
    for (final chain in _evm.configuredChains) {
      // Seed native balances.
      try {
        final funded = await chain.getAddressesWithBalance();
        for (final entry in funded) {
          final key = entry.address.eip55With0x.toLowerCase();
          _addressToAccountIndex[key] = entry.accountIndex;
          chain.balanceMonitor.trackAddress(
            entry.address,
            reason: 'seed:native',
          );
        }
      } catch (e) {
        _logger.w('Seed native scan failed for ${chain.config.id}: $e');
      }

      // Seed ERC-20 balances.
      final boltzTokens = chain.swaps?.chainInfo.tokens;
      if (boltzTokens != null && boltzTokens.isNotEmpty) {
        try {
          final tokenFunded = await chain.getAddressesWithTokenBalances(
            boltzTokens,
          );
          for (final entry in tokenFunded) {
            final key = entry.address.eip55With0x.toLowerCase();
            _addressToAccountIndex[key] = entry.accountIndex;
            chain.balanceMonitor.trackAddress(
              entry.address,
              reason: 'seed:erc20',
            );
          }
        } catch (e) {
          _logger.w('Seed ERC-20 scan failed for ${chain.config.id}: $e');
        }
      }
    }
  });

  // ── Sweep listener ───────────────────────────────────────────────────────

  void _startSweepListener() {
    _sweepSub = fundsStream$
        .debounceTime(debounceDuration)
        .listen(
          _sweep,
          onError: (Object e) => _logger.w('Sweep listener error: $e'),
        );
  }

  Future<void> _sweep(List<FundsItem> items) =>
      _logger.span('_sweep', () async {
        for (final item in items) {
          if (_swapInProgress) break;

          if (!await _passesGates(item)) continue;

          await _executeSwapOut(item);
        }
      });

  Future<bool> _passesGates(FundsItem item) async {
    final config = await _userConfigStore.state;

    // Gate 1: enabled?
    if (!config.autoWithdrawEnabled) return false;

    // Guard: already swapping?
    if (_swapInProgress) return false;

    // Guard: cooldown active?
    if (_cooldownTimer?.isActive ?? false) {
      _logger.d('FundsMonitor skipped: cooldown active');
      return false;
    }

    // Gate 2: Any escrow operations in flight?
    if (await _stateStore.hasNonTerminal('escrow_fund')) {
      _logger.d('FundsMonitor skipped: escrow fund operation(s) in flight');
      return false;
    }

    // Gate 3: Any active (non-terminal) swaps already running?
    if (await _stateStore.hasNonTerminal('swap_in') ||
        await _stateStore.hasNonTerminal('swap_out')) {
      _logger.d('FundsMonitor skipped: active swap(s) in progress');
      return false;
    }

    final minimumBalance = rbtcFromSatsInt(
      _hostrConfig.autoWithdrawMinimumSats,
    );

    // Gate 4: minimum balance?
    if (item.balance < minimumBalance) {
      _logger.d(
        'FundsMonitor skipped ${item.address.eip55With0x}: '
        '${item.balance.getInSats} sats below minimum '
        '${_hostrConfig.autoWithdrawMinimumSats}',
      );
      return false;
    }

    // Gate 5: fee ratio?
    try {
      final swapParams = SwapOutParams(
        evmKey: item.keypair,
        accountIndex: item.accountIndex,
        amount: item.isEscrowLocked ? item.balance : null,
      );
      final quote = await item.chain.swapOutQuote(params: swapParams);
      final networkFees = quote.feeBreakdown.networkFees;
      final feeRatio = networkFees.value == BigInt.zero
          ? 0.0
          : networkFees.value.toDouble() / item.balance.getInSats.toDouble();

      if (feeRatio > maxFeeRatio) {
        _logger.d(
          'FundsMonitor skipped on ${item.chain.config.id}: fee ratio '
          '${(feeRatio * 100).toStringAsFixed(1)}% exceeds max '
          '${(maxFeeRatio * 100).toStringAsFixed(1)}%',
        );
        return false;
      }
    } catch (e) {
      _logger.w('FundsMonitor: could not get quote for gate check: $e');
      return false;
    }

    return true;
  }

  Future<void> _executeSwapOut(FundsItem item) async {
    _swapInProgress = true;
    try {
      // For escrow-locked funds, bundle withdraw() as a pre-lock call.
      Map<String, Call>? preLockCalls;
      if (item.isEscrowLocked) {
        final destination = await item.chain.getAccountAddress(item.keypair);
        preLockCalls = {
          'withdraw': item.contract!.withdraw(
            WithdrawArgs(
              tradeId: item.tradeId!,
              ethKey: item.keypair,
              beneficiary: item.keypair.address,
              destination: destination,
            ),
          ),
        };
      }

      final swapOp = item.chain.swapOut(
        params: SwapOutParams(
          evmKey: item.keypair,
          accountIndex: item.accountIndex,
          amount: item.isEscrowLocked ? item.balance : null,
          preLockCalls: preLockCalls,
        ),
        auth: getIt<Auth>(),
        logger: _logger,
        nwc: getIt<Nwc>(),
        payments: getIt<Payments>(),
        quoteService: _quoteService,
      );

      _logger.i(
        'FundsMonitor: initiating swap-out of ${item.balance.getInSats} sats '
        'on ${item.chain.config.id}'
        '${item.tradeId != null ? " (escrow trade=${item.tradeId})" : ""}',
      );

      await swapOp.execute();

      if (swapOp.state is SwapOutCompleted) {
        _logger.i(
          'FundsMonitor: swap-out completed on ${item.chain.config.id}',
        );
        // Evict the escrow item on success.
        if (item.tradeId != null) {
          _escrowItems.remove(item.tradeId);
          _escrowSubject.add(_escrowItems.values.toList());
        }
      } else if (swapOp.state is SwapOutFailed) {
        final failed = swapOp.state as SwapOutFailed;
        _logger.e(
          'FundsMonitor: swap-out failed on ${item.chain.config.id}: '
          '${failed.error}',
        );
      }
    } catch (e) {
      _logger.e('FundsMonitor: swap-out threw on ${item.chain.config.id}: $e');
    } finally {
      _swapInProgress = false;
      _cooldownTimer = Timer(cooldownDuration, () {});
    }
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  static List<TokenAmount> _groupByToken(List<FundsItem> items) {
    final map = <String, TokenAmount>{};
    for (final item in items) {
      final key = item.token.address.toLowerCase();
      map.update(
        key,
        (existing) => existing + item.balance,
        ifAbsent: () => item.balance,
      );
    }
    return map.values.toList();
  }

  // ignore: prefer_void_to_null
  static void _unawaited(Future<void> future) {
    future.ignore();
  }
}
