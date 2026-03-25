import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:rxdart/rxdart.dart';

import '../../config.dart';
import '../../datasources/boltz/boltz.dart';
import '../../injection.dart';
import '../../util/main.dart';
import '../auth/auth.dart';
import '../background_worker/background_worker.dart';
import '../escrow/operations/fund/escrow_fund_recoverer.dart';
import '../nwc/nwc.dart';
import '../payments/payments.dart';
import 'capabilities/aa_capability.dart';
import 'capabilities/boltz_swap_provider.dart';
import 'capabilities/configured_evm_chain.dart';
import 'capabilities/escrow_capability.dart';
import 'chain/evm_chain.dart';
import 'chain/operations/swap_out/swap_out_operation.dart';
import 'operations/swap_out/swap_out_models.dart';
import 'operations/swap_out/swap_out_quote_service.dart';
import 'operations/swap_recoverer.dart';

@Singleton()
class Evm {
  final CustomLogger _logger;
  final HostrConfig _config;
  final Auth _auth;
  CustomLogger get logger => _logger;

  BehaviorSubject<TokenAmount>? _balanceSubject;
  StreamSubscription<TokenAmount>? _balanceSubscription;

  /// All configured EVM chains, assembled with their capabilities.
  late final List<ConfiguredEvmChain> configuredChains;

  /// The shared Boltz client — `null` if no Boltz config is present.
  BoltzClient? _boltzClient;
  BoltzClient? get boltzClient => _boltzClient;

  Evm(HostrConfig config, Auth auth, CustomLogger logger)
    : _config = config,
      _auth = auth,
      _logger = logger.scope('evm') {
    configuredChains = _buildChains();
  }

  List<ConfiguredEvmChain> _buildChains() {
    final evmConfig = _config.evmConfig;

    // Create Boltz client if configured.
    if (evmConfig.boltz != null) {
      _boltzClient = BoltzClient(evmConfig.boltz!, _logger);
    }

    return evmConfig.chains.map((chainConfig) {
      final chain = EvmChain(config: chainConfig, auth: _auth, logger: _logger);

      // AA capability — present if the chain config has AA fields.
      final aa = chainConfig.accountAbstraction != null
          ? AACapability(
              aaConfig: chainConfig.accountAbstraction!,
              chainId: chainConfig.chainId,
              nodeRpcUrl: chainConfig.rpcUrl,
              logger: _logger,
            )
          : null;

      // Escrow is always available.
      final escrow = EscrowCapability(chain: chain, logger: _logger);

      return ConfiguredEvmChain(
        chain: chain,
        aa: aa,
        escrow: escrow,
        // Swaps are attached later in [init] after Boltz discovery.
      );
    }).toList();
  }

  /// Initialize Boltz discovery and attach swap providers to matching chains.
  ///
  /// Call this once after construction. It's separated from the constructor
  /// because it's async.
  Future<void> init() => _logger.span('init', () async {
    if (_boltzClient == null) {
      _logger.i('No Boltz config — skipping swap discovery');
      return;
    }

    try {
      final discovered = await _boltzClient!.discoverChains();
      for (final info in discovered) {
        final match = configuredChains
            .where((c) => c.config.chainId == info.chainId)
            .firstOrNull;
        if (match == null) {
          _logger.d(
            'Boltz chain ${info.chainKey} '
            '(chainId=${info.chainId}) '
            'has no matching chain config — skipping',
          );
          continue;
        }

        // Attach swap provider.
        final swaps = BoltzSwapProvider(
          boltzClient: _boltzClient!,
          chainInfo: info,
          chain: match.chain,
          logger: _logger,
          nativeCurrency: match.config.boltzCurrency,
        );

        // Replace the configured chain with one that includes swaps.
        final idx = configuredChains.indexOf(match);
        configuredChains[idx] = ConfiguredEvmChain(
          chain: match.chain,
          aa: match.aa,
          swaps: swaps,
          escrow: match.escrow,
        );

        _logger.i(
          'Attached Boltz swap provider for ${info.chainKey} '
          'to chain ${match.config.id}',
        );
      }
    } catch (e) {
      _logger.e('Boltz discovery failed (chains remain swap-less): $e');
    }
  });

  void _ensureBalanceSubscription() =>
      _logger.spanSync('_ensureBalanceSubscription', () {
        if (_balanceSubscription != null) return;

        final streams = configuredChains
            .map((c) => c.chain.subscribeTotalBalance())
            .toList();

        final combined = Rx.combineLatestList<TokenAmount>(streams).map(
          (balances) => balances.fold<TokenAmount>(
            TokenAmount.zero(rbtc),
            (sum, value) => sum + value,
          ),
        );

        _balanceSubscription = combined.distinct().listen(
          (total) => _balanceSubject?.add(total),
          onError: (error) => _logger.w('Balance subscription error: $error'),
        );
      });

  Future<TokenAmount> getBalance() => _logger.span('getBalance', () async {
    TokenAmount totalBalance = TokenAmount.zero(rbtc);
    for (var c in configuredChains) {
      try {
        final chainBalance = await c.chain.getTotalBalance();
        totalBalance += chainBalance;
      } catch (e) {
        _logger.w('Failed to get balance from chain ${c.config.id}: $e');
      }
    }
    return totalBalance;
  });

