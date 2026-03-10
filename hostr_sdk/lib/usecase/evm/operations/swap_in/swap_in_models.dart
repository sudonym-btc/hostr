import 'package:web3dart/web3dart.dart';

import '../../../../util/bitcoin_amount.dart';

class SwapInParams {
  final EthPrivateKey evmKey;
  final int accountIndex;
  BitcoinAmount amount;
  BitcoinAmount? minAmount;
  BitcoinAmount? maxAmount;
  final String? invoiceDescription;

  /// When this swap is nested inside a parent operation (e.g. escrow-fund),
  /// set this to the parent's operation ID so that progress notifications
  /// update the same OS notification as the parent.
  final String? parentOperationId;

  SwapInParams({
    required this.evmKey,
    required this.accountIndex,
    required this.amount,
    this.minAmount,
    this.maxAmount,
    this.invoiceDescription,
    this.parentOperationId,
  });
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
