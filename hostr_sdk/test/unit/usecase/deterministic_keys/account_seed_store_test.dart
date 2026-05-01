@Tags(['unit'])
library;

import 'dart:async';
import 'dart:convert';

import 'package:hostr_sdk/config.dart';
import 'package:hostr_sdk/datasources/app_database.dart';
import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/deterministic_keys/account_seed_store.dart';
import 'package:hostr_sdk/usecase/evm/config/evm_config.dart';
import 'package:hostr_sdk/usecase/requests/requests.dart';
import 'package:hostr_sdk/usecase/storage/storage.dart';
import 'package:hostr_sdk/util/deterministic_key_derivation.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:mockito/mockito.dart';
import 'package:models/main.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/entities.dart' show RelayBroadcastResponse;
import 'package:ndk/ndk.dart'
    show
        Account,
        AccountType,
        Accounts,
        EventSigner,
        Filter,
        Ndk,
        Nip01Event,
        PendingSignerRequest;
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:sqlite3/sqlite3.dart' as sqlite3;
import 'package:test/test.dart';

void main() {
  group('AccountSeedStore startup seed backup behavior', () {
    test(
      'launch with nsec and no seed backup publishes deterministic seed backup',
      () async {
        final keyPair = MockKeys.guest;
        final fixture = _buildFixture(activeKeyPair: keyPair);
        final expected = await deriveHostrSeedHexFromPrivateKey(
          keyPair.privateKey!,
        );

        final seed = await fixture.store.getActiveSeedHex();

        expect(seed, expected);
        expect(await fixture.storage.getSeed(), expected);
        expect(fixture.requests.seedEventsFor(keyPair.publicKey), hasLength(1));
        expect(
          await fixture.decryptBroadcastSeedFor(keyPair.publicKey),
          expected,
        );
      },
    );

    test(
      'launch with bunker and no seed backup publishes random seed backup',
      () async {
        final publicOnly = KeyPair.justPublicKey(MockKeys.guest.publicKey);
        final fixture = _buildFixture(activeKeyPair: publicOnly);
        final deterministic = await deriveHostrSeedHexFromPrivateKey(
          MockKeys.guest.privateKey!,
        );

        final seed = await fixture.store.getActiveSeedHex();

        expect(seed, matches(RegExp(r'^[0-9a-f]{64}$')));
        expect(seed, isNot(deterministic));
        expect(await fixture.storage.getSeed(), seed);
        expect(
          fixture.requests.seedEventsFor(publicOnly.publicKey),
          hasLength(1),
        );
        expect(
          await fixture.decryptBroadcastSeedFor(publicOnly.publicKey),
          seed,
        );
      },
    );

    test(
      'launch with bunker and rejected seed backup fails startup gate',
      () async {
        final publicOnly = KeyPair.justPublicKey(MockKeys.guest.publicKey);
        final fixture = _buildFixture(activeKeyPair: publicOnly);
        fixture.requests.broadcastResponses = [
          RelayBroadcastResponse(
            relayUrl: 'wss://relay.hostr.network',
            okReceived: true,
            broadcastSuccessful: false,
            msg: 'blocked: kind 17389 not accepted',
          ),
        ];

        await expectLater(
          fixture.store.getActiveSeedHex(),
          throwsA(
            isA<StateError>().having(
              (error) => error.message,
              'message',
              contains('Unable to publish'),
            ),
          ),
        );
        expect(fixture.requests.broadcasts, hasLength(1));
        expect(fixture.requests.seedEventsFor(publicOnly.publicKey), isEmpty);
      },
    );

    test(
      'launch with nsec and existing seed backup uses backup seed',
      () async {
        final keyPair = MockKeys.guest;
        final remoteSeed = _seedHex('a1');
        final fixture = _buildFixture(activeKeyPair: keyPair);
        fixture.seedRemoteSeed(pubkey: keyPair.publicKey, seedHex: remoteSeed);

        final seed = await fixture.store.getActiveSeedHex();

        expect(seed, remoteSeed);
        expect(await fixture.storage.getSeed(), remoteSeed);
        expect(
          seed,
          isNot(await deriveHostrSeedHexFromPrivateKey(keyPair.privateKey!)),
        );
        expect(fixture.requests.broadcasts, isEmpty);
      },
    );

    test(
      'launch with bunker and existing seed backup uses backup seed',
      () async {
        final publicOnly = KeyPair.justPublicKey(MockKeys.guest.publicKey);
        final remoteSeed = _seedHex('b2');
        final fixture = _buildFixture(activeKeyPair: publicOnly);
        fixture.seedRemoteSeed(
          pubkey: publicOnly.publicKey,
          seedHex: remoteSeed,
        );

        final seed = await fixture.store.getActiveSeedHex();

        expect(seed, remoteSeed);
        expect(await fixture.storage.getSeed(), remoteSeed);
        expect(fixture.requests.broadcasts, isEmpty);
      },
    );
  });
}

_SeedFixture _buildFixture({required KeyPair activeKeyPair}) {
  final db = AppDatabase(sqlite3.sqlite3.openInMemory());
  addTearDown(db.db.close);
  final config = HostrConfig(
    appDatabase: db,
    bootstrapRelays: const [],
    bootstrapBlossom: const [],
    hostrRelay: '',
    evmConfig: const EvmConfig(),
  );
  final auth = _FakeAuth(activeKeyPair);
  final storage = AccountSeedStorage(config, auth);
  final signer = _SeedEventSigner(publicKey: activeKeyPair.publicKey);
  final ndk = _FakeNdk(_FakeAccounts(activeKeyPair.publicKey, signer));
  final requests = _SeedRequests(ndk);
  final store = AccountSeedStore(
    auth: auth,
    ndk: ndk,
    requests: requests,
    storage: storage,
    logger: CustomLogger(),
    config: config,
  );

  return _SeedFixture(
    store: store,
    storage: storage,
    requests: requests,
    signer: signer,
  );
}

