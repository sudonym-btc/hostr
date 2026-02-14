import 'package:web3dart/web3dart.dart';

import '../../../../util/bitcoin_amount.dart';

class SwapInParams {
  final EthPrivateKey evmKey;
  final BitcoinAmount amount;

  SwapInParams({required this.evmKey, required this.amount});
}

class SwapInFees {
  final BitcoinAmount estimatedGasFees;
  final BitcoinAmount estimatedSwapFees;
  final BitcoinAmount estimatedRelayFees;

  BitcoinAmount get totalFees =>
      estimatedGasFees + estimatedSwapFees + estimatedRelayFees;

  SwapInFees({
    required this.estimatedGasFees,
    required this.estimatedSwapFees,
    required this.estimatedRelayFees,
  });
}
