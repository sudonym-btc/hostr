import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:rxdart/rxdart.dart';
import 'package:web3dart/web3dart.dart';

import '../../injection.dart';
import '../../util/main.dart';
import '../auth/auth.dart';
import 'chain/evm_chain.dart';
import 'chain/rootstock/rootstock.dart';
import 'operations/swap_recovery_service.dart';

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
        .map(
          (chain) => chain.subscribeBalance(
            getEvmCredentials(auth.activeKeyPair!.privateKey!).address,
          ),
        )
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
    // Get current user's Ethereum address
    final keyPair = auth.activeKeyPair!;

    final ethPrivateKey = EthPrivateKey.fromHex(
      keyPair.privateKey!.replaceFirst('0x', ''),
    );
    final userAddress = ethPrivateKey.address;

    // Loop all supported EVM chains and sum balances
    BitcoinAmount totalBalance = BitcoinAmount.zero();
    for (var chain in supportedEvmChains) {
      try {
        final chainBalance = await chain.getBalance(userAddress);
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

  /// Recover stale swaps whose on-chain funds may be at risk.
  ///
  /// Iterates persisted [SwapRecord]s, resolves the matching [EvmChain] by
  /// `chainId`, and delegates claim / refund logic to [SwapRecoveryService].
  ///
  /// Safe to call repeatedly — idempotent and non-destructive.
  /// Returns the number of swaps that were successfully resolved.
  Future<int> recoverStaleSwaps() async {
    try {
      final recoveryService = getIt<SwapRecoveryService>();
      final evmKey = auth.getActiveEvmKey();
      return await recoveryService.recoverPendingSwaps(
        evmKey: evmKey,
        chainResolver: getClientForChainId,
      );
    } catch (e) {
      logger.e('Evm.recoverStaleSwaps failed: $e');
      return 0;
    }
  }
}
