@Tags(['unit'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:get_it/get_it.dart';
import 'package:hostr_sdk/config.dart';
import 'package:hostr_sdk/injection.dart' show HostrScope;
import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/auth/auth_identity_resolver.dart';
import 'package:marketplace_evm/usecase/evm/config/evm_config.dart';
import 'package:hostr_sdk/usecase/requests/requests.dart' as sdk_requests;
import 'package:hostr_sdk/usecase/storage/storage.dart';
import 'package:marketplace_evm/util/custom_logger.dart';
import 'package:marketplace_models/nostr_kinds.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

const _hexPrivKey =
    'e8f32e723decf4051aefac8e2c93c9c5b214313817cdb01a1494b917c8436b35';

void main() {
  group('NIP-42 auth flow', () {
    test('sign-in alone does not authenticate a relay socket', () async {
      await _withRelay((relay, auth, requests) async {
        await auth.signin(_hexPrivKey).timeout(const Duration(seconds: 4));
        // Give unsolicited relay challenges a turn through the socket listener.
        await Future<void>.delayed(const Duration(milliseconds: 100));
        expect(relay.authMessagesReceived, 0);
        expect(relay.acceptedEvents, isEmpty);
      });
    });

    test('first listing write authenticates once and later writes reuse its socket', () async {
      await _withRelay((relay, auth, requests) async {
        await auth.signin(_hexPrivKey).timeout(const Duration(seconds: 4));
        expect(relay.authMessagesReceived, 0);
        await _writeListing(requests, auth, relay.url, 'first');
        expect(relay.authMessagesReceived, 1);
        await _writeListing(requests, auth, relay.url, 'second');

        expect(relay.authMessagesReceived, 1);
        expect(relay.authPubkeysReceived, [Bip340.getPublicKey(_hexPrivKey)]);
        expect(relay.acceptedEvents, hasLength(2));
        expect(
          relay.acceptedEvents.map((e) => e.socketId).toSet(),
          hasLength(1),
        );
        expect(relay.acceptedEvents.map((e) => e.authPubkey).toSet(), {
          Bip340.getPublicKey(_hexPrivKey),
        });
      });
    });

    test(
      'account switch authenticates the next write with the new identity',
      () async {
        await _withRelay((relay, auth, requests) async {
          final secondKey = Bip340.generatePrivateKey();
          await auth.signin(_hexPrivKey).timeout(const Duration(seconds: 4));
          await _writeListing(requests, auth, relay.url, 'first-user');
          expect(relay.authMessagesReceived, 1);
          final oldSocket = relay.acceptedEvents.single.socketId;

          await auth
              .signin(secondKey.privateKey!)
              .timeout(const Duration(seconds: 4));
          expect(relay.authMessagesReceived, 1);
          await _writeListing(requests, auth, relay.url, 'second-user');

          expect(relay.authMessagesReceived, 2);
          expect(relay.authPubkeysReceived, [
            Bip340.getPublicKey(_hexPrivKey),
            secondKey.publicKey,
          ]);
          expect(relay.acceptedEvents, hasLength(2));
          expect(relay.acceptedEvents.last.socketId, isNot(oldSocket));
          expect(relay.acceptedEvents.last.authPubkey, secondKey.publicKey);
          expect(
            relay.acceptedEvents.last.event['pubkey'],
            secondKey.publicKey,
          );
        });
      },
    );

    test(
      'logout closes an authenticated socket before the next login and write',
      () async {
        await _withRelay((relay, auth, requests) async {
          final secondKey = Bip340.generatePrivateKey();
          await auth.signin(_hexPrivKey).timeout(const Duration(seconds: 4));
          await _writeListing(requests, auth, relay.url, 'before-logout');
          expect(relay.authMessagesReceived, 1);
          expect(relay.activeSocketCount, 1);
          final oldSocket = relay.acceptedEvents.single.socketId;

          await auth.logout().timeout(const Duration(seconds: 4));
          await _waitFor(
            () => relay.activeSocketCount == 0,
            timeout: const Duration(seconds: 2),
          );
          await auth
              .signin(secondKey.privateKey!)
              .timeout(const Duration(seconds: 4));
          expect(relay.authMessagesReceived, 1);
          await _writeListing(requests, auth, relay.url, 'after-logout');

          expect(relay.authMessagesReceived, 2);
          expect(relay.authPubkeysReceived, [
            Bip340.getPublicKey(_hexPrivKey),
            secondKey.publicKey,
          ]);
          expect(relay.acceptedEvents, hasLength(2));
          expect(relay.acceptedEvents.last.socketId, isNot(oldSocket));
          expect(relay.acceptedEvents.last.authPubkey, secondKey.publicKey);
        });
      },
    );

    test(
      'ephemeral gift-wrap author authenticates with the logged-in identity',
      () async {
        await _withRelay((relay, auth, requests) async {
          final ephemeralKey = Bip340.generatePrivateKey();
          await auth.signin(_hexPrivKey).timeout(const Duration(seconds: 4));
          final giftWrap = _signedEvent(
            key: ephemeralKey,
            kind: kNostrKindGiftWrap,
            content: 'encrypted gift wrap',
          );
          await requests
              .broadcastEvent(event: giftWrap, relays: [relay.url])
              .timeout(const Duration(seconds: 4));

          expect(relay.authMessagesReceived, 1);
          expect(relay.authPubkeysReceived, [Bip340.getPublicKey(_hexPrivKey)]);
          expect(relay.acceptedEvents, hasLength(1));
          expect(
            relay.acceptedEvents.single.event['pubkey'],
            ephemeralKey.publicKey,
          );
          expect(
            relay.acceptedEvents.single.authPubkey,
            Bip340.getPublicKey(_hexPrivKey),
          );
          expect(
            relay.acceptedEvents.single.authPubkey,
            isNot(ephemeralKey.publicKey),
          );
        });
      },
    );
  });
}

Future<void> _withRelay(
  Future<void> Function(_Nip42Relay, Auth, sdk_requests.Requests) action,
) async {
  final relay = _Nip42Relay(requireAuthForEvents: true);
  await relay.start();
  final ndk = _ndkFor(relay.url);
  final auth = _authFor(ndk: ndk, relayUrl: relay.url);
  final requests = sdk_requests.Requests(
    ndk: ndk,
    logger: CustomLogger(),
    auth: auth,
    config: _hostrConfig(relay.url),
  );
  try {
    await action(relay, auth, requests);
  } finally {
    await auth.dispose();
    await ndk.destroy();
    await relay.stop();
  }
}

Future<void> _writeListing(
  sdk_requests.Requests requests,
  Auth auth,
  String relayUrl,
  String id,
) => requests
    .broadcastEvent(
      event: Nip01Event(
        pubKey: auth.activePubkey!,
        kind: kNostrKindListing,
        tags: [
          ['d', id],
        ],
        content: '{}',
        createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
      ),
      relays: [relayUrl],
    )
    .timeout(const Duration(seconds: 4));

Future<void> _waitFor(
  bool Function() condition, {
  required Duration timeout,
}) async {
  final deadline = DateTime.now().add(timeout);
  while (DateTime.now().isBefore(deadline)) {
    if (condition()) return;
    await Future<void>.delayed(const Duration(milliseconds: 25));
  }
  if (condition()) return;
  throw TimeoutException('Condition was not met before $timeout', timeout);
}

Ndk _ndkFor(String relayUrl) {
  return Ndk(
    NdkConfig(
      eventVerifier: Bip340EventVerifier(useIsolate: false),
      cache: MemCacheManager(),
      engine: NdkEngine.RELAY_SETS,
      bootstrapRelays: [relayUrl],
    ),
  );
}

Auth _authFor({required Ndk ndk, required String relayUrl}) {
  final scope = HostrScope(GetIt.asNewInstance());
  scope.registerSingleton<HostrConfig>(_hostrConfig(relayUrl));
  return Auth(
    ndk: ndk,
    authStorage: _MemoryAuthStorage(),
    logger: CustomLogger(),
    identityResolver: AuthIdentityResolver(logger: CustomLogger()),
    scope: scope,
  );
}

HostrConfig _hostrConfig(String relayUrl) {
  return HostrConfig(
    bootstrapRelays: [relayUrl],
    bootstrapBlossom: const [],
    hostrRelay: relayUrl,
    evmConfig: const EvmConfig(),
    ndk: NdkConfig(
      eventVerifier: Bip340EventVerifier(useIsolate: false),
      cache: MemCacheManager(),
      engine: NdkEngine.RELAY_SETS,
      bootstrapRelays: [relayUrl],
    ),
  );
}

Nip01Event _signedEvent({
  required KeyPair key,
  required int kind,
  required String content,
}) {
  final event = Nip01Event(
    pubKey: key.publicKey,
    kind: kind,
    tags: const [],
    content: content,
    createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
  );
  return Nip01Utils.signWithPrivateKey(
    event: event,
    privateKey: key.privateKey!,
  );
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

class _Nip42Relay {
  _Nip42Relay({this.requireAuthForEvents = false});

  final bool requireAuthForEvents;
  final _sockets = <WebSocket>{};
  final _authenticatedSockets = <WebSocket>{};
  final _socketIds = <WebSocket, int>{};
  final _authPubkeysBySocket = <WebSocket, String>{};
  int _nextSocketId = 0;
  final acceptedEvents =
      <({int socketId, String? authPubkey, Map<String, dynamic> event})>[];
  HttpServer? _server;

  int authMessagesReceived = 0;
  int eventMessagesReceived = 0;
  final authPubkeysReceived = <String>[];

  String get url => 'ws://localhost:${_server!.port}';
  int get activeSocketCount => _sockets.length;

  Future<void> start() async {
    _server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    _server!.transform(WebSocketTransformer()).listen(_handleSocket);
  }

  Future<void> stop() async {
    for (final socket in _sockets.toList()) {
      await socket.close();
    }
    _sockets.clear();
    _authenticatedSockets.clear();
    await _server?.close(force: true);
  }

  void _handleSocket(WebSocket socket) {
    _sockets.add(socket);
    _socketIds[socket] = _nextSocketId++;
    socket.add(jsonEncode(['AUTH', 'challenge']));
    socket.listen(
      (message) {
        final decoded = jsonDecode(message as String) as List<dynamic>;
        final type = decoded.first as String;
        switch (type) {
          case 'AUTH':
            authMessagesReceived++;
            _authenticatedSockets.add(socket);
            final event = decoded[1] as Map<String, dynamic>;
            expect(event['kind'], 22242);
            expect(event['tags'], contains(equals(['challenge', 'challenge'])));
            expect(event['tags'], contains(equals(['relay', url])));
            expect(
              Bip340.verify(
                event['id'] as String,
                event['sig'] as String,
                event['pubkey'] as String,
              ),
              isTrue,
            );
            authPubkeysReceived.add(event['pubkey'] as String);
            _authPubkeysBySocket[socket] = event['pubkey'] as String;
            socket.add(jsonEncode(['OK', event['id'], true, '']));
            return;
          case 'EVENT':
            eventMessagesReceived++;
            final event = decoded[1] as Map<String, dynamic>;
            if (requireAuthForEvents &&
                !_authenticatedSockets.contains(socket)) {
              socket.add(
                jsonEncode([
                  'OK',
                  event['id'],
                  false,
                  'auth-required: authenticated connection required',
                ]),
              );
              return;
            }
            acceptedEvents.add((
              socketId: _socketIds[socket]!,
              authPubkey: _authPubkeysBySocket[socket],
              event: event,
            ));
            socket.add(jsonEncode(['OK', event['id'], true, '']));
            return;
          case 'REQ':
            final reqId = decoded[1] as String;
            socket.add(jsonEncode(['EOSE', reqId]));
            return;
        }
      },
      onDone: () {
        _sockets.remove(socket);
        _authenticatedSockets.remove(socket);
        _authPubkeysBySocket.remove(socket);
      },
    );
  }
}
