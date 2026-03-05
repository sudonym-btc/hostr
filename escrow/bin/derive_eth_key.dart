import 'dart:io';

import 'package:hostr_sdk/util/derive_evm_key.dart';

/// Derives the EVM private key from a Nostr private key (hex) using the same
/// BIP-44 path the daemon uses: m/44'/60'/0'/0/0
///
/// Reads from the PRIVATE_KEY env var, or the first CLI argument.
///
/// Usage:
///   dart run bin/derive_eth_key.dart <nsec_hex>
///   PRIVATE_KEY=<nsec_hex> dart run bin/derive_eth_key.dart
///
/// Outputs the 0x-prefixed ETH private key on stdout (no newline).
void main(List<String> args) {
  final nsecHex =
      args.isNotEmpty ? args.first : Platform.environment['PRIVATE_KEY'];

  if (nsecHex == null || nsecHex.isEmpty) {
    stderr.writeln('Usage: dart run bin/derive_eth_key.dart <nsec_hex>');
    stderr.writeln('   or: PRIVATE_KEY=<hex> dart run bin/derive_eth_key.dart');
    exit(1);
  }

  final ethKey = deriveEvmKey(nsecHex);
  // Output just the hex key, 0x-prefixed, for piping into other tools.
  stdout.write('0x${ethKey.privateKeyInt.toRadixString(16).padLeft(64, '0')}');
}
