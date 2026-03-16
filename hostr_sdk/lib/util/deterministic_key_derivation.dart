import 'dart:convert' show utf8;
import 'dart:typed_data';

import 'package:coinlib/coinlib.dart' as coinlib;
import 'package:convert/convert.dart' as convert;
import 'package:wallet/wallet.dart' as bip;
import 'package:web3dart/web3dart.dart';
import 'package:webcrypto/webcrypto.dart' as wc;

/// BIP-44 derivation path prefix for EVM (Ethereum / Rootstock).
const _evmPathPrefix = "m/44'/60'/0'/0";
const _nostrPathPrefix = "m/44'/1237'";
const _tradeIdPathPrefix = "m/1237'/9277'/1'/0";
const _tradeSaltPathPrefix = "m/1237'/9277'/2'/0";
const _appSeedSalt = 'hostr/root/v1';
const _appEntropyInfo = 'deterministic-app-entropy';
const _bip39SeedSaltPrefix = 'mnemonic';
const _bip39SeedIterations = 2048;
const _bip39SeedBits = 512;

Future<Uint8List> _hmacSha256Bytes(List<int> key, List<int> input) async {
  final hmacKey = await wc.HmacSecretKey.importRawKey(
    Uint8List.fromList(key),
    wc.Hash.sha256,
  );
  final mac = await hmacKey.signBytes(Uint8List.fromList(input));
  return Uint8List.fromList(mac);
}

Future<String> _sha256Hex(List<int> input) async {
  final hash = await wc.Hash.sha256.digestBytes(Uint8List.fromList(input));
  return convert.hex.encode(hash);
}

Future<Uint8List> _hkdfSha256({
  required Uint8List ikm,
  required List<int> salt,
  required List<int> info,
  required int length,
}) async {
  final prk = await _hmacSha256Bytes(salt, ikm);
  final blocks = <int>[];
  var previous = <int>[];
  var counter = 1;

  while (blocks.length < length) {
    final input = <int>[...previous, ...info, counter];
    previous = await _hmacSha256Bytes(prk, input);
    blocks.addAll(previous);
    counter++;
  }

  return Uint8List.fromList(blocks.take(length).toList(growable: false));
}

List<int> _bip39MnemonicSalt({String passphrase = ''}) {
  return utf8.encode('$_bip39SeedSaltPrefix$passphrase');
}

Future<Uint8List> _mnemonicToSeed(
  List<String> words, {
  String passphrase = '',
}) async {
  final password = utf8.encode(words.join(' '));
  final salt = Uint8List.fromList(_bip39MnemonicSalt(passphrase: passphrase));
  final key = await wc.Pbkdf2SecretKey.importRawKey(password);
  final derived = await key.deriveBits(
    _bip39SeedBits,
    wc.Hash.sha512,
    salt,
    _bip39SeedIterations,
  );
  return Uint8List.fromList(derived);
}

class DeterministicKeyDerivation {
  final String nostrPrivateKeyHex;

  Future<Uint8List>? _appEntropyFuture;
  Future<List<String>>? _evmMnemonicWordsFuture;
  Future<String>? _evmMnemonicFuture;
  Future<coinlib.HDPrivateKey>? _appMasterFuture;

  /// Cache for [HDPrivateKey] at each BIP-32 path prefix so that
  /// deriving a new account index only walks one additional child level
  /// instead of re-traversing the entire path from the master key.
  final Map<String, coinlib.HDPrivateKey> _pathPrefixKeys = {};
  final Map<int, Future<EthPrivateKey>> _evmKeyFutures = {};
  final Map<int, Future<bip.EthereumAddress>> _evmAddressFutures = {};
  final Map<int, Future<String>> _tradeIdFutures = {};
  final Map<int, Future<String>> _tradeSaltFutures = {};

  DeterministicKeyDerivation(this.nostrPrivateKeyHex);

  /// Returns the [HDPrivateKey] at [pathPrefix], caching it so that
  /// subsequent calls with a different [accountIndex] only need to derive
  /// one more child level instead of re-walking the entire path.
  coinlib.HDPrivateKey _prefixKey(
    coinlib.HDPrivateKey master,
    String pathPrefix,
  ) {
    return _pathPrefixKeys.putIfAbsent(
      pathPrefix,
      () => master.derivePath(pathPrefix),
    );
  }

  Future<Uint8List> deriveAppEntropy() {
    return _appEntropyFuture ??= _deriveAppEntropyFromPrivateKey(
      nostrPrivateKeyHex,
    );
  }

  Future<List<String>> deriveAccountMnemonicWords() {
    return _evmMnemonicWordsFuture ??= () async {
      final entropy = await deriveAppEntropy();
      return bip.entropyToMnemonic(entropy);
    }();
  }

