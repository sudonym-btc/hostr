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
import 'package:hostr_sdk/usecase/evm/config/evm_config.dart';
import 'package:hostr_sdk/usecase/requests/requests.dart' as sdk_requests;
import 'package:hostr_sdk/usecase/storage/storage.dart';
import 'package:hostr_sdk/util/custom_logger.dart';
import 'package:models/nostr_kinds.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/bip340.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

const _hexPrivKey =
    'e8f32e723decf4051aefac8e2c93c9c5b214313817cdb01a1494b917c8436b35';

void main() {
  group('NIP-42 auth flow', () {
    test(
      'sign-in and signed-in startup share one AUTH after relay AUTH OK',
      () async {
        final relay = _Nip42Relay();
        await relay.start();

        final ndk = _ndkFor(relay.url);
        final auth = _authFor(ndk: ndk, relayUrl: relay.url);
        StreamSubscription<AuthState>? authSub;
        final startupAuth = Completer<void>();

        try {
          authSub = auth.authState.listen((state) {
            if (state is! LoggedIn || startupAuth.isCompleted) return;
            startupAuth.complete(
              auth.ensureNip42AuthForHostrRelay(
                timeout: const Duration(seconds: 3),
              ),
            );
          });

          await auth.signin(_hexPrivKey).timeout(const Duration(seconds: 4));
          await startupAuth.future.timeout(const Duration(seconds: 4));

          expect(relay.authMessagesReceived, 1);
        } finally {
          await authSub?.cancel();
          await auth.dispose();
          await ndk.destroy();
          await relay.stop();
        }
      },
    );

    test('listing writes reuse sign-in AUTH and do not prompt again', () async {
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
        await auth.signin(_hexPrivKey).timeout(const Duration(seconds: 4));

        final listing = Nip01Event(
          pubKey: auth.activePubkey!,
          kind: kNostrKindListing,
          tags: const [
            ['d', 'listing-auth-test'],
          ],
          content: '{}',
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        );

        await requests
            .broadcastEvent(event: listing, relays: [relay.url])
            .timeout(const Duration(seconds: 4));

        expect(relay.authMessagesReceived, 1);
        expect(relay.eventMessagesReceived, 1);
      } finally {
        await auth.dispose();
        await ndk.destroy();
        await relay.stop();
      }
    });

    test('account switches send a fresh AUTH for the new pubkey', () async {
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
      final secondKey = Bip340.generatePrivateKey();

      try {
        await auth.signin(_hexPrivKey).timeout(const Duration(seconds: 4));
        await auth
            .signin(secondKey.privateKey!)
            .timeout(const Duration(seconds: 4));

        final profile = Nip01Event(
          pubKey: secondKey.publicKey,
          kind: kNostrKindProfile,
          tags: const [],
          content: '{}',
          createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
        );

        await requests
            .broadcastEvent(event: profile)
            .timeout(const Duration(seconds: 4));

        expect(relay.authMessagesReceived, 2);
        expect(relay.authPubkeysReceived, [
          Bip340.getPublicKey(_hexPrivKey),
          secondKey.publicKey,
        ]);
        expect(relay.eventMessagesReceived, 1);
      } finally {
        await auth.dispose();
        await ndk.destroy();
        await relay.stop();
      }
    });

    test(
      'temp-pubkey gift wraps reuse logged-in AUTH for Hostr relay writes',
      () async {
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
        final tempKey = Bip340.generatePrivateKey();

        try {
          await auth.signin(_hexPrivKey).timeout(const Duration(seconds: 4));

          final giftWrap = _signedEvent(
            key: tempKey,
            kind: kNostrKindGiftWrap,
            content: 'encrypted gift wrap',
          );

          await requests
              .broadcastEvent(event: giftWrap, relays: [relay.url])
              .timeout(const Duration(seconds: 4));

          expect(relay.authMessagesReceived, 1);
          expect(relay.eventMessagesReceived, 1);
        } finally {
          await auth.dispose();
          await ndk.destroy();
          await relay.stop();
        }
      },
    );
  });
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
  HttpServer? _server;

  int authMessagesReceived = 0;
  int eventMessagesReceived = 0;
  final authPubkeysReceived = <String>[];

  String get url => 'ws://localhost:${_server!.port}';

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
            authPubkeysReceived.add(event['pubkey'] as String);
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
      },
    );
  }
}
