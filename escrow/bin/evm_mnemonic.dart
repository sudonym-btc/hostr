import 'dart:io';

import 'package:hostr_sdk/util/deterministic_key_derivation.dart';
import 'package:models/secp256k1.dart' show loadSecp256k1Backend;

/// Derives and prints the BIP-39 mnemonic + EVM address from a Nostr private
/// key (hex).  The mnemonic can be imported directly into MetaMask.
///
/// Usage:
///   dart run bin/evm_mnemonic.dart <nostr_privkey_hex>
///   PRIVATE_KEY=<hex> dart run bin/evm_mnemonic.dart
Future<void> main(List<String> args) async {
  final hex =
      args.isNotEmpty ? args.first : Platform.environment['PRIVATE_KEY'];
  if (hex == null || hex.isEmpty) {
    stderr.writeln('Usage: dart run bin/evm_mnemonic.dart <nostr_privkey_hex>');
    exit(1);
  }

  await loadSecp256k1Backend();

  final derivation = DeterministicKeyDerivation(hex);

  final mnemonic = await derivation.deriveAccountMnemonic();
  final address = await derivation.deriveEvmAddress();

  print('');
  print('┌─────────────────────────────────────────────────────────────');
  print('│  24-word BIP-39 mnemonic (MetaMask-compatible)');
  print('│');
  print('│  $mnemonic');
  print('│');
  print('│  Derivation path:  m/44\'/60\'/0\'/0/0');
  print('│  EVM address:      ${address.eip55With0x}');
  print('└─────────────────────────────────────────────────────────────');
  print('');
  print('Import the mnemonic into MetaMask as a "Secret Recovery Phrase".');
  print('The first account (index 0) will match the address above.');
}