class _SeedFixture {
  final AccountSeedStore store;
  final AccountSeedStorage storage;
  final _SeedRequests requests;
  final _SeedEventSigner signer;

  const _SeedFixture({
    required this.store,
    required this.storage,
    required this.requests,
    required this.signer,
  });

  void seedRemoteSeed({required String pubkey, required String seedHex}) {
    requests.addSeedEvent(pubkey: pubkey, content: signer.encodeSeed(seedHex));
  }

  Future<String> decryptBroadcastSeedFor(String pubkey) {
    final event = requests.seedEventsFor(pubkey).single;
    return signer.decryptSeed(event.content, pubkey);
  }
}

class _FakeAuth extends Fake implements Auth {
  final KeyPair _activeKeyPair;

  _FakeAuth(this._activeKeyPair);

  @override
  KeyPair? get activeKeyPair => _activeKeyPair;

  @override
  String? get activePubkey => _activeKeyPair.publicKey;
}

class _SeedRequests extends Fake implements Requests {
  final Ndk _ndk;
  final List<Nip01Event> _events = [];
  final List<Nip01Event> broadcasts = [];
  List<RelayBroadcastResponse>? broadcastResponses;

  _SeedRequests(this._ndk);

  @override
  Ndk get ndk => _ndk;

  void addSeedEvent({required String pubkey, required String content}) {
    _events.add(
      Nip01Event(
        pubKey: pubkey,
        kind: kNostrKindHostrSeed,
        content: content,
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        tags: const [],
      ),
    );
  }

  List<Nip01Event> seedEventsFor(String pubkey) => _events
      .where((event) => event.kind == kNostrKindHostrSeed)
      .where((event) => event.pubKey == pubkey)
      .toList(growable: false);

  @override
  Stream<T> query<T extends Nip01Event>({
    required Filter filter,
    Duration? timeout,
    List<String>? relays,
    String? name,
    bool cacheRead = true,
    bool cacheWrite = true,
  }) async* {
    for (final event in _events) {
      if (!_matches(event, filter)) continue;
      yield event as T;
    }
  }

  @override
  Future<List<RelayBroadcastResponse>> broadcast({
    required Nip01Event event,
    List<String>? relays,
  }) async {
    broadcasts.add(event);
    final responses = broadcastResponses ?? [_successfulBroadcastResponse()];
    throwIfBroadcastFailed(responses, context: 'fake seed publish ${event.id}');
    if (hasSuccessfulBroadcast(responses)) {
      _events.add(event);
    }
    return responses;
  }

  bool _matches(Nip01Event event, Filter filter) {
    final authors = filter.authors;
    if (authors != null && !authors.contains(event.pubKey)) return false;
    final kinds = filter.kinds;
    if (kinds != null && !kinds.contains(event.kind)) return false;
    return true;
  }
}

class _FakeNdk extends Fake implements Ndk {
  final Accounts _accounts;

  _FakeNdk(this._accounts);

  @override
  Accounts get accounts => _accounts;
}

class _FakeAccounts extends Fake implements Accounts {
  final String _pubkey;
  final EventSigner _signer;

  _FakeAccounts(this._pubkey, this._signer);

  @override
  String? getPublicKey() => _pubkey;

  @override
  Account? getLoggedAccount() => Account(
    type: AccountType.externalSigner,
    pubkey: _pubkey,
    signer: _signer,
  );
}

class _SeedEventSigner extends Fake implements EventSigner {
  final String publicKey;

  _SeedEventSigner({required this.publicKey});

  String encodeSeed(String seedHex) =>
      'seed:${jsonEncode({'v': 1, 'seed': seedHex})}';

  Future<String> decryptSeed(String ciphertext, String pubkey) async {
    final plaintext = await decryptNip44(
      ciphertext: ciphertext,
      senderPubKey: pubkey,
    );
    final decoded = jsonDecode(plaintext!) as Map<String, dynamic>;
    return decoded['seed'] as String;
  }

  @override
  String getPublicKey() => publicKey;

  @override
  bool canSign() => true;

  @override
  Future<Nip01Event> sign(Nip01Event event) async => event;

  @override
  Future<String?> encryptNip44({
    required String plaintext,
    required String recipientPubKey,
  }) async {
    return 'seed:$plaintext';
  }

  @override
  Future<String?> decryptNip44({
    required String ciphertext,
    required String senderPubKey,
  }) async {
    if (!ciphertext.startsWith('seed:')) return null;
    return ciphertext.substring('seed:'.length);
  }

  @override
  Future<String?> decrypt(String msg, String destPubKey, {String? id}) async =>
      null;

  @override
  Future<String?> encrypt(String msg, String destPubKey, {String? id}) async =>
      null;

  @override
  Stream<List<PendingSignerRequest>> get pendingRequestsStream =>
      const Stream.empty();

  @override
  List<PendingSignerRequest> get pendingRequests => const [];

  @override
  bool cancelRequest(String requestId) => false;

  @override
  Future<void> dispose() async {}
}

String _seedHex(String byteHex) => List.filled(32, byteHex).join();

RelayBroadcastResponse _successfulBroadcastResponse() {
  return RelayBroadcastResponse(
    relayUrl: 'wss://relay.hostr.network',
    okReceived: true,
    broadcastSuccessful: true,
  );
}
