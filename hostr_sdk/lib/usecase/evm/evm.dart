import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:models/main.dart';

import '../../config.dart';
import '../../datasources/boltz/boltz.dart';
import '../../injection.dart';
import '../../util/main.dart';
import '../auth/auth.dart';
import '../background_worker/background_worker.dart';
import '../nwc/nwc.dart';
import '../payments/payments.dart';
import 'capabilities/aa_capability.dart';
import 'capabilities/boltz_swap_provider.dart';
import 'chain/evm_chain.dart';
import 'chain/operations/swap_out/swap_out_operation.dart';
import 'operations/swap_out/swap_out_models.dart';
import 'operations/swap_quote_service.dart';
import 'operations/swap_recoverer.dart';

@Singleton()
class Evm {
  final CustomLogger _logger;
  final HostrConfig _config;
  final Auth _auth;
  CustomLogger get logger => _logger;

  /// All configured EVM chains, assembled with their capabilities.
  late final List<EvmChain> configuredChains;

  /// The shared Boltz client — `null` if no Boltz config is present.
  BoltzClient? _boltzClient;
  BoltzClient? get boltzClient => _boltzClient;

  Evm(HostrConfig config, Auth auth, CustomLogger logger)
    : _config = config,
      _auth = auth,
      _logger = logger.scope('evm') {
    configuredChains = _buildChains();
  }

