import 'dart:convert';

import 'package:models/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

const kCurrentAuthRecordVersion = 1;

class AuthRecord {
  final int version;
  final String credentialType;
  final String secret;
  final int? nostrAccountIndex;
  final int maxAccountIndex;
  final KeyPair? keyPair;

  const AuthRecord({
    required this.version,
    required this.credentialType,
    required this.secret,
    this.nostrAccountIndex,
    this.maxAccountIndex = -1,
    this.keyPair,
  });

  String? get privateKeyHex => keyPair?.privateKey;

  String? get publicKeyHex => keyPair?.publicKey;

  Map<String, dynamic> toJson() => {
    'version': version,
    'credentialType': credentialType,
    'secret': secret,
    if (nostrAccountIndex != null) 'nostrAccountIndex': nostrAccountIndex,
    'maxAccountIndex': maxAccountIndex,
    if (keyPair?.privateKey != null)
      'keyPair': {
        'privateKey': keyPair!.privateKey,
        'publicKey': keyPair!.publicKey,
      },
  };

  AuthRecord copyWith({
    int? version,
    String? credentialType,
    String? secret,
    Object? nostrAccountIndex = _noValue,
    int? maxAccountIndex,
    Object? keyPair = _noValue,
  }) => AuthRecord(
    version: version ?? this.version,
    credentialType: credentialType ?? this.credentialType,
    secret: secret ?? this.secret,
    nostrAccountIndex: identical(nostrAccountIndex, _noValue)
        ? this.nostrAccountIndex
        : nostrAccountIndex as int?,
    maxAccountIndex: maxAccountIndex ?? this.maxAccountIndex,
    keyPair: identical(keyPair, _noValue) ? this.keyPair : keyPair as KeyPair?,
  );

  static AuthRecord? fromStorage(List<String> raw) {
    if (raw.isEmpty) return null;
    final first = raw.first;
    try {
      final decoded = jsonDecode(first);
      if (decoded is Map<String, dynamic>) {
        final decodedKeyPair = _decodeKeyPair(decoded['keyPair']);
        return AuthRecord(
          version: decoded['version'] as int? ?? kCurrentAuthRecordVersion,
          credentialType: decoded['credentialType'] as String? ?? 'private_key',
          secret: decoded['secret'] as String,
          nostrAccountIndex: decoded['nostrAccountIndex'] as int?,
          maxAccountIndex: decoded['maxAccountIndex'] as int? ?? -1,
          keyPair: decodedKeyPair,
        );
      }
    } catch (_) {
      // fall through to raw-key migration below
    }

    return AuthRecord(
      version: kCurrentAuthRecordVersion,
      credentialType: 'private_key',
      secret: first,
      maxAccountIndex: -1,
    );
  }
}

KeyPair? _decodeKeyPair(Object? raw) {
  if (raw is! Map<String, dynamic>) return null;
  final privateKey = raw['privateKey'] as String?;
  if (privateKey == null || privateKey.isEmpty) return null;
  return Bip340.fromPrivateKey(privateKey);
}

const _noValue = Object();
