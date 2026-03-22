import 'dart:typed_data';

import 'package:wallet/wallet.dart' show EthereumAddress;

/// Arguments for an EtherSwap claim operation.
///
/// Extracted from the deprecated rif_relay module so the typedef can be shared
/// across the codebase without pulling in the relay implementation.
typedef ClaimArgs = ({
  BigInt amount,
  Uint8List preimage,
  Uint8List r,
  EthereumAddress refundAddress,
  Uint8List s,
  BigInt timelock,
  BigInt v,
});
