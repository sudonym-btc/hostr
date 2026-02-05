import 'dart:async';

import 'package:hostr/core/main.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:rxdart/rxdart.dart';
import 'package:web3dart/web3dart.dart';

import '../auth/auth.dart';
import 'evm_chain.dart';
import 'rootstock.dart';

@Singleton()
class Evm {
  final CustomLogger logger = CustomLogger();
  final Auth auth;
  final Rootstock rootstock;

  BehaviorSubject<double>? _balanceSubject;
  StreamSubscription<double>? _balanceSubscription;

  late final List<EvmChain> supportedEvmChains;
  Evm({required this.auth, required this.rootstock}) {
    supportedEvmChains = [rootstock];
  }

  Future<int> getBalance() async {
    // Get current user's Ethereum address
    final keyPair = auth.activeKeyPair!;

    final ethPrivateKey = EthPrivateKey.fromHex(
      keyPair.privateKey!.replaceFirst('0x', ''),
    );
    final userAddress = ethPrivateKey.address;

    // Loop all supported EVM chains and sum balances
    double totalBalance = 0;
    for (var chain in supportedEvmChains) {
      try {
        final chainBalance = await chain.getBalance(userAddress);
        totalBalance += chainBalance;
      } catch (e) {
        logger.w('Failed to get balance from chain: $e');
      }
    }

    return totalBalance.toInt();
  }

  ValueStream<double> subscribeBalance() {
    _balanceSubject ??= BehaviorSubject<double>();

    if (_balanceSubscription == null) {
      final streams = supportedEvmChains
          .map(
            (chain) => chain.subscribeBalance(
              getEvmCredentials(auth.activeKeyPair!.privateKey!).address,
            ),
          )
          .toList();

      final combined = Rx.combineLatestList<double>(streams).map(
        (balances) => balances.fold<double>(0, (sum, value) => sum + value),
      );

      _balanceSubscription = combined.distinct().listen(
        (total) => _balanceSubject!.add(total),
        onError: (error) => logger.w('Balance subscription error: $error'),
      );
    }

    return _balanceSubject!.stream;
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
}
