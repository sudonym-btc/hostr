import 'dart:convert' show utf8;
import 'dart:typed_data';

import 'package:convert/convert.dart' as convert;
import 'package:crypto/crypto.dart' as crypto;
import 'package:wallet/wallet.dart' as bip;
import 'package:web3dart/web3dart.dart';

/// BIP-44 derivation path prefix for EVM (Ethereum / Rootstock).
const _evmPathPrefix = "m/44'/60'/0'/0";
const _nostrPathPrefix = "m/44'/1237'";
const _tradeIdPathPrefix = "m/1237'/9277'/1'/0";
const _tradeSaltPathPrefix = "m/1237'/9277'/2'/0";
const _appSeedSalt = 'hostr/root/v1';
const _appEntropyInfo = 'deterministic-app-entropy';

Uint8List _hkdfSha256({
  required Uint8List ikm,
  required List<int> salt,
  required List<int> info,
  required int length,
}) {
  final extract = crypto.Hmac(crypto.sha256, salt).convert(ikm).bytes;
  final prk = Uint8List.fromList(extract);
  final blocks = <int>[];
  var previous = <int>[];
  var counter = 1;

  while (blocks.length < length) {
    final input = <int>[...previous, ...info, counter];
    previous = crypto.Hmac(crypto.sha256, prk).convert(input).bytes;
    blocks.addAll(previous);
    counter++;
  }

  return Uint8List.fromList(blocks.take(length).toList(growable: false));
}

bip.ExtendedPrivateKey _deriveAppMaster(String nostrPrivateKeyHex) {
  final words = deriveEvmMnemonicWords(nostrPrivateKeyHex);
  final seed = bip.mnemonicToSeed(words);
  return bip.ExtendedPrivateKey.master(seed, bip.xprv);
}

bip.ExtendedPrivateKey _deriveChild(
  bip.ExtendedPrivateKey master,
  String path,
  int accountIndex,
) {
  return master.forPath('$path/$accountIndex') as bip.ExtendedPrivateKey;
}

Uint8List _deriveAppEntropy(String nostrPrivateKeyHex) {
  final ikm = Uint8List.fromList(convert.hex.decode(nostrPrivateKeyHex));
  return _hkdfSha256(
    ikm: ikm,
    salt: utf8.encode(_appSeedSalt),
    info: utf8.encode(_appEntropyInfo),
    length: 32,
  );
}

Uint8List _childKeyBytes(
  bip.ExtendedPrivateKey master,
  String path,
  int accountIndex,
) {
  final child = _deriveChild(master, path, accountIndex);
  final keyHex = child.key.toRadixString(16).padLeft(64, '0');
  return Uint8List.fromList(convert.hex.decode(keyHex));
}

String _deriveHashedChildHex(
  bip.ExtendedPrivateKey master,
  String path,
  int accountIndex,
) {
  final bytes = _childKeyBytes(master, path, accountIndex);
  return crypto.sha256.convert(bytes).toString();
}

List<String> deriveEvmMnemonicWords(String nostrPrivateKeyHex) {
  final entropy = _deriveAppEntropy(nostrPrivateKeyHex);
  return bip.entropyToMnemonic(entropy);
}

/// Returns the BIP-39 mnemonic derived from a Nostr private key (hex).
///
/// This is a deterministic synthetic mnemonic derived from the resolved
/// active Nostr private key. Importing it into MetaMask will produce the
/// same EVM addresses the app derives for that Nostr identity.
String deriveEvmMnemonic(String nostrPrivateKeyHex) {
  return deriveEvmMnemonicWords(nostrPrivateKeyHex).join(' ');
}

/// Derives the Nostr private key at [accountIndex] from a BIP-39 mnemonic,
/// following NIP-06: `m/44'/1237'/<account>'/0/0`.
String deriveNostrPrivateKeyFromMnemonic(
  String mnemonicSentence, {
  int accountIndex = 0,
}) {
  final words = mnemonicSentence.trim().split(RegExp(r'\s+'));
  final seed = bip.mnemonicToSeed(words);
  final master = bip.ExtendedPrivateKey.master(seed, bip.xprv);
  final derived =
      master.forPath("$_nostrPathPrefix/$accountIndex'/0/0")
          as bip.ExtendedPrivateKey;
  return derived.key.toRadixString(16).padLeft(64, '0');
}

/// Derives a BIP-44 EVM private key from a Nostr private key (hex).
///
/// Derivation: active Nostr private key → synthetic mnemonic →
///   PBKDF2 seed → BIP-32 master → m/44'/60'/0'/0/{accountIndex}
///
/// This is MetaMask-compatible: pasting the mnemonic into MetaMask
/// will show the same addresses.
EthPrivateKey deriveEvmKey(String nostrPrivateKeyHex, {int accountIndex = 0}) {
  final master = _deriveAppMaster(nostrPrivateKeyHex);
  final derived = _deriveChild(master, _evmPathPrefix, accountIndex);
  final keyHex = derived.key.toRadixString(16).padLeft(64, '0');
  return EthPrivateKey.fromHex(keyHex);
}

/// Derives a deterministic trade ID from the active Nostr private key.
String deriveTradeId(String nostrPrivateKeyHex, {int accountIndex = 0}) {
  final master = _deriveAppMaster(nostrPrivateKeyHex);
  return _deriveHashedChildHex(master, _tradeIdPathPrefix, accountIndex);
}

/// Derives a deterministic salt from the active Nostr private key.
String deriveTradeSalt(String nostrPrivateKeyHex, {int accountIndex = 0}) {
  final master = _deriveAppMaster(nostrPrivateKeyHex);
  return _deriveHashedChildHex(master, _tradeSaltPathPrefix, accountIndex);
}
