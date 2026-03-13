import 'dart:async';
import 'dart:io';

import 'package:injectable/injectable.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart' hide Requests;

import '../../config.dart';
import '../../injection.dart';
import '../../util/main.dart';
import '../requests/requests.dart';
import '../storage/storage.dart';

@Singleton(env: Env.allButTestAndMock)
class Relays {
  final CustomLogger _logger;
  final Ndk _ndk;
  final RelayStorage _relayStorage;
  CustomLogger get logger => _logger;
  Ndk get ndk => _ndk;
  RelayStorage get relayStorage => _relayStorage;

  Relays({
    required Ndk ndk,
    required RelayStorage relayStorage,
    required CustomLogger logger,
  }) : _ndk = ndk,
       _relayStorage = relayStorage,
       _logger = logger;

  Future<void> add(String url) => _logger.span('add', () async {
    _logger.d('Adding relay: $url');
    return _ndk.relays
        .connectRelay(dirtyUrl: url, connectionSource: ConnectionSource.seed)
        .then((value) async {
          _logger.i('Connected to relay: $url success: ${value.first}');
          if (value.first == true) {
            await _relayStorage.add(url);
          } else {
            throw Exception(value.second);
          }
        });
  });

  Future<void> remove(String url) => _logger.span('remove', () async {
    _logger.d('Removing relay: $url');

    List<RelayConnectivity<dynamic>> relays = _ndk.relays.connectedRelays;
    for (var relay in relays) {
      if (relay.url == url) {
        await relay.close();
      }
    }
    await _relayStorage.remove(url);
  });

  Future<void> connect() => _logger.span('connect', () async {
    final config = getIt<HostrConfig>();
    final configured = config.bootstrapRelays;

    try {
      // First attempt a connection without NDK. NDK will error after 4 seconds and prevent future reconnects for a long timeout.
      // However, debug mode over wireless can result in network access being locked for 20+ seconds, so we want to use a longer than NDK timeout to attempt connection.
      // https://www.reddit.com/r/iOSProgramming/comments/1nvksc7/network_requests_are_failing_for_first_30_seconds/?utm_source=chatgpt.com

      final sw = Stopwatch()..start();
      final ws = await WebSocket.connect(configured.first);
      sw.stop();
      await ws.close();
    } catch (_) {}
    if (configured.isEmpty) return;

    await Future.wait(
      configured.map(
        (url) => _ndk.relays.connectRelay(
          dirtyUrl: url,
          connectionSource: ConnectionSource.seed,
        ),
      ),
    );
  });

  /// Returns a future that completes once at least one relay is connected.
  ///
  /// On a cold start over wireless/Tailscale the initial WebSocket handshake
  /// may take several seconds. This method polls [Ndk.relays.connectedRelays]
  /// with backoff so that callers can await relay readiness before issuing
  /// queries that would otherwise silently return empty results.
  ///
  /// Safe to call from multiple places — all callers share the same future.
  Future<void> ensureConnected() => _logger.span('ensureConnected', () async {
    _logger.d('Ensuring relay connectivity…');
    return _waitForConnection();
  });

  Future<void> _waitForConnection() => _logger.span(
    '_waitForConnection',
    () async {
      const timeout = Duration(seconds: 30);
      const pollInterval = Duration(seconds: 1);

      // Poll until at least one relay is connected or we exceed the timeout.
      final deadline = DateTime.now().add(timeout);
      while (DateTime.now().isBefore(deadline)) {
        if (_ndk.relays.connectedRelays.isNotEmpty) {
          return;
        }
        getIt<HostrConfig>().bootstrapRelays.map(
          (e) => _ndk.relays.isRelayConnecting(e)
              ? _ndk.relays.reconnectRelay(
                  e,
                  connectionSource: ConnectionSource.seed,
                )
              : null,
        );
        _logger.d('Checking relay connectivity…');
        await Future.delayed(pollInterval);
      }
      throw Exception('Timed out waiting for relay connection after $timeout');
    },
  );

  Stream<Map<String, RelayConnectivity<dynamic>>> connectivity() {
    return _ndk.relays.relayConnectivityChanges;
  }

