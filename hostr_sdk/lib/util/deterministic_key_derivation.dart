import 'dart:convert' show utf8;
import 'dart:typed_data';

import 'package:convert/convert.dart' as convert;
import 'package:cryptography/cryptography.dart';
import 'package:wallet/wallet.dart' as bip;
import 'package:web3dart/web3dart.dart';

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

final _sha256Async = Sha256();
final _hmacSha256Async = Hmac.sha256();
final _pbkdf2HmacSha512Async = Pbkdf2(
  macAlgorithm: Hmac.sha512(),
  iterations: _bip39SeedIterations,
  bits: _bip39SeedBits,
);

Future<Uint8List> _hmacSha256Bytes(List<int> key, List<int> input) async {
  final mac = await _hmacSha256Async.calculateMac(
    input,
    secretKey: SecretKey(key),
    nonce: const [],
  );
  return Uint8List.fromList(mac.bytes);
}

Future<String> _sha256Hex(List<int> input) async {
  final hash = await _sha256Async.hash(input);
  return convert.hex.encode(hash.bytes);
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
  final derivedKey = await _pbkdf2HmacSha512Async.deriveKeyFromPassword(
    password: words.join(' '),
    nonce: _bip39MnemonicSalt(passphrase: passphrase),
  );
  return Uint8List.fromList(await derivedKey.extractBytes());
}

bip.ExtendedPrivateKey _deriveChild(
  bip.ExtendedPrivateKey master,
  String path,
  int accountIndex,
) {
  return master.forPath('$path/$accountIndex') as bip.ExtendedPrivateKey;
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

Future<String> _deriveHashedChildHex(
  bip.ExtendedPrivateKey master,
  String path,
  int accountIndex,
) async {
  final bytes = _childKeyBytes(master, path, accountIndex);
  return _sha256Hex(bytes);
}

class DeterministicKeyDerivation {
  final String nostrPrivateKeyHex;

  Future<Uint8List>? _appEntropyFuture;
  Future<List<String>>? _evmMnemonicWordsFuture;
  Future<String>? _evmMnemonicFuture;
  Future<bip.ExtendedPrivateKey>? _appMasterFuture;
  final Map<int, Future<EthPrivateKey>> _evmKeyFutures = {};
  final Map<int, Future<String>> _tradeIdFutures = {};
  final Map<int, Future<String>> _tradeSaltFutures = {};

  DeterministicKeyDerivation(this.nostrPrivateKeyHex);

  Future<Uint8List> deriveAppEntropy() {
    return _appEntropyFuture ??= _deriveAppEntropyFromPrivateKey(
      nostrPrivateKeyHex,
    );
  }

  Future<List<String>> deriveEvmMnemonicWords() {
    return _evmMnemonicWordsFuture ??= () async {
      final entropy = await deriveAppEntropy();
      return bip.entropyToMnemonic(entropy);
    }();
  }

  Future<String> deriveEvmMnemonic() {
    return _evmMnemonicFuture ??= () async {
      return (await deriveEvmMnemonicWords()).join(' ');
    }();
  }

  Future<bip.ExtendedPrivateKey> deriveAppMaster() {
    return _appMasterFuture ??= () async {
      final words = await deriveEvmMnemonicWords();
      final seed = await _mnemonicToSeed(words);
      return bip.ExtendedPrivateKey.master(seed, bip.xprv);
    }();
  }

  Future<EthPrivateKey> deriveEvmKey({int accountIndex = 0}) {
    return _evmKeyFutures.putIfAbsent(accountIndex, () async {
      final derived = _deriveChild(
        await deriveAppMaster(),
        _evmPathPrefix,
        accountIndex,
      );
      final keyHex = derived.key.toRadixString(16).padLeft(64, '0');
      return EthPrivateKey.fromHex(keyHex);
    });
  }

  Future<String> deriveTradeId({int accountIndex = 0}) {
    return _tradeIdFutures.putIfAbsent(accountIndex, () async {
      return _deriveHashedChildHex(
        await deriveAppMaster(),
        _tradeIdPathPrefix,
        accountIndex,
      );
    });
  }

  Future<String> deriveTradeSalt({int accountIndex = 0}) {
    return _tradeSaltFutures.putIfAbsent(accountIndex, () async {
      return _deriveHashedChildHex(
        await deriveAppMaster(),
        _tradeSaltPathPrefix,
        accountIndex,
      );
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

Future<List<String>> deriveEvmMnemonicWords(String nostrPrivateKeyHex) async {
  return _forPrivateKey(nostrPrivateKeyHex).deriveEvmMnemonicWords();
}

Future<String> deriveEvmMnemonic(String nostrPrivateKeyHex) async {
  return _forPrivateKey(nostrPrivateKeyHex).deriveEvmMnemonic();
}

Future<String> deriveNostrPrivateKeyFromMnemonic(
  String mnemonicSentence, {
  int accountIndex = 0,
}) async {
  final words = mnemonicSentence.trim().split(RegExp(r'\s+'));
  final seed = await _mnemonicToSeed(words);
  final master = bip.ExtendedPrivateKey.master(seed, bip.xprv);
  final derived =
      master.forPath("$_nostrPathPrefix/$accountIndex'/0/0")
          as bip.ExtendedPrivateKey;
  return derived.key.toRadixString(16).padLeft(64, '0');
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
