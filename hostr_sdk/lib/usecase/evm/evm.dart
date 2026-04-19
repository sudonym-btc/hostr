import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:models/main.dart';

import '../../config.dart';
import '../../datasources/boltz/boltz.dart';
import '../../injection.dart';
import '../../util/main.dart';
import '../auth/auth.dart';
import '../background_worker/background_worker.dart';
import 'capabilities/aa_capability.dart';
import 'capabilities/boltz_swap_provider.dart';
import 'chain/evm_chain.dart';
import 'chain/operations/swap_out/swap_out_operation.dart';
import 'models/amount_spec.dart';
import 'operations/swap_out/swap_out_models.dart';
import 'operations/swap_recoverer.dart';

@Singleton()
class Evm {
  final CustomLogger _logger;
  final HostrConfig _config;
  final Auth _auth;
  CustomLogger get logger => _logger;

  /// All configured EVM chains, assembled with their capabilities.
  late final List<EvmChain> configuredChains = _buildChains();

  /// The shared Boltz client — `null` if no Boltz config is present.
  BoltzClient? _boltzClient;
  BoltzClient? get boltzClient => _boltzClient;

  Evm(HostrConfig config, Auth auth, CustomLogger logger)
    : _config = config,
      _auth = auth,
      _logger = logger.scope('evm');

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
      return getIt<EvmChain>(param1: chainConfig, param2: aa);
    }).toList();
  }

  /// Initialize Boltz discovery and attach swap providers to matching chains.
  ///
  /// Call this once after construction. It's separated from the constructor
  /// because it's async.
  Future<void> init() => _logger.span('init', () async {
    final chains = configuredChains;
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
        final match = chains
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

        // Resolve Boltz ERC-20 tokens so the chain token registry is warm.
        // FundsMonitorService owns balance tracking and will register these
        // tokens with its private trackers when it starts.
        for (final entry in info.tokens.entries) {
          await match.resolveToken(entry.value.eip55With0x);
        }

        _logger.i(
          'Attached Boltz swap provider for ${info.chainKey} '
          'to chain ${match.config.id}',
        );
      }
    } catch (e) {
      _logger.e('Boltz discovery failed (chains remain swap-less): $e');
    }

    // Balance monitoring is owned by FundsMonitorService.
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

  Future<void> reset() => _logger.span('reset', () async {});

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
  /// Performs a direct scan. Continuous balance tracking is owned by
  /// [FundsMonitorService].
  Future<List<EvmSwapOutOperation>> swapOutAll({TokenAmount? minimumBalance}) =>
      _logger.span('swapOutAll', () async {
        final ops = <EvmSwapOutOperation>[];
        for (final configured in configuredChains) {
          if (configured.swaps == null) continue;

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
                ),
              ),
            );
          }

          final boltzTokens = configured.swaps?.chainInfo.tokens;
          if (boltzTokens != null && boltzTokens.isNotEmpty) {
            final tokenFunded = await configured.getAddressesWithTokenBalances(
              boltzTokens,
            );
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
                    amountSpec: AmountSpec.input(entry.balance),
                  ),
                ),
              );
            }
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
