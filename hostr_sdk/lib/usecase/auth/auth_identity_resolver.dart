import 'dart:isolate';

import 'package:bip39_mnemonic/bip39_mnemonic.dart';
import 'package:injectable/injectable.dart';
import 'package:models/bip340.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';

import '../../util/custom_logger.dart';
import '../../util/deterministic_key_derivation.dart';
import 'auth_models.dart';

@Singleton()
class AuthIdentityResolver {
  final CustomLogger _logger;

  AuthIdentityResolver({required CustomLogger logger})
    : _logger = logger.scope('auth_identity_resolver');

  Future<AuthRecord> prepareIdentity(
    String input, {
    int nostrAccountIndex = 0,
  }) => _logger.span('prepareIdentity', () async {
    final record = buildAuthRecord(input, nostrAccountIndex: nostrAccountIndex);
    return resolveRecord(record);
  });

  Future<AuthRecord> resolveInput(String input, {int nostrAccountIndex = 0}) =>
      _logger.span('resolveInput', () async {
        return prepareIdentity(input, nostrAccountIndex: nostrAccountIndex);
      });

  AuthRecord buildAuthRecord(String input, {int nostrAccountIndex = 0}) {
    final trimmed = input.trim();
    final wordCount = trimmed
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .length;
    if (wordCount == 12 || wordCount == 24) {
      final normalized = Mnemonic.fromSentence(
        trimmed,
        Language.english,
      ).sentence;
      return AuthRecord(
        version: kCurrentAuthRecordVersion,
        credentialType: 'mnemonic',
        secret: normalized,
        nostrAccountIndex: nostrAccountIndex,
        maxAccountIndex: -1,
      );
    }

    final privateKey = _parseAndValidateKey(trimmed);
    return AuthRecord(
      version: kCurrentAuthRecordVersion,
      credentialType: 'private_key',
      secret: privateKey,
      maxAccountIndex: -1,
    );
  }

  Future<AuthRecord> resolveRecord(AuthRecord record) async {
    if (record.keyPair != null) {
      return record;
    }

    if (record.credentialType == 'mnemonic') {
      return _resolveMnemonicIdentity(
        record.secret,
        nostrAccountIndex: record.nostrAccountIndex ?? 0,
      );
    }

    final privateKeyHex = _parseAndValidateKey(record.secret);
    return record.copyWith(keyPair: Bip340.fromPrivateKey(privateKeyHex));
  }

  Future<AuthRecord> _resolveMnemonicIdentity(
    String mnemonicSentence, {
    required int nostrAccountIndex,
  }) => _logger.span('_resolveMnemonicIdentity', () async {
    final privateKeyHex = await _resolveMnemonicPrivateKeyOffMainIsolate(
      mnemonicSentence,
      nostrAccountIndex,
    );
    return AuthRecord(
      version: kCurrentAuthRecordVersion,
      credentialType: 'mnemonic',
      secret: mnemonicSentence,
      nostrAccountIndex: nostrAccountIndex,
      maxAccountIndex: -1,
      keyPair: Bip340.fromPrivateKey(privateKeyHex),
    );
  });

  String _parseAndValidateKey(String input) {
    final trimmed = input.trim();

    if (trimmed.length == 64 && _isHex(trimmed)) {
      return trimmed.toLowerCase();
    }

    if (trimmed.startsWith('nsec1')) {
      final decoded = Helpers.decodeBech32(trimmed);
      final hex = decoded[0];
      if (hex.isNotEmpty && hex.length == 64 && _isHex(hex)) {
        return hex.toLowerCase();
      }
      throw Exception('Invalid nsec key');
    }

    throw Exception(
      'Invalid key format. Expected mnemonic, nsec or 64-char hex private key',
    );
  }

  bool _isHex(String str) {
    return RegExp(r'^[0-9a-fA-F]+$').hasMatch(str);
  }
}

const bool _kSupportsBackgroundIsolates =
    !bool.fromEnvironment('dart.library.js_interop') &&
    !bool.fromEnvironment('dart.library.js_util');

Future<String> _resolveMnemonicPrivateKeyOffMainIsolate(
  String mnemonicSentence,
  int nostrAccountIndex,
) async {
  if (_kSupportsBackgroundIsolates) {
    return Isolate.run(
      () async => await _deriveResolvedMnemonicPrivateKey(
        mnemonicSentence,
        nostrAccountIndex,
      ),
    );
  }

  return _deriveResolvedMnemonicPrivateKey(mnemonicSentence, nostrAccountIndex);
}

Future<String> _deriveResolvedMnemonicPrivateKey(
  String mnemonicSentence,
  int nostrAccountIndex,
) async {
  final privateKeyHex = await deriveNostrPrivateKeyFromMnemonic(
    mnemonicSentence,
    accountIndex: nostrAccountIndex,
  );
  return privateKeyHex;
}
