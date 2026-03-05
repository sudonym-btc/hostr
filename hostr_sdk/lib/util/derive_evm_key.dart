import 'dart:typed_data';

import 'package:convert/convert.dart' as convert;
import 'package:wallet/wallet.dart' as bip;
import 'package:web3dart/web3dart.dart';

/// BIP-44 derivation path prefix for EVM (Ethereum / Rootstock).
const _evmPathPrefix = "m/44'/60'/0'/0";

/// Returns the BIP-39 mnemonic derived from a Nostr private key (hex).
///
/// This is the 24-word seed phrase that, when imported into MetaMask,
/// will produce the same EVM addresses the daemon uses.
String deriveEvmMnemonic(String nostrPrivateKeyHex) {
  final entropy = Uint8List.fromList(convert.hex.decode(nostrPrivateKeyHex));
  final words = bip.entropyToMnemonic(entropy);
  return words.join(' ');
}

/// Derives a BIP-44 EVM private key from a Nostr private key (hex).
///
/// Derivation: nsec hex → BIP-39 mnemonic (entropy-to-words) →
///   PBKDF2 seed → BIP-32 master → m/44'/60'/0'/0/{accountIndex}
///
/// This is MetaMask-compatible: pasting the mnemonic into MetaMask
/// will show the same addresses.
EthPrivateKey deriveEvmKey(String nostrPrivateKeyHex, {int accountIndex = 0}) {
  final entropy = Uint8List.fromList(convert.hex.decode(nostrPrivateKeyHex));
  final words = bip.entropyToMnemonic(entropy);
  final seed = bip.mnemonicToSeed(words);
  final master = bip.ExtendedPrivateKey.master(seed, bip.xprv);
  final derived =
      master.forPath("$_evmPathPrefix/$accountIndex") as bip.ExtendedPrivateKey;
  final keyHex = derived.key.toRadixString(16).padLeft(64, '0');
  return EthPrivateKey.fromHex(keyHex);
}
