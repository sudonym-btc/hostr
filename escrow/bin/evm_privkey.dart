import 'dart:io';

import 'package:convert/convert.dart' as convert;
import 'package:hostr_sdk/util/deterministic_key_derivation.dart';
import 'package:models/secp256k1.dart' show loadSecp256k1Backend;

/// Derives the EVM private key (hex) from a Nostr private key using the
/// standard deterministic derivation (HKDF → BIP-39 → m/44'/60'/0'/0/0).
///
/// Prints ONLY the raw hex key to stdout so it can be captured by shell scripts.
///
/// Usage:
///   dart run bin/evm_privkey.dart <nostr_privkey_hex>
///   PRIVATE_KEY=<hex> dart run bin/evm_privkey.dart
Future<void> main(List<String> args) async {
  final hex =
      args.isNotEmpty ? args.first : Platform.environment['PRIVATE_KEY'];
  if (hex == null || hex.isEmpty) {
    stderr.writeln(
      'Usage: dart run bin/evm_privkey.dart <nostr_privkey_hex>',
    );
    exit(1);
  }

  await loadSecp256k1Backend();

  final key = await deriveEvmKey(hex);
  // Print only the hex (no 0x prefix) so callers can easily capture it.
  final keyBytes = key.privateKey;
  stdout.write(convert.hex.encode(keyBytes));
}
