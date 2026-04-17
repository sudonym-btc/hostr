import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Filter;
import 'package:rxdart/rxdart.dart';
import 'package:wallet/wallet.dart';
import 'package:web3dart/web3dart.dart' show EthPrivateKey;

import '../../../../config.dart';
import '../../../../injection.dart';
import '../../../../util/custom_logger.dart';
import '../../../auth/auth.dart';
import '../../../escrow/supported_escrow_contract/supported_escrow_contract.dart';
import '../../../escrows/escrows.dart';
import '../../../trade_account_allocator/trade_account_allocator.dart';
import '../../../user_config/user_config_store.dart';
import '../../../user_subscriptions/user_subscriptions.dart';
import '../../chain/evm_chain.dart';
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
/// There is **no ongoing per-block monitoring** by default. Balances are
/// refreshed only when explicitly requested via [refetchAccount] (e.g. after
/// a swap-in or swap-out completes).
///
/// For future use, [trackAddress]/[untrackAddress] and [trackToken] delegate
/// to [EvmBalanceMonitor] on the relevant chain for per-block monitoring, but
/// this is unused in the current flow.
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

  bool _swapInProgress = false;
  StreamSubscription? _eventSub;
  StreamSubscription? _sweepSub;

  Completer<void>? _scanCompleter;

  bool _started = false;

  FundsMonitorService(
    this._evm,
    this._userSubs,
    this._auth,
    this._tradeAccountAllocator,
    this._stateStore,
    this._userConfigStore,
    CustomLogger logger,
  ) : _logger = logger.scope('funds-monitor');

  // ── Lifecycle ────────────────────────────────────────────────────────────

  /// Start the service and kick off the initial [scan].
  ///
  /// 1. Builds the funds observable streams.
  /// 2. Runs a one-time [scan] (HD balance + escrow contract balances).
  /// 3. Subscribes to escrow settlement events for reactive refresh.
  /// 4. Starts sweep listener.
  ///
  /// Idempotent.
  void start() => _logger.spanSync('start', () {
    if (_started) return;
    _started = true;

    _buildFundsStream();
    _scanCompleter = Completer<void>();
    scan().then(
      (_) {
        if (!(_scanCompleter?.isCompleted ?? true)) _scanCompleter?.complete();
      },
      onError: (Object e) {
        _logger.w('Initial scan failed: $e');
        if (!(_scanCompleter?.isCompleted ?? true)) _scanCompleter?.complete();
      },
    );
    _startEventListener();
    _startSweepListener();
  });

  /// Await the initial [scan]. Returns immediately if already completed or
  /// not yet started.
  Future<void> seedAndAwait() async {
    await _scanCompleter?.future;
  }

  /// Stop the service. Safe to call when not started.
  Future<void> stop() => _logger.span('stop', () async {
    if (!_started) return;
    _started = false;

    await _eventSub?.cancel();
    _eventSub = null;
    await _sweepSub?.cancel();
    _sweepSub = null;
    _swapInProgress = false;

    _logger.d('FundsMonitorService stopped');
  });

  /// Reset state and restart (e.g. after user logs out → log in).
  Future<void> reset() => _logger.span('reset', () async {
    await stop();
    _walletItems.clear();
    _walletSubject.add([]);
    _escrowItems.clear();
    _escrowSubject.add([]);
    _addressToAccountIndex.clear();
    _scanCompleter = null;
  });

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
    final boltzTokens = chain.swaps?.chainInfo.tokens ?? {};
    final (:nativeFunded, :tokenFunded) = await chain.scanAllHDBalances(
      tokens: boltzTokens,
    );

    for (final entry in nativeFunded) {
      final key = entry.address.eip55With0x.toLowerCase();
      _addressToAccountIndex[key] = entry.accountIndex;
      final nativeToken = Token.native(chain.config.chainId);
      final mapKey = (key, nativeToken.address.toLowerCase());
      _walletItems[mapKey] = FundsItem(
        address: entry.address,
        keypair: entry.keypair,
        accountIndex: entry.accountIndex,
        token: nativeToken,
        balance: entry.balance,
        chain: chain,
        blockNumber: 0,
        isSmartAddress: entry.isSmartAddress,
      );
    }

    for (final entry in tokenFunded) {
      final key = entry.address.eip55With0x.toLowerCase();
      _addressToAccountIndex[key] = entry.accountIndex;
      final tokenKey = entry.tokenAddress.eip55With0x.toLowerCase();
      final mapKey = (key, tokenKey);
      _walletItems[mapKey] = FundsItem(
        address: entry.address,
        keypair: entry.keypair,
        accountIndex: entry.accountIndex,
        token: entry.balance.token,
        balance: entry.balance,
        chain: chain,
        blockNumber: 0,
        isSmartAddress: entry.isSmartAddress,
      );
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

      // Native balance.
      final nativeBalances = await chain.getBalancesBatch([address]);
      final nativeToken = Token.native(chain.config.chainId);
      final nativeBal = nativeBalances[address];
      final nativeMapKey = (addrKey, nativeToken.address.toLowerCase());
      if (nativeBal != null && nativeBal.value > BigInt.zero) {
        _walletItems[nativeMapKey] = FundsItem(
          address: address,
          keypair: keypair,
          accountIndex: accountIndex,
          token: nativeToken,
          balance: nativeBal,
          chain: chain,
          blockNumber: 0,
          isSmartAddress: isSmartAddress,
        );
      } else {
        _walletItems.remove(nativeMapKey);
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
            _walletItems[mapKey] = FundsItem(
              address: address,
              keypair: keypair,
              accountIndex: accountIndex,
              token: balance.token,
              balance: balance,
              chain: chain,
              blockNumber: 0,
              isSmartAddress: isSmartAddress,
            );
          } else {
            _walletItems.remove(mapKey);
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
  // Track / untrack (delegates to EvmBalanceMonitor — unused for now)
  // ══════════════════════════════════════════════════════════════════════════

  /// Register an address for per-block monitoring on a specific chain.
  ///
  /// This starts the chain's [EvmBalanceMonitor] if not already running and
  /// adds the address to its tracked set. Currently unused — the default
  /// flow uses [scan] + [refetchAccount] instead.
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
      _escrowItems[(addrKey, tokenKey)] = FundsItem(
        address: effectiveAddress,
        keypair: keypair,
        accountIndex: accountIndex,
        token: token,
        balance: TokenAmount(value: entry.value, token: token),
        chain: chain,
        blockNumber: 0,
        contract: contract,
        isSmartAddress: smartAddr != null,
      );
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
          if (!await _passesGates(item)) continue;

          await _executeSwapOut(item);
        }
      });

  Future<bool> _passesGates(FundsItem item) async {
    try {
      final config = await _userConfigStore.state;

      // Gate 1: enabled?
      if (!config.autoWithdrawEnabled) return false;

      // Guard: already swapping?
      if (_swapInProgress) return false;

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
