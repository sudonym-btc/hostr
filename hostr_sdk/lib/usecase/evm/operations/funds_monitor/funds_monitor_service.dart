import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Filter;
import 'package:rxdart/rxdart.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart'
    show BlockNum, EthPrivateKey, FilterOptions;

import '../../../../config.dart';
import '../../../../injection.dart';
import '../../../../util/custom_logger.dart';
import '../../../../util/token_amount_ext.dart';
import '../../../auth/auth.dart';
import '../../../escrow/supported_escrow_contract/supported_escrow_contract.dart';
import '../../../escrows/escrows.dart';
import '../../../trade_account_allocator/trade_account_allocator.dart';
import '../../../user_config/user_config_store.dart';
import '../../../user_subscriptions/user_subscriptions.dart';
import '../../chain/evm_chain.dart';
import '../../chain/rpc_batch_builder.dart';
import '../../evm.dart';
import '../../models/amount_spec.dart';
import '../operation_state_store.dart';
import '../swap_out/swap_out_models.dart';
import '../swap_out/swap_out_state.dart';
import 'funds_item.dart';

/// Monitors fund balances and auto-sweeps them to Lightning.
///
/// ## Design
///
/// On startup, [scan] performs a one-time HD address derivation and batched
/// RPC balance fetch across all configured EVM chains (native + Boltz ERC-20
/// tokens). It also queries known escrow contracts for locked balances. The
/// results are emitted as [FundsItem]s via [fundsStream$].
///
/// After the initial scan, balances are refreshed by explicit [scan] and
/// [refetchAccount] calls. Startup does not subscribe to block streams; live
/// block tracking is only entered through explicit APIs such as
/// [setLiveErc20TrackingEnabled] or [trackAddress].
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

  /// Maximum fee-to-balance ratio tolerated for an auto-withdrawal.
  static const double maxFeeRatio = 0.10;

  // ── Dependencies ────────────────────────────────────────────────────────

  final Evm _evm;
  final UserSubscriptions _userSubs;
  final Auth _auth;
  final TradeAccountAllocator _tradeAccountAllocator;
  final OperationStateStore _stateStore;
  final UserConfigStore _userConfigStore;
  final CustomLogger _logger;

  // ── Observable state ────────────────────────────────────────────────────

  /// All currently sweepable funds across all chains.
  ///
  /// Items where [FundsItem.contract] is non-null are escrow-locked and
  /// require `preLockCalls` in the corresponding swap-out operation.
  late Stream<List<FundsItem>> fundsStream$;

  /// Display-only: per-token totals collapsed from [fundsStream$].
  late Stream<List<TokenAmount>> displayBalance$;

  // ── Internal state ───────────────────────────────────────────────────────

  /// Smart-wallet / EOA balances keyed by (addressLower, tokenAddressLower).
  final Map<(String, String), FundsItem> _walletItems = {};
  final BehaviorSubject<List<FundsItem>> _walletSubject =
      BehaviorSubject.seeded([]);

  /// Escrow-locked balances keyed by (addressLower, tokenAddressLower).
  final Map<(String, String), FundsItem> _escrowItems = {};
  final BehaviorSubject<List<FundsItem>> _escrowSubject =
      BehaviorSubject.seeded([]);

  /// Address → account index (populated during scan + refetch).
  final Map<String, int> _addressToAccountIndex = {};
  final Map<(String, String), _TrackedWalletAccount> _walletAccounts = {};
  final Map<String, _ChainBalanceTracker> _chainTrackers = {};
  final Map<(String, String), Future<TokenAmount?>> _swapOutMinimumCache = {};

  bool _swapInProgress = false;
  StreamSubscription? _eventSub;
  StreamSubscription? _sweepSub;

  Completer<void>? _scanCompleter;
  Future<void>? _startFuture;

  bool _started = false;
  bool _streamsBuilt = false;
  bool _liveErc20TrackingEnabled;
  int _startGeneration = 0;

  FundsMonitorService(
    this._evm,
    this._userSubs,
    this._auth,
    this._tradeAccountAllocator,
    this._stateStore,
    this._userConfigStore,
    CustomLogger logger,
  ) : _logger = logger.scope('funds-monitor'),
      _liveErc20TrackingEnabled = false;

  // ── Lifecycle ────────────────────────────────────────────────────────────

  /// Start the service and kick off the initial [scan].
  ///
  /// 1. Builds the funds observable streams.
  /// 2. Runs a one-time [scan] (HD balance + escrow contract balances).
  /// 3. Subscribes to escrow settlement events for reactive refresh.
  /// 4. Starts sweep listener.
  ///
  /// Idempotent.
  Future<void> start() {
    final existing = _startFuture;
    if (existing != null) return existing;

    final generation = ++_startGeneration;
    late final Future<void> future;
    future = _logger.span('start', () => _startInternal(generation)).catchError(
      (Object e, StackTrace st) {
        if (identical(_startFuture, future)) {
          _startFuture = null;
          _started = false;
        }
        Error.throwWithStackTrace(e, st);
      },
    );
    _startFuture = future;
    return future;
  }

  Future<void> _startInternal(int generation) async {
    if (_started) return;
    _started = true;

    _buildFundsStream();
    _scanCompleter = Completer<void>();
    try {
      await _prepareBalanceTrackers();
      if (!_isCurrentStart(generation)) return;

      _startEventListener();
      _startSweepListener();

      try {
        await scan();
      } catch (e) {
        _logger.w('Initial scan failed: $e');
      }
    } finally {
      if (!(_scanCompleter?.isCompleted ?? true)) _scanCompleter?.complete();
    }

    // Do not start block-triggered balance tracking here. Startup should do
    // one discovery scan only; later refreshes happen through explicit scan or
    // refetch calls.
  }

  /// Await the initial [scan]. Returns immediately if already completed or
  /// not yet started.
  Future<void> seedAndAwait() async {
    await _scanCompleter?.future;
  }

  /// Stop the service. Safe to call when not started.
  Future<void> stop() => _logger.span('stop', () async {
    if (!_started) return;
    _started = false;
    _startGeneration++;
    _startFuture = null;

    await _eventSub?.cancel();
    _eventSub = null;
    await _sweepSub?.cancel();
    _sweepSub = null;
    for (final tracker in _chainTrackers.values) {
      await tracker.stop();
    }
    _swapInProgress = false;
    _clearSessionState();

    _logger.d('FundsMonitorService stopped');
  });

  /// Reset state and restart (e.g. after user logs out → log in).
  Future<void> reset() => _logger.span('reset', () async {
    await stop();
    _clearSessionState();
    for (final tracker in _chainTrackers.values) {
      await tracker.dispose();
    }
    _chainTrackers.clear();
    _scanCompleter = null;
    _startFuture = null;
  });

  bool _isCurrentStart(int generation) =>
      _started && _startGeneration == generation;

  void _clearSessionState() {
    _walletItems.clear();
    _walletSubject.add([]);
    _escrowItems.clear();
    _escrowSubject.add([]);
    _addressToAccountIndex.clear();
    _walletAccounts.clear();
  }

  bool get liveErc20TrackingEnabled => _liveErc20TrackingEnabled;

  /// Enable this only when the app deliberately wants per-block ERC-20
  /// Transfer-log tracking. Explicit [scan] and [refetchAccount] always read
  /// ERC-20 balances regardless of this setting.
  Future<void> setLiveErc20TrackingEnabled(bool enabled) async {
    if (_liveErc20TrackingEnabled == enabled) return;
    _liveErc20TrackingEnabled = enabled;

    for (final chain in _evm.configuredChains) {
      final tracker = await _ensureChainTracker(chain);
      tracker.setLiveErc20TrackingEnabled(enabled);
      if (enabled) {
        await _registerLiveErc20Tokens(chain, tracker, snapshot: true);
        tracker.start();
      } else {
        await tracker.stop();
      }
    }
  }

  /// Force an immediate sweep check (skips debounce).
  Future<void> checkNow() => _logger.span('checkNow', () async {
    final items = await fundsStream$.first;
    await _sweep(items);
  });

  // ══════════════════════════════════════════════════════════════════════════
  // One-time scan
  // ══════════════════════════════════════════════════════════════════════════

  /// Derive HD addresses across all configured chains, batch-fetch native +
  /// ERC-20 balances, and query escrow contract balances. Results are emitted
  /// as [FundsItem]s via [fundsStream$].
  ///
  /// This is the primary balance-discovery mechanism. It runs once at startup
  /// and can be called again to do a full refresh.
  Future<void> scan() => _logger.span('scan', () async {
    for (final chain in _evm.configuredChains) {
      try {
        await _scanChain(chain);
      } catch (e) {
        _logger.w('Scan failed for ${chain.config.id}: $e');
      }
    }

    // Fetch escrow contract balances.
    await _scanEscrowContracts();
  });

  /// Scan a single chain: derive HD addresses, batch-fetch native + ERC-20
  /// balances for all Boltz tokens, and record as [FundsItem]s.
  Future<void> _scanChain(EvmChain chain) async {
    final tracker = await _ensureChainTracker(chain);
    final boltzTokens = chain.swaps?.chainInfo.tokens ?? {};
    final (:nativeFunded, :tokenFunded) = await chain.scanAllHDBalances(
      tokens: boltzTokens,
    );

    for (final entry in nativeFunded) {
      final key = entry.address.eip55With0x.toLowerCase();
      _trackWalletAddress(
        chain: chain,
        address: entry.address,
        keypair: entry.keypair,
        accountIndex: entry.accountIndex,
        isSmartAddress: entry.isSmartAddress,
        reason: 'scan:${entry.accountIndex}',
        snapshot: false,
      );
      final nativeToken = Token.native(chain.config.chainId);
      final mapKey = (key, nativeToken.address.toLowerCase());
      final dust = await _isDustBalance(chain, entry.balance);
      _walletItems[mapKey] = FundsItem(
        address: entry.address,
        keypair: entry.keypair,
        accountIndex: entry.accountIndex,
        token: nativeToken,
        balance: entry.balance,
        chain: chain,
        blockNumber: 0,
        isSmartAddress: entry.isSmartAddress,
        dust: dust,
      );
      if (dust) _logUnsweepableDust(entry.balance, entry.address, chain);
      tracker.seedBalance(entry.address, nativeToken, entry.balance);
    }

    for (final entry in tokenFunded) {
      final key = entry.address.eip55With0x.toLowerCase();
      _trackWalletAddress(
        chain: chain,
        address: entry.address,
        keypair: entry.keypair,
        accountIndex: entry.accountIndex,
        isSmartAddress: entry.isSmartAddress,
        reason: 'scan:${entry.accountIndex}',
        snapshot: false,
      );
      final tokenKey = entry.tokenAddress.eip55With0x.toLowerCase();
      final mapKey = (key, tokenKey);
      final dust = await _isDustBalance(chain, entry.balance);
      _walletItems[mapKey] = FundsItem(
        address: entry.address,
        keypair: entry.keypair,
        accountIndex: entry.accountIndex,
        token: entry.balance.token,
        balance: entry.balance,
        chain: chain,
        blockNumber: 0,
        isSmartAddress: entry.isSmartAddress,
        dust: dust,
      );
      if (dust) _logUnsweepableDust(entry.balance, entry.address, chain);
      tracker.seedBalance(entry.address, entry.balance.token, entry.balance);
    }

    _walletSubject.add(_walletItems.values.toList());
  }

  /// Query all known escrow contracts for locked balances across all chains.
  ///
  /// Discovers escrow services by fetching [EscrowService] events from
  /// bootstrap escrow pubkeys, then calls `allBalances` on each contract.
  Future<void> _scanEscrowContracts() =>
      _logger.span('_scanEscrowContracts', () async {
        final escrows = getIt<Escrows>();
        final config = getIt<HostrConfig>();
        if (config.bootstrapEscrowPubkeys.isEmpty) return;

        // Fetch known escrow service events.
        final services = await escrows.list(
          Filter(
            kinds: EscrowService.kinds,
            authors: config.bootstrapEscrowPubkeys,
          ),
        );

        for (final service in services) {
          try {
            final chain = _evm.getChainByChainId(service.chainId);
            if (chain == null) continue;

            final contract = chain.escrow.getSupportedEscrowContract(service);

            // Check all known account indices for balances.
            final seenIndices = <int>{};
            for (final index in _addressToAccountIndex.values) {
              if (!seenIndices.add(index)) continue;
              try {
                final keypair = await _auth.hd.getActiveEvmKey(
                  accountIndex: index,
                );
                await _refreshEscrowBalances(
                  contract: contract,
                  chain: chain,
                  keypair: keypair,
                  accountIndex: index,
                );
              } catch (e) {
                _logger.w(
                  'Escrow balance scan failed for account $index '
                  'on ${chain.config.id}: $e',
                );
              }
            }
          } catch (e) {
            _logger.w('Escrow scan failed for service ${service.id}: $e');
          }
        }
      });

  // ══════════════════════════════════════════════════════════════════════════
  // Targeted refetch
  // ══════════════════════════════════════════════════════════════════════════

  /// Re-fetch wallet + escrow balances for a specific account on a given
  /// chain. Call this after a swap-in or swap-out completes.
  Future<void> refetchAccount(EvmChain chain, int accountIndex) => _logger.span(
    'refetchAccount(${chain.config.id}, $accountIndex)',
    () async {
      final keypair = await _auth.hd.getActiveEvmKey(
        accountIndex: accountIndex,
      );
      final smartAddress = chain.aa != null
          ? await chain.aa!.getSmartAccountAddress(keypair)
          : null;
      final address = smartAddress ?? keypair.address;
      final isSmartAddress = smartAddress != null;

      // Re-scan wallet balances for this address.
      final boltzTokens = chain.swaps?.chainInfo.tokens ?? {};
      final addrKey = address.eip55With0x.toLowerCase();
      _trackWalletAddress(
        chain: chain,
        address: address,
        keypair: keypair,
        accountIndex: accountIndex,
        isSmartAddress: isSmartAddress,
        reason: 'refetch:$accountIndex',
        snapshot: false,
      );
      final tracker = await _ensureChainTracker(chain);

      // Native balance.
      final nativeBalances = await chain.getBalancesBatch([address]);
      final nativeToken = Token.native(chain.config.chainId);
      final nativeBal = nativeBalances[address];
      final nativeMapKey = (addrKey, nativeToken.address.toLowerCase());
      if (nativeBal != null && nativeBal.value > BigInt.zero) {
        final dust = await _isDustBalance(chain, nativeBal);
        _walletItems[nativeMapKey] = FundsItem(
          address: address,
          keypair: keypair,
          accountIndex: accountIndex,
          token: nativeToken,
          balance: nativeBal,
          chain: chain,
          blockNumber: 0,
          isSmartAddress: isSmartAddress,
          dust: dust,
        );
        if (dust) _logUnsweepableDust(nativeBal, address, chain);
      } else {
        _walletItems.remove(nativeMapKey);
      }
      if (nativeBal != null) {
        tracker.seedBalance(address, nativeToken, nativeBal);
      }

      // ERC-20 balances.
      for (final tokenEntry in boltzTokens.entries) {
        try {
          final results = await chain.getERC20BalancesBatch([
            (owner: address, token: tokenEntry.value),
          ]);
          final balance = results.isNotEmpty ? results.first : null;
          final tokenKey = tokenEntry.value.eip55With0x.toLowerCase();
          final mapKey = (addrKey, tokenKey);
          if (balance != null && balance.value > BigInt.zero) {
            final dust = await _isDustBalance(chain, balance);
            _walletItems[mapKey] = FundsItem(
              address: address,
              keypair: keypair,
              accountIndex: accountIndex,
              token: balance.token,
              balance: balance,
              chain: chain,
              blockNumber: 0,
              isSmartAddress: isSmartAddress,
              dust: dust,
            );
            if (dust) _logUnsweepableDust(balance, address, chain);
          } else {
            _walletItems.remove(mapKey);
          }
          if (balance != null) {
            tracker.seedBalance(address, balance.token, balance);
          }
        } catch (e) {
          _logger.w(
            'Refetch ERC20 ${tokenEntry.key} failed for account '
            '$accountIndex on ${chain.config.id}: $e',
          );
        }
      }

      _walletSubject.add(_walletItems.values.toList());

      // Also refresh escrow balances for this account.
      await _scanEscrowContracts();
    },
  );

  // ══════════════════════════════════════════════════════════════════════════
  // Explicit live wallet balance tracking
  // ══════════════════════════════════════════════════════════════════════════

  /// Explicitly register an address for per-block monitoring on a chain.
  Future<void> trackAddress(
    EthereumAddress address,
    int accountIndex, {
    required String chain,
    String? reason,
  }) async {
    final evmChain = _evm.getChainById(chain);
    if (evmChain == null) return;
    final keypair = await _auth.hd.getActiveEvmKey(accountIndex: accountIndex);
    _trackWalletAddress(
      chain: evmChain,
      address: address,
      keypair: keypair,
      accountIndex: accountIndex,
      isSmartAddress:
          keypair.address.eip55With0x.toLowerCase() !=
          address.eip55With0x.toLowerCase(),
      reason: reason,
    );
    if (_started) {
      final tracker = await _ensureChainTracker(evmChain);
      tracker.start();
    }
  }

  // ── Stream construction ──────────────────────────────────────────────────

  void _buildFundsStream() {
    if (_streamsBuilt) return;
    _streamsBuilt = true;

    // Combined stream: latest wallet snapshot + latest escrow snapshot.
    fundsStream$ = Rx.combineLatest2(
      _walletSubject.stream,
      _escrowSubject.stream,
      (walletItems, escrowItems) => [...walletItems, ...escrowItems],
    ).shareReplay(maxSize: 1);

    displayBalance$ = fundsStream$
        .map(_groupByToken)
        .distinct()
        .shareReplay(maxSize: 1);
  }

  Future<void> _prepareBalanceTrackers() async {
    for (final chain in _evm.configuredChains) {
      await _ensureChainTracker(chain);
    }
  }

  Future<_ChainBalanceTracker> _ensureChainTracker(EvmChain chain) async {
    final existing = _chainTrackers[chain.config.id];
    if (existing != null) return existing;

    final tracker = _ChainBalanceTracker(
      chain: chain,
      logger: _logger,
      onBalance: _onWalletBalance,
      liveErc20TrackingEnabled: _liveErc20TrackingEnabled,
    );
    _chainTrackers[chain.config.id] = tracker;

    if (_liveErc20TrackingEnabled) {
      await _registerLiveErc20Tokens(chain, tracker);
    }

    return tracker;
  }

  Future<void> _registerLiveErc20Tokens(
    EvmChain chain,
    _ChainBalanceTracker tracker, {
    bool snapshot = false,
  }) async {
    final boltzTokens = chain.swaps?.chainInfo.tokens ?? {};
    for (final tokenAddress in boltzTokens.values) {
      try {
        final token = await chain.resolveToken(tokenAddress.eip55With0x);
        tracker.trackToken(token, snapshot: snapshot);
      } catch (e) {
        _logger.w(
          'Could not prepare balance token ${tokenAddress.eip55With0x} '
          'for ${chain.config.id}: $e',
        );
      }
    }
  }

  void _trackWalletAddress({
    required EvmChain chain,
    required EthereumAddress address,
    required EthPrivateKey keypair,
    required int accountIndex,
    required bool isSmartAddress,
    String? reason,
    bool snapshot = true,
  }) {
    final addressKey = address.eip55With0x.toLowerCase();
    _addressToAccountIndex[addressKey] = accountIndex;
    _walletAccounts[(chain.config.id, addressKey)] = _TrackedWalletAccount(
      keypair: keypair,
      accountIndex: accountIndex,
      isSmartAddress: isSmartAddress,
    );
    final tracker = _chainTrackers[chain.config.id];
    tracker?.trackAddress(address, reason: reason, snapshot: snapshot);
  }

  Future<void> _onWalletBalance(_WalletBalanceUpdate update) async {
    final addressKey = update.address.eip55With0x.toLowerCase();
    final account = _walletAccounts[(update.chain.config.id, addressKey)];
    if (account == null) {
      _logger.w(
        'Ignoring balance update for untracked address '
        '${update.address.eip55With0x} on ${update.chain.config.id}',
      );
      return;
    }

    final tokenKey = update.balance.token.address.toLowerCase();
    final mapKey = (addressKey, tokenKey);
    if (update.balance.value > BigInt.zero) {
      final dust = await _isDustBalance(update.chain, update.balance);
      _walletItems[mapKey] = FundsItem(
        address: update.address,
        keypair: account.keypair,
        accountIndex: account.accountIndex,
        token: update.balance.token,
        balance: update.balance,
        chain: update.chain,
        blockNumber: update.blockNumber,
        isSmartAddress: account.isSmartAddress,
        dust: dust,
      );
      if (dust) {
        _logUnsweepableDust(update.balance, update.address, update.chain);
      }
    } else {
      _walletItems.remove(mapKey);
    }

    _walletSubject.add(_walletItems.values.toList());
  }

  // ── Settlement event → escrow FundsItem refresh ─────────────────────────

  void _startEventListener() {
    // Use .stream (not .replayStream) — historical balances are already
    // covered by the startup scan. Replaying all past settlement events
    // triggers expensive HD key derivation for every counterparty tradeId.
    _eventSub = _userSubs.paymentEvents$.stream
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

    try {
      // Skip events whose tradeId doesn't belong to this user's HD tree.
      final accountIndex =
          await _tradeAccountAllocator.tryFindTradeAccountIndexByTradeId(
            event.tradeId,
          ) ??
          0;

      final keypair = await _auth.hd.getActiveEvmKey(
        accountIndex: accountIndex,
      );

      await _refreshEscrowBalances(
        contract: contract,
        chain: chain,
        keypair: keypair,
        accountIndex: accountIndex,
      );
    } catch (e) {
      _logger.e('Failed to refresh escrow balances after ${event.tradeId}: $e');
    }
  }

  /// Fetch all escrow balances for [keypair] from [contract] and emit
  /// the updated list via [_escrowSubject].
  Future<void> _refreshEscrowBalances({
    required SupportedEscrowContract contract,
    required EvmChain chain,
    required EthPrivateKey keypair,
    required int accountIndex,
  }) async {
    final balanceMap = await contract.allBalances(beneficiary: keypair.address);

    final smartAddr = chain.aa != null
        ? await chain.aa!.getSmartAccountAddress(keypair)
        : null;
    final effectiveAddress = smartAddr ?? keypair.address;
    final addrKey = effectiveAddress.eip55With0x.toLowerCase();

    // Remove stale entries for this address + contract.
    final contractKey = contract.address.eip55With0x.toLowerCase();
    _escrowItems.removeWhere(
      (key, item) =>
          key.$1 == addrKey &&
          item.contract?.address.eip55With0x.toLowerCase() == contractKey,
    );

    // Upsert non-zero balances.
    for (final entry in balanceMap.entries) {
      final token = await chain.resolveToken(entry.key.eip55With0x);
      final tokenKey = entry.key.eip55With0x.toLowerCase();
      final balance = TokenAmount(value: entry.value, token: token);
      if (balance.value > BigInt.zero) {
        final dust = await _isDustBalance(chain, balance);
        _escrowItems[(addrKey, tokenKey)] = FundsItem(
          address: effectiveAddress,
          keypair: keypair,
          accountIndex: accountIndex,
          token: token,
          balance: balance,
          chain: chain,
          blockNumber: 0,
          contract: contract,
          isSmartAddress: smartAddr != null,
          dust: dust,
        );
        if (dust) _logUnsweepableDust(balance, effectiveAddress, chain);
      }
    }

    _escrowSubject.add(_escrowItems.values.toList());
  }

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
        if (items.isEmpty) {
          _logger.d('FundsMonitor sweep: no items');
        } else {
          _logger.d(
            'FundsMonitor sweep: ${items.length} item(s)\n'
            '${items.map((i) => '  • ${i.chain.config.id} '
                '${i.token.tagId} '
                '${i.balance} '
                '@${i.address.eip55With0x} '
                '${i.isEscrowLocked
                    ? "[escrow: ${i.contract!.address.eip55With0x}]"
                    : i.isSmartAddress
                    ? "[smart-wallet]"
                    : "[EOA]"}').join('\n')}',
          );
        }
        for (final item in items) {
          if (item.dust) {
            _logger.d(
              'FundsMonitor skipped dust: ${item.chain.config.id} '
              '${item.token.tagId} ${item.balance.value} '
              '@${item.address.eip55With0x}',
            );
            continue;
          }
          if (!await _passesGates(item)) continue;

          await _executeSwapOut(item);
        }
      });

  Future<bool> _passesGates(FundsItem item) async {
    try {
      if (item.dust) return false;

      final config = await _userConfigStore.state;

      // Gate 1: enabled?
      if (!config.autoWithdrawEnabled) return false;

      // Guard: already swapping?
      if (_swapInProgress) return false;

      final destination = await item.chain.payments
          .resolveAutomaticInvoiceDestination();
      if (!destination.canCreateAutomatically) {
        _logger.w(destination.error ?? 'Cannot sweep without payout details');
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

      // Gate 5: fee ratio?
      try {
        final swapParams = await _swapOutParams(item);
        final quote = await item.chain.swapOutQuote(params: swapParams);
        final networkFees = quote.feeBreakdown.networkFees;
        final feeRatio =
            networkFees.value == BigInt.zero ||
                item.balance.value == BigInt.zero
            ? 0.0
            : networkFees.value.toDouble() / item.balance.value.toDouble();

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
    } catch (e, st) {
      _logger.e(
        'FundsMonitor: _passesGates threw for '
        '${item.chain.config.id} ${item.token.tagId} '
        '@${item.address.eip55With0x}: $e\n$st',
      );
      return false;
    }
  }

  Future<void> _executeSwapOut(FundsItem item) async {
    _swapInProgress = true;
    _logger.i(
      'FundsMonitor: executing swap-out — '
      '${item.chain.config.id} ${item.token.tagId} '
      '${item.balance} '
      '@${item.address.eip55With0x}'
      '${item.isEscrowLocked
          ? " [escrow: ${item.contract!.address.eip55With0x}]"
          : item.isSmartAddress
          ? " [smart-wallet]"
          : " [EOA]"}',
    );
    try {
      final swapOp = item.chain.swapOut(params: await _swapOutParams(item));

      await swapOp.execute();

      if (swapOp.state is SwapOutCompleted) {
        _logger.i(
          'FundsMonitor: swap-out completed on ${item.chain.config.id}',
        );

        // Immediately evict the swapped item so it disappears from the
        // fund list right away, even before the refetch confirms zero
        // balance on-chain.
        _removeFundsItem(item);

        // Re-fetch all balances for this account so the subjects reflect
        // the withdrawal.
        await refetchAccount(item.chain, item.accountIndex);
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
    }
  }

  // ── Param builder ────────────────────────────────────────────────────────

  /// Builds [SwapOutParams] for [item], including escrow `withdraw()` as a
  /// pre-lock call when the funds are locked in an escrow contract.
  ///
  /// Shared by the quote gate-check and the actual swap-out execution so that
  /// gas estimation sees the same call bundle as the real operation.
  Future<SwapOutParams> _swapOutParams(FundsItem item) async {
    Map<String, Call>? preLockCalls;
    if (item.isEscrowLocked) {
      final destination = await item.chain.getAccountAddress(item.keypair);
      final tokenAddress = EthereumAddress.fromHex(item.token.address);
      preLockCalls = {
        'withdraw': item.contract!.withdraw(
          WithdrawArgs(
            token: tokenAddress,
            ethKey: item.keypair,
            beneficiary: item.keypair.address,
            destination: destination,
          ),
        ),
      };
    }
    return SwapOutParams(
      evmKey: item.keypair,
      accountIndex: item.accountIndex,
      amountSpec: AmountSpec.input(item.balance),
      preLockCalls: preLockCalls,
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  @visibleForTesting
  Future<bool> isDustBalanceForTesting(EvmChain chain, TokenAmount balance) =>
      _isDustBalance(chain, balance);

  @visibleForTesting
  void seedWalletItemForTesting(FundsItem item) {
    _buildFundsStream();
    final addrKey = item.address.eip55With0x.toLowerCase();
    final tokenKey = item.token.address.toLowerCase();
    _walletItems[(addrKey, tokenKey)] = item;
    _walletSubject.add(_walletItems.values.toList());
  }

  Future<bool> _isDustBalance(EvmChain chain, TokenAmount balance) async {
    final quotedBridgeAmount = await _quoteBridgeAmountForDustCheck(
      chain,
      balance,
    );
    if (quotedBridgeAmount != null) {
      final minimum = await _swapOutMinimumFor(chain, quotedBridgeAmount.token);
      if (quotedBridgeAmount.value <= BigInt.zero) return true;
      return isDustBalanceForSwapOutLimits(
        quotedBridgeAmount,
        minimumSwapOutAmount: minimum,
      );
    }

    final minimum = await _swapOutMinimumFor(chain, balance.token);
    return isDustBalanceForSwapOutLimits(
      balance,
      minimumSwapOutAmount: minimum,
    );
  }

  @visibleForTesting
  static bool isDustBalanceForSwapOutLimits(
    TokenAmount balance, {
    TokenAmount? minimumSwapOutAmount,
  }) {
    if (balance.value <= BigInt.zero) return false;

    final roundedBalance = balance.roundDownToSats();
    if (roundedBalance.value <= BigInt.zero) return true;

    if (minimumSwapOutAmount == null) return false;
    if (minimumSwapOutAmount.token != balance.token) {
      throw ArgumentError(
        'Swap-out minimum token ${minimumSwapOutAmount.token.tagId} does not '
        'match balance token ${balance.token.tagId}',
      );
    }

    return roundedBalance < minimumSwapOutAmount.roundUpToSats();
  }

  Future<TokenAmount?> _swapOutMinimumFor(EvmChain chain, Token token) {
    if (chain.swaps == null) return Future.value(null);

    final key = (chain.config.id, token.address.toLowerCase());
    final cached = _swapOutMinimumCache[key];
    if (cached != null) return cached;

    final future = _fetchSwapOutMinimum(chain, token);
    _swapOutMinimumCache[key] = future;
    return future.then((minimum) {
      if (minimum == null) {
        _swapOutMinimumCache.remove(key);
      }
      return minimum;
    });
  }

  Future<TokenAmount?> _fetchSwapOutMinimum(EvmChain chain, Token token) async {
    try {
      final swaps = chain.swaps!;
      final tokenAddress = token.isNative
          ? null
          : EthereumAddress.fromHex(token.address);
      if (tokenAddress != null && !_isBridgeTokenAddress(chain, tokenAddress)) {
        return null;
      }

      final limits = await swaps.getSwapOutLimits(tokenAddress: tokenAddress);
      return TokenAmount.fromDenominated(limits.min, token).roundUpToSats();
    } catch (e) {
      _logger.w(
        'Failed to fetch Boltz swap-out minimum for ${chain.config.id} '
        '${token.tagId}: $e',
      );
      return null;
    }
  }

  Future<TokenAmount?> _quoteBridgeAmountForDustCheck(
    EvmChain chain,
    TokenAmount balance,
  ) async {
    final swaps = chain.swaps;
    if (swaps == null || !balance.token.isERC20) return null;

    final tokenIn = EthereumAddress.fromHex(balance.token.address);
    if (_isBridgeTokenAddress(chain, tokenIn)) return null;

    final bridgeAddress = _bridgeTokenAddress(chain);
    if (bridgeAddress == null) return null;

    try {
      final currency = swaps.nativeCurrency ?? swaps.chainInfo.chainKey;
      final res = await swaps.boltzClient.gBoltzCli.quoteCurrencyInGet(
        currency: currency,
        tokenIn: tokenIn.eip55With0x,
        tokenOut: bridgeAddress.eip55With0x,
        amountIn: balance.value.toString(),
      );
      if (!res.isSuccessful || res.body == null || res.body!.isEmpty) {
        throw StateError(
          'Boltz quote /in failed (HTTP ${res.statusCode}) '
          'for ${tokenIn.eip55With0x} → ${bridgeAddress.eip55With0x}.',
        );
      }

      final quoted = BigInt.tryParse(res.body!.first.quote);
      if (quoted == null) {
        throw StateError('Boltz quote was not an integer amount');
      }

      final bridgeToken = await chain.resolveToken(bridgeAddress.eip55With0x);
      return TokenAmount(value: quoted, token: bridgeToken);
    } catch (e) {
      _logger.w(
        'Failed to quote ${balance.token.tagId} balance into Boltz bridge '
        'token for dust check on ${chain.config.id}: $e',
      );
      return null;
    }
  }

  EthereumAddress? _bridgeTokenAddress(EvmChain chain) {
    final tokens = chain.swaps?.chainInfo.tokens;
    if (tokens == null || tokens.isEmpty) return null;
    return tokens.values.first;
  }

  bool _isBridgeTokenAddress(EvmChain chain, EthereumAddress tokenAddress) {
    final bridge = _bridgeTokenAddress(chain);
    if (bridge == null) return false;
    return bridge.eip55With0x.toLowerCase() ==
        tokenAddress.eip55With0x.toLowerCase();
  }

  void _logUnsweepableDust(
    TokenAmount balance,
    EthereumAddress address,
    EvmChain chain,
  ) {
    final rounded = balance.roundDownToSats();
    final isBtcLike =
        balance.token.isNative ||
        (balance.token.isERC20 &&
            _isBridgeTokenAddress(
              chain,
              EthereumAddress.fromHex(balance.token.address),
            ));
    final reason = isBtcLike
        ? '(${rounded.getInSats} whole sats, below swap-out minimum)'
        : '(quoted bridge BTC amount below swap-out minimum)';
    _logger.d(
      'FundsMonitor detected dust: '
      '${chain.config.id} ${balance.token.tagId} '
      '${balance.value} smallest-unit '
      '$reason '
      '@${address.eip55With0x}',
    );
  }

  /// Remove a specific [FundsItem] from the wallet or escrow maps and
  /// re-emit the updated lists. Used after a successful swap-out so the
  /// item disappears immediately rather than lingering until refetch.
  void _removeFundsItem(FundsItem item) {
    final addrKey = item.address.eip55With0x.toLowerCase();
    final tokenKey = item.token.address.toLowerCase();
    final mapKey = (addrKey, tokenKey);

    if (item.isEscrowLocked) {
      _escrowItems.remove(mapKey);
      _escrowSubject.add(_escrowItems.values.toList());
    } else {
      _walletItems.remove(mapKey);
      _walletSubject.add(_walletItems.values.toList());
    }
  }

  static List<TokenAmount> _groupByToken(List<FundsItem> items) {
    final map = <String, TokenAmount>{};
    for (final item in items) {
      if (item.dust) continue;
      final key = item.token.address.toLowerCase();
      map.update(
        key,
        (existing) => existing + item.balance,
        ifAbsent: () => item.balance,
      );
    }
    return map.values.toList();
  }
}

const _transferEventTopic =
    '0xddf252ad1be2c89b69c2b068fc378daa952ba7f163c4a11628f55a4df523b3ef';

class _TrackedWalletAccount {
  final EthPrivateKey keypair;
  final int accountIndex;
  final bool isSmartAddress;

  const _TrackedWalletAccount({
    required this.keypair,
    required this.accountIndex,
    required this.isSmartAddress,
  });
}

class _WalletBalanceUpdate {
  final EvmChain chain;
  final EthereumAddress address;
  final TokenAmount balance;
  final int blockNumber;

  const _WalletBalanceUpdate({
    required this.chain,
    required this.address,
    required this.balance,
    required this.blockNumber,
  });
}

class _TrackedAddress {
  final EthereumAddress address;
  final String? reason;

  const _TrackedAddress({required this.address, this.reason});

  @override
  bool operator ==(Object other) =>
      other is _TrackedAddress &&
      other.address.eip55With0x.toLowerCase() ==
          address.eip55With0x.toLowerCase();

  @override
  int get hashCode => address.eip55With0x.toLowerCase().hashCode;
}

class _ChainBalanceTracker {
  final EvmChain _chain;
  final CustomLogger _logger;
  final Future<void> Function(_WalletBalanceUpdate update) _onBalance;

  final Duration blockCoalesceDuration = const Duration(seconds: 2);
  final Duration expansionDebounceDuration = const Duration(milliseconds: 100);
  final int batchChunkSize = 10;

  final Set<_TrackedAddress> _trackedAddresses = {};
  final Set<Token> _trackedTokens = {};
  final Map<(String, String), TokenAmount> _balanceCache = {};
  bool _liveErc20TrackingEnabled;

  int? _lastProcessedBlock;
  StreamSubscription<int>? _blockSub;
  Timer? _coalesceTimer;
  int? _coalesceFirst;
  int? _coalesceLast;
  Timer? _expansionTimer;
  final Set<_TrackedAddress> _pendingAddresses = {};
  final Set<Token> _pendingTokens = {};
  bool _processing = false;
  bool _disposed = false;

  _ChainBalanceTracker({
    required EvmChain chain,
    required CustomLogger logger,
    required Future<void> Function(_WalletBalanceUpdate update) onBalance,
    required bool liveErc20TrackingEnabled,
  }) : _chain = chain,
       _logger = logger.scope('balance-tracker.${chain.config.id}'),
       _onBalance = onBalance,
       _liveErc20TrackingEnabled = liveErc20TrackingEnabled;

  void trackAddress(
    EthereumAddress address, {
    String? reason,
    bool snapshot = true,
  }) {
    final tracked = _TrackedAddress(address: address, reason: reason);
    if (!_trackedAddresses.add(tracked)) return;

    _logger.d('trackAddress(${address.eip55With0x}, reason=$reason)');
    if (snapshot) {
      _pendingAddresses.add(tracked);
      _scheduleExpansionFlush();
    }
  }

  void trackToken(Token token, {bool snapshot = true}) {
    if (!_liveErc20TrackingEnabled) return;
    final added = _trackedTokens.add(token);
    if (!added && !snapshot) return;

    if (added) {
      _logger.d('trackToken(${token.tagId})');
    }
    if (snapshot) {
      _pendingTokens.add(token);
      _scheduleExpansionFlush();
    }
  }

  void setLiveErc20TrackingEnabled(bool enabled) {
    if (_liveErc20TrackingEnabled == enabled) return;
    _liveErc20TrackingEnabled = enabled;
    if (!enabled) {
      _trackedTokens.clear();
      _pendingTokens.clear();
    }
  }

  void seedBalance(EthereumAddress address, Token token, TokenAmount balance) {
    _balanceCache[(
          address.eip55With0x.toLowerCase(),
          token.address.toLowerCase(),
        )] =
        balance;
  }

  void start() {
    if (_blockSub != null || _disposed) return;
    _logger.i('Starting chain balance tracker');
    _blockSub = _chain.newBlocks().listen(
      _onNewBlock,
      onError: (Object e) => _logger.w('Block stream error: $e'),
    );
  }

  Future<void> stop() async {
    await _blockSub?.cancel();
    _blockSub = null;
    _coalesceTimer?.cancel();
    _coalesceTimer = null;
    _coalesceFirst = null;
    _coalesceLast = null;
    _expansionTimer?.cancel();
    _expansionTimer = null;
  }

  Future<void> dispose() async {
    _disposed = true;
    await stop();
    _trackedAddresses.clear();
    _trackedTokens.clear();
    _pendingAddresses.clear();
    _pendingTokens.clear();
    _balanceCache.clear();
  }

  void _scheduleExpansionFlush() {
    if (_disposed) return;
    _expansionTimer?.cancel();
    _expansionTimer = Timer(expansionDebounceDuration, _flushExpansion);
  }

  Future<void> _flushExpansion() => _logger.span('_flushExpansion', () async {
    if (_disposed) return;

    final newAddresses = Set<_TrackedAddress>.of(_pendingAddresses);
    final newTokens = Set<Token>.of(_pendingTokens);
    _pendingAddresses.clear();
    _pendingTokens.clear();

    if (newAddresses.isEmpty && newTokens.isEmpty) return;

    try {
      final blockNumber = await _chain.getBlockNumber();
      final batch = RpcBatch();

      final nativeAddrs = newAddresses.map((a) => a.address).toList();
      final nativeResult = nativeAddrs.isNotEmpty
          ? batch.getBalances(nativeAddrs, chainId: _chain.config.chainId)
          : null;

      final addressesToSnapshot = <EthereumAddress>{
        ...newAddresses.map((a) => a.address),
      };
      final tokensToSnapshot = <Token>{..._trackedTokens};
      if (newTokens.isNotEmpty) {
        for (final existing in _trackedAddresses) {
          addressesToSnapshot.add(existing.address);
        }
      }

      final erc20Pairs =
          <({EthereumAddress owner, EthereumAddress token, Token meta})>[];
      for (final address in addressesToSnapshot) {
        for (final token in tokensToSnapshot) {
          final key = (
            address.eip55With0x.toLowerCase(),
            token.address.toLowerCase(),
          );
          final isNewAddress = newAddresses.any(
            (tracked) =>
                tracked.address.eip55With0x.toLowerCase() ==
                address.eip55With0x.toLowerCase(),
          );
          if (_balanceCache.containsKey(key) &&
              !isNewAddress &&
              !newTokens.contains(token)) {
            continue;
          }
          erc20Pairs.add((
            owner: address,
            token: EthereumAddress.fromHex(token.address),
            meta: token,
          ));
        }
      }

      final erc20Result = erc20Pairs.isNotEmpty
          ? batch.getERC20Balances(
              erc20Pairs
                  .map((p) => (owner: p.owner, token: p.token))
                  .toList(growable: false),
              tokenResolver: _chain.resolveToken,
            )
          : null;

      if (!batch.isEmpty) {
        await _chain.executeBatch(batch);

        if (nativeResult != null) {
          for (final entry in nativeResult.value.entries) {
            await _emitNativeBalance(entry.key, entry.value, blockNumber);
          }
        }

        if (erc20Result != null) {
          for (var i = 0; i < erc20Pairs.length; i++) {
            final balance = erc20Result.value[i];
            if (balance == null) continue;
            await _emitErc20Balance(
              erc20Pairs[i].owner,
              erc20Pairs[i].meta,
              balance,
              blockNumber,
            );
          }
        }
      }

      _lastProcessedBlock ??= blockNumber;
    } catch (e) {
      _logger.w('Expansion snapshot failed: $e');
    }
  });

  void _onNewBlock(int blockNumber) {
    _coalesceFirst ??= blockNumber;
    _coalesceLast = blockNumber;

    if (blockCoalesceDuration == Duration.zero) {
      _flushCoalescedBlocks();
      return;
    }

    _coalesceTimer?.cancel();
    _coalesceTimer = Timer(blockCoalesceDuration, _flushCoalescedBlocks);
  }

  void _flushCoalescedBlocks() {
    final from = _coalesceFirst;
    final to = _coalesceLast;
    _coalesceFirst = null;
    _coalesceLast = null;
    _coalesceTimer?.cancel();

    if (from == null || to == null) return;
    if (_trackedAddresses.isEmpty) return;

    unawaited(_processBlockRange(from, to));
  }

  Future<void> _processBlockRange(int from, int to) async {
    if (_processing || _disposed) return;
    _processing = true;

    try {
      await _logger.span('processBlockRange($from..$to)', () async {
        await _refreshNativeBalances(to);
        if (_liveErc20TrackingEnabled) {
          await _refreshErc20Balances(from, to);
        }
        _lastProcessedBlock = to;
      });
    } catch (e) {
      _logger.w('Block range processing failed ($from..$to): $e');
    } finally {
      _processing = false;
    }
  }

  Future<void> _refreshNativeBalances(int blockNumber) =>
      _logger.span('_refreshNativeBalances', () async {
        if (_trackedAddresses.isEmpty) return;

        final trackedLower = {
          for (final address in _trackedAddresses)
            address.address.eip55With0x.toLowerCase(): address.address,
        };

        Set<EthereumAddress> dirty;

        try {
          final block = await _chain.client.makeRPCCall<Map<String, dynamic>>(
            'eth_getBlockByNumber',
            ['0x${blockNumber.toRadixString(16)}', true],
          );

          final transactions =
              (block['transactions'] as List<dynamic>?) ?? const [];
          dirty = {};
          for (final tx in transactions) {
            if (tx is! Map<String, dynamic>) continue;
            final from = (tx['from'] as String?)?.toLowerCase();
            final to = (tx['to'] as String?)?.toLowerCase();
            if (from != null && trackedLower.containsKey(from)) {
              dirty.add(trackedLower[from]!);
            }
            if (to != null && trackedLower.containsKey(to)) {
              dirty.add(trackedLower[to]!);
            }
          }
        } catch (e) {
          _logger.w(
            'Failed to inspect block $blockNumber txs, '
            'falling back to full refresh: $e',
          );
          dirty = trackedLower.values.toSet();
        }

        if (dirty.isEmpty) return;

        for (final chunk in _chunked(dirty.toList(), batchChunkSize)) {
          final balances = await _chain.getBalancesBatch(chunk);
          for (final entry in balances.entries) {
            await _emitNativeBalance(entry.key, entry.value, blockNumber);
          }
        }
      });

  Future<void> _refreshErc20Balances(int from, int to) =>
      _logger.span('_refreshErc20Balances', () async {
        if (_trackedTokens.isEmpty || _trackedAddresses.isEmpty) return;

        final scanFrom = (_lastProcessedBlock != null)
            ? _lastProcessedBlock! + 1
            : from;
        if (scanFrom > to) return;

        final trackedAddrPadded = <String, EthereumAddress>{};
        for (final address in _trackedAddresses) {
          trackedAddrPadded[_padAddress(address.address)] = address.address;
        }

        final tokenContracts = _trackedTokens
            .map((token) => EthereumAddress.fromHex(token.address))
            .toList(growable: false);

        final dirtyPairs = <(EthereumAddress, Token)>{};
        final paddedList = trackedAddrPadded.keys.toList(growable: false);

        for (final topicIndex in [1, 2]) {
          try {
            final topics = <List<String?>>[
              [_transferEventTopic],
              topicIndex == 1 ? paddedList : <String?>[],
              topicIndex == 2 ? paddedList : <String?>[],
            ];

            for (final tokenContract in tokenContracts) {
              final logs = await _chain.getLogs(
                FilterOptions(
                  address: tokenContract,
                  topics: topics,
                  fromBlock: BlockNum.exact(scanFrom),
                  toBlock: BlockNum.exact(to),
                ),
                batch: true,
                batchHint: EvmLogsBatchHint(
                  requestKey: 'funds-monitor-transfer-t$topicIndex',
                  dynamicTopicIndex: topicIndex,
                ),
              );

              final token = _trackedTokens.firstWhere(
                (t) =>
                    t.address.toLowerCase() ==
                    tokenContract.eip55With0x.toLowerCase(),
              );

              for (final log in logs) {
                final logTopics = log.topics;
                if (logTopics == null || logTopics.length < 3) continue;

                final fromAddress = trackedAddrPadded[logTopics[1]];
                final toAddress = trackedAddrPadded[logTopics[2]];
                if (fromAddress != null) dirtyPairs.add((fromAddress, token));
                if (toAddress != null) dirtyPairs.add((toAddress, token));
              }
            }
          } catch (e) {
            _logger.w('ERC20 log scan failed (topicIndex=$topicIndex): $e');
            for (final address in _trackedAddresses) {
              for (final token in _trackedTokens) {
                dirtyPairs.add((address.address, token));
              }
            }
          }
        }

        if (dirtyPairs.isEmpty) return;

        final pairsList = dirtyPairs.toList();
        for (final chunk in _chunked(pairsList, batchChunkSize)) {
          final results = await _chain.getERC20BalancesBatch(
            chunk
                .map(
                  (pair) => (
                    owner: pair.$1,
                    token: EthereumAddress.fromHex(pair.$2.address),
                  ),
                )
                .toList(growable: false),
          );
          for (var i = 0; i < chunk.length; i++) {
            final balance = results[i];
            if (balance == null) continue;
            await _emitErc20Balance(chunk[i].$1, chunk[i].$2, balance, to);
          }
        }
      });

  Future<void> _emitNativeBalance(
    EthereumAddress address,
    TokenAmount balance,
    int blockNumber,
  ) async {
    final token = Token.native(_chain.config.chainId);
    await _emitBalance(address, token, balance, blockNumber);
  }

  Future<void> _emitErc20Balance(
    EthereumAddress address,
    Token token,
    TokenAmount balance,
    int blockNumber,
  ) async {
    await _emitBalance(address, token, balance, blockNumber);
  }

  Future<void> _emitBalance(
    EthereumAddress address,
    Token token,
    TokenAmount balance,
    int blockNumber,
  ) async {
    final key = (
      address.eip55With0x.toLowerCase(),
      token.address.toLowerCase(),
    );
    final previous = _balanceCache[key];
    _balanceCache[key] = balance;

    if (previous != null && previous.value == balance.value) return;

    await _onBalance(
      _WalletBalanceUpdate(
        chain: _chain,
        address: address,
        balance: balance,
        blockNumber: blockNumber,
      ),
    );
  }

  static String _padAddress(EthereumAddress address) {
    final hex = address.eip55With0x.toLowerCase().replaceFirst('0x', '');
    return '0x${hex.padLeft(64, '0')}';
  }

  static List<List<T>> _chunked<T>(List<T> list, int size) {
    final chunks = <List<T>>[];
    for (var i = 0; i < list.length; i += size) {
      final end = (i + size < list.length) ? i + size : list.length;
      chunks.add(list.sublist(i, end));
    }
    return chunks;
  }
}
