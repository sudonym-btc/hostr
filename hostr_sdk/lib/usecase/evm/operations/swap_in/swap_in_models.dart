import 'package:wallet/wallet.dart' show EthereumAddress;
import 'package:web3dart/web3dart.dart';

import '../../../../util/bitcoin_amount.dart';
import '../../chain/rootstock/rif_relay/rif_relay.dart';

typedef SwapInClaimCallback = Future<String> Function(ClaimArgs claimArgs);

class SwapInParams {
  final EthPrivateKey evmKey;
  final int accountIndex;
  BitcoinAmount amount;
  BitcoinAmount? minAmount;
  BitcoinAmount? maxAmount;
  final String? invoiceDescription;
  final EthereumAddress? claimAddress;
  final EthereumAddress? claimDestination;

  /// When this swap is nested inside a parent operation (e.g. escrow-fund),
  /// set this to the parent's operation ID so that progress notifications
  /// update the same OS notification as the parent.
  final String? parentOperationId;

  /// Optional override for the swap claim execution.
  ///
  /// When set, the swap operation will call this callback during the claim
  /// step instead of using the default RIF relay EtherSwap claim flow. The
  /// callback receives the fully prepared [ClaimArgs] and must return the
  /// broadcast transaction hash.
  final SwapInClaimCallback? onClaim;

  SwapInParams({
    required this.evmKey,
    required this.accountIndex,
    required this.amount,
    this.minAmount,
    this.maxAmount,
    this.invoiceDescription,
    this.claimAddress,
    this.claimDestination,
    this.parentOperationId,
    this.onClaim,
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
