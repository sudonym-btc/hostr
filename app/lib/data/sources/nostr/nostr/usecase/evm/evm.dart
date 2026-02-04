import 'dart:async';

import 'package:hostr/config/main.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/injection.dart';
import 'package:http/http.dart' as http;
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

  BehaviorSubject<double>? _balanceSubject;
  StreamSubscription<double>? _balanceSubscription;

  late final List<EvmChain> supportedEvmChains;
  Evm({required this.auth}) {
    supportedEvmChains = [
      Rootstock(
        client: Web3Client(getIt<Config>().rootstockRpcUrl, http.Client()),
      ),
    ];
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
}
