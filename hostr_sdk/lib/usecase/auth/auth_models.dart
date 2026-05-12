import 'dart:convert';

import 'package:models/bip340.dart';
import 'package:ndk/ndk.dart' show BunkerConnection;
import 'package:ndk/shared/nips/nip01/key_pair.dart';

const kCurrentAuthRecordVersion = 1;

class AuthRecord {
  final int version;
  final String credentialType;
  final String secret;
  final String? publicKey;
  final int? nostrAccountIndex;
  final int maxAccountIndex;
  final KeyPair? keyPair;
  final BunkerConnection? bunkerConnection;

  const AuthRecord({
    required this.version,
    required this.credentialType,
    required this.secret,
    this.publicKey,
    this.nostrAccountIndex,
    this.maxAccountIndex = -1,
    this.keyPair,
    this.bunkerConnection,
  });

  String? get privateKeyHex => keyPair?.privateKey;

  String? get publicKeyHex => publicKey ?? keyPair?.publicKey;

  Map<String, dynamic> toJson() => {
    'version': version,
    'credentialType': credentialType,
    'secret': secret,
    if (publicKey != null) 'publicKey': publicKey,
    if (nostrAccountIndex != null) 'nostrAccountIndex': nostrAccountIndex,
    'maxAccountIndex': maxAccountIndex,
    if (keyPair?.privateKey != null)
      'keyPair': {
        'privateKey': keyPair!.privateKey,
        'publicKey': keyPair!.publicKey,
      },
    if (bunkerConnection != null)
      'bunkerConnection': bunkerConnection!.toJson(),
  };

  AuthRecord copyWith({
    int? version,
    String? credentialType,
    String? secret,
    Object? publicKey = _noValue,
    Object? nostrAccountIndex = _noValue,
    int? maxAccountIndex,
    Object? keyPair = _noValue,
    Object? bunkerConnection = _noValue,
  }) => AuthRecord(
    version: version ?? this.version,
    credentialType: credentialType ?? this.credentialType,
    secret: secret ?? this.secret,
    publicKey: identical(publicKey, _noValue)
        ? this.publicKey
        : publicKey as String?,
    nostrAccountIndex: identical(nostrAccountIndex, _noValue)
        ? this.nostrAccountIndex
        : nostrAccountIndex as int?,
    maxAccountIndex: maxAccountIndex ?? this.maxAccountIndex,
    keyPair: identical(keyPair, _noValue) ? this.keyPair : keyPair as KeyPair?,
    bunkerConnection: identical(bunkerConnection, _noValue)
        ? this.bunkerConnection
        : bunkerConnection as BunkerConnection?,
  );

  static AuthRecord? fromStorage(List<String> raw) {
    final first = raw
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .firstOrNull;
    if (first == null) return null;
    try {
      final decoded = jsonDecode(first);
      if (decoded is Map<String, dynamic>) {
        final decodedKeyPair = _decodeKeyPair(decoded['keyPair']);
        return AuthRecord(
          version: decoded['version'] as int? ?? kCurrentAuthRecordVersion,
          credentialType: decoded['credentialType'] as String? ?? 'private_key',
          secret: decoded['secret'] as String,
          publicKey:
              decoded['publicKey'] as String? ?? decodedKeyPair?.publicKey,
          nostrAccountIndex: decoded['nostrAccountIndex'] as int?,
          maxAccountIndex: decoded['maxAccountIndex'] as int? ?? -1,
          keyPair: decodedKeyPair,
          bunkerConnection: _decodeBunkerConnection(
            decoded['bunkerConnection'],
          ),
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

BunkerConnection? _decodeBunkerConnection(Object? raw) {
  if (raw is! Map<String, dynamic>) return null;
  return BunkerConnection.fromJson(raw);
}

const _noValue = Object();