  ConfiguredEvmChain getChainForEscrowService(EscrowService service) =>
      _logger.spanSync('getChainForEscrowService', () {
        // TODO: match by chain ID from escrow service metadata.
        // For now return the first chain.
        if (configuredChains.isEmpty) {
          throw StateError(
            'No EVM chains configured for escrow service ${service.id}',
          );
        }
        return configuredChains.first;
      });

  /// Look up a configured chain by chain ID.
  ConfiguredEvmChain? getChainByChainId(int chainId) {
    return configuredChains
        .where((c) => c.config.chainId == chainId)
        .firstOrNull;
  }

  /// Look up a configured chain by config ID string.
  ConfiguredEvmChain? getChainById(String id) {
    return configuredChains.where((c) => c.config.id == id).firstOrNull;
  }

  ValueStream<TokenAmount> subscribeBalance() {
    _balanceSubject ??= BehaviorSubject<TokenAmount>(
      onListen: _ensureBalanceSubscription,
    );
    return _balanceSubject!.stream;
  }

  void resetBalance() => _logger.spanSync('resetBalance', () {
    _balanceSubscription?.cancel();
    _balanceSubscription = null;
    if (_balanceSubject?.hasListener ?? false) {
      _ensureBalanceSubscription();
    }
  });

  Future<void> reset() => _logger.span('reset', () async {
    await _balanceSubscription?.cancel();
    _balanceSubscription = null;
    _balanceSubject = null;
  });

  Future<void> dispose() => _logger.span('dispose', () async {
    await _balanceSubscription?.cancel();
    _balanceSubscription = null;
    for (final c in configuredChains) {
      await c.chain.dispose();
    }
    await _balanceSubject?.close();
    _balanceSubject = null;
  });

  bool _isRecovering = false;

  /// Create swap-out operations for every funded address across all chains
  /// that have a Boltz swap provider.
  ///
  /// Returns the list of created [EvmSwapOutOperation]s (one per funded
  /// address that meets the optional [minimumBalance]).
  ///
  /// Scans both **native** balances and **ERC-20 token** balances for every
  /// token listed in the chain's Boltz discovery (`chainInfo.tokens`).
  Future<List<EvmSwapOutOperation>> swapOutAll({TokenAmount? minimumBalance}) =>
      _logger.span('swapOutAll', () async {
        final ops = <EvmSwapOutOperation>[];
        for (final configured in configuredChains) {
          if (configured.swaps == null) continue;

          // ── Native-asset sweep ──────────────────────────────────────
          final funded = await configured.chain.getAddressesWithBalance();
          for (final entry in funded) {
            if (minimumBalance != null && entry.balance < minimumBalance) {
              continue;
            }
            final evmKey = await _auth.hd.getActiveEvmKey(
              accountIndex: entry.accountIndex,
            );
            ops.add(
              configured.swapOut(
                params: SwapOutParams(
                  evmKey: evmKey,
                  accountIndex: entry.accountIndex,
                  amount: null,
                ),
                auth: _auth,
                logger: _logger,
                nwc: getIt<Nwc>(),
                payments: getIt<Payments>(),
                quoteService: getIt<SwapOutQuoteService>(),
              ),
            );
          }

          // ── ERC-20 token sweep ──────────────────────────────────────
          final boltzTokens = configured.swaps!.chainInfo.tokens;
          if (boltzTokens.isEmpty) continue;

          final tokenFunded = await configured.chain
              .getAddressesWithTokenBalances(boltzTokens);

          for (final entry in tokenFunded) {
            if (minimumBalance != null && entry.balance < minimumBalance) {
              continue;
            }
            final evmKey = await _auth.hd.getActiveEvmKey(
              accountIndex: entry.accountIndex,
            );
            // Pass the full ERC-20 balance as `amount` so the swap-out
            // operation knows which token to lock (via amount.token).
            ops.add(
              configured.swapOut(
                params: SwapOutParams(
                  evmKey: evmKey,
                  accountIndex: entry.accountIndex,
                  amount: entry.balance,
                ),
                auth: _auth,
                logger: _logger,
                nwc: getIt<Nwc>(),
                payments: getIt<Payments>(),
                quoteService: getIt<SwapOutQuoteService>(),
              ),
            );
          }
        }
        return ops;
      });

  Future<int> recoverStaleOperations({
    bool isBackground = false,
    OnBackgroundProgress? onProgress,
  }) => _logger.span('recoverStaleOperations', () async {
    if (_isRecovering) {
      _logger.d('recoverStaleOperations already in progress — skipping');
      return 0;
    }
    _isRecovering = true;
    try {
      final swapRecoverer = getIt<SwapRecoverer>();
      final escrowRecoverer = getIt<EscrowFundRecoverer>();
      final swapsResolved = await swapRecoverer.recoverAll(
        isBackground: isBackground,
        onProgress: onProgress,
      );
      final escrowsResolved = await escrowRecoverer.recoverAll(
        isBackground: isBackground,
        onProgress: onProgress,
      );
      return swapsResolved + escrowsResolved;
    } catch (e) {
      _logger.e('Evm.recoverStaleOperations failed: $e');
      return 0;
    } finally {
      _isRecovering = false;
    }
  });
}
