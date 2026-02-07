import 'package:hostr/core/util/main.dart';
import 'package:web3dart/web3dart.dart';

class SwapInParams {
  final EthPrivateKey evmKey;
  final BitcoinAmount amount;

  SwapInParams({required this.evmKey, required this.amount});
}

class SwapInFees {
  final BitcoinAmount estimatedGasFees;
  final BitcoinAmount estimatedSwapFees;

  SwapInFees({required this.estimatedGasFees, required this.estimatedSwapFees});
}
