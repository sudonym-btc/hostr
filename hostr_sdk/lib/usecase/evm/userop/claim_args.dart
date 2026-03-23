import 'dart:typed_data';

import 'package:wallet/wallet.dart' show EthereumAddress;

/// Arguments for an EtherSwap / ERC20Swap claim operation.
///
/// Extracted from the deprecated rif_relay module so the typedef can be shared
/// across the codebase without pulling in the relay implementation.
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