  /// Fetches the user's NIP-65 relay list and connects to any relays
  /// not already connected. This populates NDK's cache so the outbox/inbox
  /// model works automatically for broadcasts and queries.
  Future<void> syncNip65(String pubkey) => logger.span('syncNip65', () async {
    logger.i('Syncing NIP-65 relay list for $pubkey');
    try {
      final relayList = await ndk.userRelayLists.getSingleUserRelayList(
        pubkey,
        forceRefresh: true,
      );
      if (relayList == null || relayList.urls.isEmpty) {
        logger.i('No NIP-65 relay list found for $pubkey');
        return;
      }
      logger.i('Found ${relayList.urls.length} relays in NIP-65 list');

      final connectedUrls = ndk.relays.connectedRelays
          .map((r) => r.url)
          .toSet();

      await Future.wait(
        relayList.urls
            .where((url) => !connectedUrls.contains(url))
            .map(
              (url) => add(url).catchError((e) {
                logger.w('Failed to connect to NIP-65 relay $url: $e');
              }),
            ),
      );
    } catch (e) {
      logger.e('Error syncing NIP-65 relay list: $e');
    }
  });

  /// Publishes the user's NIP-65 relay list, ensuring the given
  /// [hostrRelay] is included with read+write markers.
  Future<void> publishNip65({
    required String hostrRelay,
    required String pubkey,
  }) => logger.span('publishNip65', () async {
    logger.i('Publishing NIP-65 relay list with hostr relay: $hostrRelay');
    try {
      final before = await ndk.userRelayLists.getSingleUserRelayList(pubkey);
      if (before != null) {
        logger.d(
          'NIP-65 before publish: ${before.relays.entries.map((e) => '${e.key} → ${e.value}').join(', ')}',
        );
      } else {
        logger.d('NIP-65 before publish: no existing list');
      }

      await ndk.userRelayLists.broadcastAddNip65Relay(
        relayUrl: hostrRelay,
        marker: ReadWriteMarker.readWrite,
        broadcastRelays: ndk.relays.connectedRelays.map((r) => r.url),
      );

      final after = await ndk.userRelayLists.getSingleUserRelayList(pubkey);
      if (after != null) {
        logger.d(
          'NIP-65 after publish: ${after.relays.entries.map((e) => '${e.key} → ${e.value}').join(', ')}',
        );
      }
    } catch (e) {
      logger.e('Error publishing NIP-65 relay list: $e');
    }
  });
}

@Singleton(as: Relays, env: [Env.test, Env.mock])
class MockRelays extends Relays {
  MockRelays({
    required super.ndk,
    required super.relayStorage,
    required super.logger,
  });

  /// No real relays to connect to in test/mock.
  @override
  Future<void> connect() async {}

  @override
  Future<void> ensureConnected() async {}

  /// Reads kind-10002 (NIP-65) events from [InMemoryRequests] and
  /// pre-seeds NDK's [CacheManager] so that
  /// `ndk.userRelayLists.getSingleUserRelayList(pubkey)` returns
  /// instantly from cache — zero WebSocket IO.
  @override
  Future<void> syncNip65(String pubkey) async {
    logger.i('MockRelays: syncing NIP-65 from InMemoryRequests for $pubkey');
    final requests = getIt<Requests>();
    Nip01Event? latest;
    await for (final event in requests.query(
      filter: Filter(authors: [pubkey], kinds: [Nip65.kKind]),
    )) {
      if (latest == null || event.createdAt > latest.createdAt) {
        latest = event;
      }
    }
    if (latest == null) {
      logger.i('MockRelays: no NIP-65 event found for $pubkey');
      return;
    }
    final nip65 = Nip65.fromEvent(latest);
    final userRelayList = UserRelayList.fromNip65(nip65);
    await ndk.config.cache.saveUserRelayList(userRelayList);
    logger.i(
      'MockRelays: cached ${userRelayList.urls.length} relays for $pubkey',
    );
  }

  /// No relay to publish NIP-65 to.
  @override
  Future<void> publishNip65({
    required String hostrRelay,
    required String pubkey,
  }) async {}
}
