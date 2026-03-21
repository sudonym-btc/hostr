import 'package:models/main.dart';
import 'package:web3dart/web3dart.dart';

class SwapOutParams {
  final EthPrivateKey evmKey;
  final int accountIndex;
  final TokenAmount? amount;

  SwapOutParams({
    required this.evmKey,
    required this.accountIndex,
    required this.amount,
  });
}

class SwapOutFees {
  final TokenAmount estimatedGasFees;
  final TokenAmount estimatedSwapFees;
  final TokenAmount balance;
  final TokenAmount invoiceAmount;

  TokenAmount get totalFees => estimatedGasFees + estimatedSwapFees;

  SwapOutFees({
    required this.estimatedGasFees,
    required this.estimatedSwapFees,
    required this.balance,
    required this.invoiceAmount,
  });
}
