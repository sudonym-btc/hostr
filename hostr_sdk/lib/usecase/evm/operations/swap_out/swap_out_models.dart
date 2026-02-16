import 'package:web3dart/web3dart.dart';

import '../../../../util/bitcoin_amount.dart';

class SwapOutParams {
  final EthPrivateKey evmKey;
  final BitcoinAmount? amount;

  SwapOutParams({required this.evmKey, required this.amount});
}

class SwapOutFees {
  final BitcoinAmount estimatedGasFees;
  final BitcoinAmount estimatedSwapFees;

  BitcoinAmount get totalFees => estimatedGasFees + estimatedSwapFees;

  SwapOutFees({
    required this.estimatedGasFees,
    required this.estimatedSwapFees,
  });
}
