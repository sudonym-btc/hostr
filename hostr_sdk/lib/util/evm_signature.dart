import 'dart:typed_data';

import 'package:convert/convert.dart';

/// Parsed EIP-712 / ECDSA signature components.
typedef EvmSignature = ({BigInt v, Uint8List r, Uint8List s});

/// Parse a 65-byte hex-encoded ECDSA / EIP-712 signature into its
/// `(v, r, s)` components.
///
/// Accepts optional `0x` prefix.
EvmSignature parseEvmSignature(String sigHex) {
  final normalized = sigHex.startsWith('0x') ? sigHex.substring(2) : sigHex;
  final sigBytes = hex.decode(normalized);
  if (sigBytes.length != 65) {
    throw StateError(
      'Expected 65-byte signature, got ${sigBytes.length} bytes',
    );
  }
  return (
    r: Uint8List.fromList(sigBytes.sublist(0, 32)),
    s: Uint8List.fromList(sigBytes.sublist(32, 64)),
    v: BigInt.from(sigBytes[64]),
  );
}
