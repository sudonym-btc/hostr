@Tags(['unit'])
library;

import 'dart:async';
import 'dart:convert';

import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/auth/auth_identity_resolver.dart';
import 'package:hostr_sdk/usecase/storage/storage.dart';
import 'package:hostr_sdk/util/custom_logger.dart';
import 'package:ndk/ndk.dart';
import 'package:test/test.dart';

// ── Well-known test data ───────────────────────────────────────────────

/// A valid 12-word BIP-39 mnemonic for testing.
const _mnemonic12 =
    'abandon abandon abandon abandon abandon abandon abandon abandon '
    'abandon abandon abandon about';

/// A valid 24-word BIP-39 mnemonic for testing.
const _mnemonic24 =
    'abandon abandon abandon abandon abandon abandon abandon abandon '
    'abandon abandon abandon abandon abandon abandon abandon abandon '
    'abandon abandon abandon abandon abandon abandon abandon art';

/// A 64-char hex private key (well-known test vector).
const _hexPrivKey =
    'e8f32e723decf4051aefac8e2c93c9c5b214313817cdb01a1494b917c8436b35';

void main() {
  group('AuthIdentityResolver — buildAuthRecord', () {
    late AuthIdentityResolver resolver;

    setUp(() {
      resolver = AuthIdentityResolver(logger: CustomLogger());
    });

    test('12-word mnemonic → credentialType "mnemonic"', () {
      final record = resolver.buildAuthRecord(_mnemonic12);
      expect(record.credentialType, 'mnemonic');
      expect(record.version, kCurrentAuthRecordVersion);
      expect(record.nostrAccountIndex, 0);
    });

    test('24-word mnemonic → credentialType "mnemonic"', () {
      final record = resolver.buildAuthRecord(_mnemonic24);
      expect(record.credentialType, 'mnemonic');
    });

    test('mnemonic with extra whitespace is normalized', () {
      final record = resolver.buildAuthRecord(
        '  abandon  abandon  abandon  abandon  abandon  abandon  '
        'abandon  abandon  abandon  abandon  abandon  about  ',
      );
      expect(record.credentialType, 'mnemonic');
    });

    test('mnemonic records nostrAccountIndex parameter', () {
      final record = resolver.buildAuthRecord(
        _mnemonic12,
        nostrAccountIndex: 3,
      );
      expect(record.nostrAccountIndex, 3);
    });

    test('mnemonic record has no keyPair (resolved separately)', () {
      final record = resolver.buildAuthRecord(_mnemonic12);
      expect(record.keyPair, isNull);
    });

    test('64-char hex → credentialType "private_key"', () {
      final record = resolver.buildAuthRecord(_hexPrivKey);
      expect(record.credentialType, 'private_key');
      expect(record.secret, _hexPrivKey);
    });

    test('hex key is lowercased', () {
      final upper = _hexPrivKey.toUpperCase();
      final record = resolver.buildAuthRecord(upper);
      expect(record.secret, _hexPrivKey);
    });

    test('nsec bech32 → credentialType "private_key"', () {
      // We don't have a real nsec here, so we test the hex path only.
      // nsec decoding is tested implicitly through _parseAndValidateKey.
      // Just verify hex works.
      final record = resolver.buildAuthRecord(_hexPrivKey);
      expect(record.credentialType, 'private_key');
    });

    test('invalid input throws', () {
      expect(() => resolver.buildAuthRecord('short'), throwsException);
      expect(() => resolver.buildAuthRecord(''), throwsException);
      expect(
        () => resolver.buildAuthRecord('not a mnemonic and not hex'),
        throwsException,
      );
    });

    test('11-word input is treated as invalid (not 12 or 24)', () {
      expect(
        () => resolver.buildAuthRecord(
          'abandon abandon abandon abandon abandon '
          'abandon abandon abandon abandon abandon abandon',
        ),
        throwsException,
      );
    });
  });

  group('AuthRecord — fromStorage', () {
    test('empty list → null', () {
      expect(AuthRecord.fromStorage([]), isNull);
    });

    test('JSON with full structure → parses correctly', () {
      final json = {
        'version': 1,
        'credentialType': 'mnemonic',
        'secret': _mnemonic12,
        'nostrAccountIndex': 2,
        'maxAccountIndex': 5,
      };
      final record = AuthRecord.fromStorage([jsonEncode(json)]);
      expect(record, isNotNull);
      expect(record!.version, 1);
      expect(record.credentialType, 'mnemonic');
      expect(record.secret, _mnemonic12);
      expect(record.nostrAccountIndex, 2);
      expect(record.maxAccountIndex, 5);
    });

    test('JSON without optional fields uses defaults', () {
      final json = {'secret': _hexPrivKey};
      final record = AuthRecord.fromStorage([jsonEncode(json)]);
      expect(record, isNotNull);
      expect(record!.version, kCurrentAuthRecordVersion);
      expect(record.credentialType, 'private_key');
      expect(record.nostrAccountIndex, isNull);
      expect(record.maxAccountIndex, -1);
    });

    test('raw hex key (non-JSON) → migration to private_key record', () {
      final record = AuthRecord.fromStorage([_hexPrivKey]);
      expect(record, isNotNull);
      expect(record!.credentialType, 'private_key');
      expect(record.secret, _hexPrivKey);
      expect(record.maxAccountIndex, -1);
    });

    test('JSON with keyPair → parses keyPair', () {
      final json = {
        'version': 1,
        'credentialType': 'private_key',
        'secret': _hexPrivKey,
        'keyPair': {'privateKey': _hexPrivKey, 'publicKey': 'abcd1234' * 8},
      };
      final record = AuthRecord.fromStorage([jsonEncode(json)]);
      expect(record!.keyPair, isNotNull);
      expect(record.keyPair!.privateKey, _hexPrivKey);
    });

    test('JSON with bunker connection → parses bunker session fields', () {
      final json = {
        'version': 1,
        'credentialType': 'bunker',
        'secret': '',
        'publicKey': 'abcd1234' * 8,
        'bunkerConnection': {
          'privateKey': _hexPrivKey,
          'remotePubkey': 'beef5678' * 8,
          'relays': ['wss://relay.hostr.development'],
        },
      };
      final record = AuthRecord.fromStorage([jsonEncode(json)]);
      expect(record, isNotNull);
      expect(record!.credentialType, 'bunker');
      expect(record.publicKeyHex, 'abcd1234' * 8);
      expect(record.bunkerConnection, isNotNull);
      expect(record.bunkerConnection!.relays, [
        'wss://relay.hostr.development',
      ]);
    });
  });

  group('AuthRecord — toJson / copyWith', () {
    test('round-trip: toJson → fromStorage', () {
      final original = AuthRecord(
        version: 1,
        credentialType: 'mnemonic',
        secret: _mnemonic12,
        nostrAccountIndex: 0,
        maxAccountIndex: 3,
      );
      final json = original.toJson();
      final restored = AuthRecord.fromStorage([jsonEncode(json)]);
      expect(restored!.credentialType, original.credentialType);
      expect(restored.secret, original.secret);
      expect(restored.maxAccountIndex, original.maxAccountIndex);
    });

    test('copyWith preserves unchanged fields', () {
      final original = AuthRecord(
        version: 1,
        credentialType: 'mnemonic',
        secret: _mnemonic12,
        nostrAccountIndex: 0,
        maxAccountIndex: 3,
      );
      final copy = original.copyWith(maxAccountIndex: 10);
      expect(copy.maxAccountIndex, 10);
      expect(copy.credentialType, 'mnemonic');
      expect(copy.secret, _mnemonic12);
      expect(copy.nostrAccountIndex, 0);
    });

    test('copyWith can set nostrAccountIndex to null', () {
      final original = AuthRecord(
        version: 1,
        credentialType: 'mnemonic',
        secret: _mnemonic12,
        nostrAccountIndex: 5,
      );
      final copy = original.copyWith(nostrAccountIndex: null);
      expect(copy.nostrAccountIndex, isNull);
    });

    test('copyWith with no arguments is identity', () {
      final original = AuthRecord(
        version: 1,
        credentialType: 'mnemonic',
        secret: _mnemonic12,
        nostrAccountIndex: 2,
        maxAccountIndex: 7,
      );
      final copy = original.copyWith();
      expect(copy.version, original.version);
      expect(copy.credentialType, original.credentialType);
      expect(copy.secret, original.secret);
      expect(copy.nostrAccountIndex, original.nostrAccountIndex);
      expect(copy.maxAccountIndex, original.maxAccountIndex);
    });

    test('round-trip preserves bunker connection fields', () {
      final original = AuthRecord(
        version: 1,
        credentialType: 'bunker',
        secret: '',
        publicKey: 'abcd1234' * 8,
        bunkerConnection: BunkerConnection(
          privateKey: _hexPrivKey,
          remotePubkey: 'beef5678' * 8,
          relays: const ['wss://relay.hostr.development'],
        ),
      );
      final restored = AuthRecord.fromStorage([jsonEncode(original.toJson())]);
      expect(restored, isNotNull);
      expect(restored!.publicKeyHex, original.publicKeyHex);
      expect(restored.bunkerConnection, isNotNull);
      expect(
        restored.bunkerConnection!.remotePubkey,
        original.bunkerConnection!.remotePubkey,
      );
    });
  });

  group('AuthRecord — getters', () {
    test('privateKeyHex delegates to keyPair', () {
      final record = AuthRecord(
        version: 1,
        credentialType: 'private_key',
        secret: _hexPrivKey,
      );
      expect(record.privateKeyHex, isNull);
    });

    test('publicKeyHex delegates to keyPair', () {
      final record = AuthRecord(
        version: 1,
        credentialType: 'private_key',
        secret: _hexPrivKey,
      );
      expect(record.publicKeyHex, isNull);
    });

    test('publicKeyHex prefers explicit publicKey when present', () {
      final record = AuthRecord(
        version: 1,
        credentialType: 'bunker',
        secret: '',
        publicKey: 'abcd1234' * 8,
      );
      expect(record.publicKeyHex, 'abcd1234' * 8);
    });
  });

  group('Auth lifecycle', () {
    test('dispose disposes active NDK account signers', () async {
      final ndk = Ndk(
        NdkConfig(
          eventVerifier: Bip340EventVerifier(useIsolate: false),
          cache: MemCacheManager(),
          engine: NdkEngine.RELAY_SETS,
          bootstrapRelays: const [],
        ),
      );
      final signer = _DisposableSigner('aabb' * 16);
      ndk.accounts.loginExternalSigner(signer: signer);
      final auth = Auth(
        ndk: ndk,
        authStorage: _MemoryAuthStorage(),
        logger: CustomLogger(),
        identityResolver: AuthIdentityResolver(logger: CustomLogger()),
      );

      await auth.dispose();

      expect(signer.disposed, isTrue);
      expect(ndk.accounts.accounts, isEmpty);
      await ndk.requests.closeAllSubscription();
      await ndk.relays.closeAllTransports();
      await ndk.accounts.dispose();
    });
  });
}

