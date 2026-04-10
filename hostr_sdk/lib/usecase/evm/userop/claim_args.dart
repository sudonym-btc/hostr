import 'dart:typed_data';

import 'package:wallet/wallet.dart' show EthereumAddress;

/// Arguments for an EtherSwap / ERC20Swap claim operation.
///
/// Shared typedef so claim logic can be used across the codebase without
/// coupling to any single swap-contract implementation.
///
/// When [tokenAddress] is non-null the claim targets the ERC20Swap contract
/// (which requires `tokenAddress` as an additional parameter in every call).
/// When null, the claim targets the EtherSwap contract.
typedef ClaimArgs = ({
  BigInt amount,
  Uint8List preimage,
  Uint8List r,
  EthereumAddress refundAddress,
  Uint8List s,
  BigInt timelock,
  EthereumAddress? tokenAddress,
  BigInt v,
});
