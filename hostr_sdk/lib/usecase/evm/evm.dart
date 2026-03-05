import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:rxdart/rxdart.dart';

import '../../injection.dart';
import '../../util/main.dart';
import '../auth/auth.dart';
import '../escrow/operations/fund/escrow_fund_recoverer.dart';
import 'chain/evm_chain.dart';
import 'chain/rootstock/rootstock.dart';
import 'operations/swap_recoverer.dart';

@Singleton()
class Evm {
  final CustomLogger logger;
  final Auth auth;
  final Rootstock rootstock;

  BehaviorSubject<BitcoinAmount>? _balanceSubject;
  StreamSubscription<BitcoinAmount>? _balanceSubscription;

  late final List<EvmChain> supportedEvmChains;
  Evm({required this.auth, required this.rootstock, required this.logger}) {
    supportedEvmChains = [rootstock];
  }

  void _ensureBalanceSubscription() {
    if (_balanceSubscription != null) return;

    final streams = supportedEvmChains
        .map((chain) => chain.subscribeTotalBalance())
        .toList();

    final combined = Rx.combineLatestList<BitcoinAmount>(streams).map(
      (balances) => balances.fold<BitcoinAmount>(
        BitcoinAmount.zero(),
        (sum, value) => sum + value,
      ),
    );

    _balanceSubscription = combined.distinct().listen(
      (total) => _balanceSubject?.add(total),
      onError: (error) => logger.w('Balance subscription error: $error'),
    );
  }

  Future<BitcoinAmount> getBalance() async {
    // Loop all supported EVM chains and sum total balances across all
    // HD-derived addresses that have ever been used.
    BitcoinAmount totalBalance = BitcoinAmount.zero();
    for (var chain in supportedEvmChains) {
      try {
        final chainBalance = await chain.getTotalBalance();
        totalBalance += chainBalance;
      } catch (e) {
        logger.w('Failed to get balance from chain: $e');
      }
    }

    return totalBalance;
  }

  EvmChain getChainForEscrowService(EscrowService service) {
    for (var chain in supportedEvmChains) {
      return chain;
      // if (chain.matchesEscrowService(service)) {
      //   return chain;
      // }
    }
    throw Exception(
      'No supported EVM chain found for escrow service ${service.id}',
    );
  }

  ValueStream<BitcoinAmount> subscribeBalance() {
    _balanceSubject ??= BehaviorSubject<BitcoinAmount>(
      onListen: _ensureBalanceSubscription,
    );

    return _balanceSubject!.stream;
  }

  /// Tears down the current balance subscription and restarts it for
  /// the current authenticated user. Call this when the active key changes.
  void resetBalance() {
    _balanceSubscription?.cancel();
    _balanceSubscription = null;
    // If there are active listeners, restart immediately for the new user.
    if (_balanceSubject?.hasListener ?? false) {
      _ensureBalanceSubscription();
    }
  }

  /// Soft cleanup for logout: tear down the balance subscription and
  /// subject so a subsequent [subscribeBalance] / [resetBalance] starts
  /// fresh, but don't permanently close anything.
  Future<void> reset() async {
    await _balanceSubscription?.cancel();
    _balanceSubscription = null;
    // Don't close the subject — just null it so subscribeBalance()
    // lazily creates a new one on the next login.
    _balanceSubject = null;
  }

  /// Permanent teardown — closes the subject. Only call when the Hostr
  /// instance itself is being disposed.
  Future<void> dispose() async {
    await _balanceSubscription?.cancel();
    _balanceSubscription = null;
    await _balanceSubject?.close();
    _balanceSubject = null;
  }

  Future<EvmChain> getClientForChainId(int chainId) async {
    for (var chain in supportedEvmChains) {
      if ((await chain.getChainId()).toInt() == chainId) {
        return chain;
      }
    }
    throw Exception('EVM chain with ID $chainId not supported.');
  }

  /// Recover stale swaps and escrow fund operations.
  ///
  /// Loads persisted cubit states from [OperationStateStore], reconstructs
  /// the appropriate cubits, and calls their [recover] methods.
  ///
  /// Safe to call repeatedly — idempotent and non-destructive.
  /// Returns the number of operations that were successfully resolved.
  Future<int> recoverStaleOperations() async {
    try {
      final swapRecoverer = getIt<SwapRecoverer>();
      final escrowRecoverer = getIt<EscrowFundRecoverer>();
      final swapsResolved = await swapRecoverer.recoverAll();
      final escrowsResolved = await escrowRecoverer.recoverAll();
      return swapsResolved + escrowsResolved;
    } catch (e) {
      logger.e('Evm.recoverStaleOperations failed: $e');
      return 0;
    }
  }
}