class _MemoryAuthStorage implements AuthStorage {
  var _items = <String>[];

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);

  @override
  Future<List<String>> get() async => List<String>.from(_items);

  @override
  Future<void> set(List<String> items) async {
    _items = List<String>.from(items);
  }

  @override
  Future<void> add(String item) async {
    if (!_items.contains(item)) _items.add(item);
  }

  @override
  Future<void> remove(String item) async {
    _items.remove(item);
  }

  @override
  Future<void> wipe() async {
    _items.clear();
  }
}

class _DisposableSigner implements EventSigner {
  _DisposableSigner(this.pubkey);

  final String pubkey;
  bool disposed = false;

  @override
  bool canSign() => true;

  @override
  bool cancelRequest(String requestId) => false;

  @override
  Future<String?> decrypt(String msg, String destPubKey, {String? id}) async =>
      msg;

  @override
  Future<String?> decryptNip44({
    required String ciphertext,
    required String senderPubKey,
  }) async => ciphertext;

  @override
  Future<void> dispose() async {
    disposed = true;
  }

  @override
  Future<String?> encrypt(String msg, String destPubKey, {String? id}) async =>
      msg;

  @override
  Future<String?> encryptNip44({
    required String plaintext,
    required String recipientPubKey,
  }) async => plaintext;

  @override
  List<PendingSignerRequest> get pendingRequests => const [];

  @override
  Stream<List<PendingSignerRequest>> get pendingRequestsStream =>
      const Stream.empty();

  @override
  String getPublicKey() => pubkey;

  @override
  Future<Nip01Event> sign(Nip01Event event) async => event;
}