  List<EvmChain> _buildChains() {
    final evmConfig = _config.evmConfig;

    // Create Boltz client if configured.
    if (evmConfig.boltz != null) {
      _boltzClient = BoltzClient(evmConfig.boltz!, _logger);
    }

    return evmConfig.chains.map((chainConfig) {
      // AA capability — present if the chain config has AA fields.
      final aa = chainConfig.accountAbstraction != null
          ? AACapability(
              aaConfig: chainConfig.accountAbstraction!,
              chainId: chainConfig.chainId,
              nodeRpcUrl: chainConfig.rpcUrl,
              logger: _logger,
            )
          : null;

      // Chain owns transport + capabilities (escrow is auto-created).
      // Swaps are attached later in [init] after Boltz discovery.
      return EvmChain(
        config: chainConfig,
        auth: _auth,
        logger: _logger,
        aa: aa,
        quoteService: getIt<SwapQuoteService>(),
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

    if (!getIt.isRegistered<BoltzClient>()) {
      getIt.registerSingleton<BoltzClient>(_boltzClient!);
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

        // Attach swap provider directly.
        final swaps = BoltzSwapProvider(
          boltzClient: _boltzClient!,
          chainInfo: info,
          chain: match,
          logger: _logger,
          nativeCurrency: match.config.boltzCurrency,
        );
        match.swaps = swaps;

        // Register Boltz ERC-20 tokens in the balance monitor.
        // Resolves decimals on-chain and caches them in the token registry.
        for (final entry in info.tokens.entries) {
          final token = await match.resolveToken(entry.value.eip55With0x);
          match.balanceMonitor.trackToken(token);
        }

        _logger.i(
          'Attached Boltz swap provider for ${info.chainKey} '
          'to chain ${match.config.id}',
        );
      }
    } catch (e) {
      _logger.e('Boltz discovery failed (chains remain swap-less): $e');
    }

    // Start each chain's balance monitor after Boltz tokens are registered.
    for (final chain in configuredChains) {
      chain.balanceMonitor.start();
    }
  });

  EvmChain getChainForEscrowService(EscrowService service) =>
      _logger.spanSync('getChainForEscrowService', () {
        if (configuredChains.isEmpty) {
          throw StateError(
            'No EVM chains configured for escrow service ${service.id}',
          );
        }
        final match = configuredChains
            .where((c) => c.config.chainId == service.chainId)
            .firstOrNull;
        if (match != null) return match;
        _logger.w(
          'No chain with chainId=${service.chainId} for escrow service '
          '${service.id} — falling back to first configured chain '
          '(chainId=${configuredChains.first.config.chainId})',
        );
        return configuredChains.first;
      });

  /// Look up a configured chain by chain ID.
  EvmChain? getChainByChainId(int chainId) {
    return configuredChains
        .where((c) => c.config.chainId == chainId)
        .firstOrNull;
  }

  /// Look up a configured chain by config ID string.
  EvmChain? getChainById(String id) {
    return configuredChains.where((c) => c.config.id == id).firstOrNull;
  }

  Future<void> reset() => _logger.span('reset', () async {
    for (final c in configuredChains) {
      await c.balanceMonitor.stop();
    }
  });

  Future<void> dispose() => _logger.span('dispose', () async {
    for (final c in configuredChains) {
      await c.dispose();
    }
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
  ///
  /// Uses the [EvmBalanceMonitor] cache where available to avoid redundant RPC
  /// calls; falls back to [getAddressesWithBalance] for chains with no tracked
  /// addresses yet.
  Future<List<EvmSwapOutOperation>> swapOutAll({TokenAmount? minimumBalance}) =>
      _logger.span('swapOutAll', () async {
        final ops = <EvmSwapOutOperation>[];
        for (final configured in configuredChains) {
          if (configured.swaps == null) continue;

          // Collect funded (address, accountIndex, balance) entries from the
          // monitor cache. Fall back to a live RPC scan if the monitor has not
          // yet seeded any addresses.
          final monitorAddresses = configured.balanceMonitor.trackedAddresses;
          if (monitorAddresses.isNotEmpty) {
            for (final tracked in monitorAddresses) {
              final addr = tracked.address;
              // Native balance from cache.
              final native = configured.balanceMonitor.balanceOf(
                addr,
                Token.native(configured.config.chainId),
              );
              if (native != null && native.value > BigInt.zero) {
                if (minimumBalance == null ||
                    native.getInSats >= minimumBalance.getInSats) {
                  // Derive the account index from the reason tag if present.
                  final accountIndex =
                      _accountIndexFromReason(tracked.reason) ?? 0;
                  final evmKey = await _auth.hd.getActiveEvmKey(
                    accountIndex: accountIndex,
                  );
                  ops.add(
                    configured.swapOut(
                      params: SwapOutParams(
                        evmKey: evmKey,
                        accountIndex: accountIndex,
                        amount: null,
                      ),
                      auth: _auth,
                      logger: _logger,
                      nwc: getIt<Nwc>(),
                      payments: getIt<Payments>(),
                      quoteService: getIt<SwapQuoteService>(),
                    ),
                  );
                }
              }

              // ERC-20 balances from cache.
              for (final token in configured.balanceMonitor.trackedTokens) {
                final erc20 = configured.balanceMonitor.balanceOf(addr, token);
                if (erc20 != null && erc20.value > BigInt.zero) {
                  if (minimumBalance == null ||
                      erc20.getInSats >= minimumBalance.getInSats) {
                    final accountIndex =
                        _accountIndexFromReason(tracked.reason) ?? 0;
                    final evmKey = await _auth.hd.getActiveEvmKey(
                      accountIndex: accountIndex,
                    );
                    ops.add(
                      configured.swapOut(
                        params: SwapOutParams(
                          evmKey: evmKey,
                          accountIndex: accountIndex,
                          amount: erc20,
                        ),
                        auth: _auth,
                        logger: _logger,
                        nwc: getIt<Nwc>(),
                        payments: getIt<Payments>(),
                        quoteService: getIt<SwapQuoteService>(),
                      ),
                    );
                  }
                }
              }
            }
          } else {
            // Fallback: live RPC scan (no monitor data yet).
            final funded = await configured.getAddressesWithBalance();
            for (final entry in funded) {
              if (minimumBalance != null &&
                  entry.balance.getInSats < minimumBalance.getInSats) {
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
                  quoteService: getIt<SwapQuoteService>(),
                ),
              );
            }

            // Also scan ERC-20 balances when Boltz tokens are configured.
            final boltzTokens = configured.swaps?.chainInfo.tokens;
            if (boltzTokens != null && boltzTokens.isNotEmpty) {
              final tokenFunded = await configured
                  .getAddressesWithTokenBalances(boltzTokens);
              for (final entry in tokenFunded) {
                if (minimumBalance != null &&
                    entry.balance.getInSats < minimumBalance.getInSats) {
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
                      amount: entry.balance,
                    ),
                    auth: _auth,
                    logger: _logger,
                    nwc: getIt<Nwc>(),
                    payments: getIt<Payments>(),
                    quoteService: getIt<SwapQuoteService>(),
                  ),
                );
              }
            }
          }
        }
        return ops;
      });

  /// Parse a `seed:index` or similar reason tag back to an account index.
  static int? _accountIndexFromReason(String? reason) {
    if (reason == null) return null;
    final parts = reason.split(':');
    if (parts.length >= 2) return int.tryParse(parts.last);
    return null;
  }

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
      // SwapRecoverer handles both plain swaps AND escrow fund swaps
      // (via postClaimCalls on SwapInData).
      return await swapRecoverer.recoverAll(
        isBackground: isBackground,
        onProgress: onProgress,
      );
    } catch (e) {
      _logger.e('Evm.recoverStaleOperations failed: $e');
      return 0;
    } finally {
      _isRecovering = false;
    }
  });
}