  Future<String> deriveAccountMnemonic() {
    return _evmMnemonicFuture ??= () async {
      return (await deriveAccountMnemonicWords()).join(' ');
    }();
  }

  Future<coinlib.HDPrivateKey> deriveAppMaster() {
    return _appMasterFuture ??= () async {
      final words = await deriveAccountMnemonicWords();
      final seed = await _mnemonicToSeed(words);
      return coinlib.HDPrivateKey.fromSeed(seed);
    }();
  }

  Future<EthPrivateKey> deriveEvmKey({int accountIndex = 0}) {
    return _evmKeyFutures.putIfAbsent(accountIndex, () async {
      final master = await deriveAppMaster();
      final parent = _prefixKey(master, _evmPathPrefix);
      final derived = parent.derive(accountIndex);
      final keyHex = convert.hex.encode(derived.privateKey.data);
      return EthPrivateKey.fromHex(keyHex);
    });
  }

  Future<bip.EthereumAddress> deriveEvmAddress({int accountIndex = 0}) {
    return _evmAddressFutures.putIfAbsent(accountIndex, () async {
      final master = await deriveAppMaster();
      final parent = _prefixKey(master, _evmPathPrefix);
      final derived = parent.derive(accountIndex);
      // Use coinlib (native/WASM secp256k1) for the EC point multiplication
      // instead of going through EthPrivateKey.address which uses
      // pointycastle's pure-Dart implementation (~260 ms on web).
      final uncompressedPub = coinlib.ECPrivateKey(
        derived.privateKey.data,
        compressed: false,
      ).pubkey.data; // 65 bytes (0x04 ‖ x ‖ y)
      // keccak256(pubBytes[1:]) → last 20 bytes = address
      final addressBytes = publicKeyToAddress(uncompressedPub.sublist(1));
      return bip.EthereumAddress(addressBytes);
    });
  }

  Future<String> deriveTradeId({int accountIndex = 0}) {
    return _tradeIdFutures.putIfAbsent(accountIndex, () async {
      final master = await deriveAppMaster();
      final parent = _prefixKey(master, _tradeIdPathPrefix);
      final child = parent.derive(accountIndex);
      return _sha256Hex(child.privateKey.data);
    });
  }

  Future<String> deriveTradeSalt({int accountIndex = 0}) {
    return _tradeSaltFutures.putIfAbsent(accountIndex, () async {
      final master = await deriveAppMaster();
      final parent = _prefixKey(master, _tradeSaltPathPrefix);
      final child = parent.derive(accountIndex);
      return _sha256Hex(child.privateKey.data);
    });
  }
}

Future<Uint8List> _deriveAppEntropyFromPrivateKey(
  String nostrPrivateKeyHex,
) async {
  final ikm = Uint8List.fromList(convert.hex.decode(nostrPrivateKeyHex));
  return _hkdfSha256(
    ikm: ikm,
    salt: utf8.encode(_appSeedSalt),
    info: utf8.encode(_appEntropyInfo),
    length: 32,
  );
}

DeterministicKeyDerivation _forPrivateKey(String nostrPrivateKeyHex) {
  return DeterministicKeyDerivation(nostrPrivateKeyHex);
}

Future<List<String>> deriveAccountMnemonicWords(
  String nostrPrivateKeyHex,
) async {
  return _forPrivateKey(nostrPrivateKeyHex).deriveAccountMnemonicWords();
}

Future<String> deriveAccountMnemonic(String nostrPrivateKeyHex) async {
  return _forPrivateKey(nostrPrivateKeyHex).deriveAccountMnemonic();
}

Future<String> deriveNostrPrivateKeyFromMnemonic(
  String mnemonicSentence, {
  int accountIndex = 0,
}) async {
  final words = mnemonicSentence.trim().split(RegExp(r'\s+'));
  final seed = await _mnemonicToSeed(words);
  final master = coinlib.HDPrivateKey.fromSeed(seed);
  final derived = master.derivePath("$_nostrPathPrefix/$accountIndex'/0/0");
  return convert.hex.encode(derived.privateKey.data);
}

Future<EthPrivateKey> deriveEvmKey(
  String nostrPrivateKeyHex, {
  int accountIndex = 0,
}) async {
  return _forPrivateKey(
    nostrPrivateKeyHex,
  ).deriveEvmKey(accountIndex: accountIndex);
}

Future<String> deriveTradeId(
  String nostrPrivateKeyHex, {
  int accountIndex = 0,
}) async {
  return _forPrivateKey(
    nostrPrivateKeyHex,
  ).deriveTradeId(accountIndex: accountIndex);
}

Future<String> deriveTradeSalt(
  String nostrPrivateKeyHex, {
  int accountIndex = 0,
}) async {
  return _forPrivateKey(
    nostrPrivateKeyHex,
  ).deriveTradeSalt(accountIndex: accountIndex);
}
