import 'dart:async';

import 'package:hostr_sdk/config.dart';
import 'package:hostr_sdk/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart' hide Requests;

import '../../util/main.dart';
import '../requests/requests.dart';
import '../storage/storage.dart';

@Singleton(env: Env.allButTestAndMock)
class Relays {
  final CustomLogger logger;
  final Ndk ndk;
  final RelayStorage relayStorage;
  Stopwatch? _connectWaitStopwatch;
  Relays({required this.ndk, required this.relayStorage, required this.logger});

  Future<void> add(String url) {
    logger.d('Adding relay: $url');
    return ndk.relays
        .connectRelay(dirtyUrl: url, connectionSource: ConnectionSource.seed)
        .then((value) async {
          logger.i('Connected to relay: $url success: ${value.first}');
          if (value.first == true) {
            await relayStorage.add(url);
          } else {
            throw Exception(value.second);
          }
        });
  }

  Future<void> remove(String url) async {
    logger.d('Removing relay: $url');
    ndk.relays.closeAllTransports();

    List<RelayConnectivity<dynamic>> relays = ndk.relays.connectedRelays;
    for (var relay in relays) {
      if (relay.url == url) {
        await relay.close();
      }
    }
    await relayStorage.remove(url);
  }

  Future<void> connect() {
    return ndk.relays.seedRelaysConnected;
  }

  Completer<void>? _readyCompleter;

  /// Returns a future that completes once at least one relay is connected.
  ///
  /// On a cold start over wireless/Tailscale the initial WebSocket handshake
  /// may take several seconds. This method polls [Ndk.relays.connectedRelays]
  /// with backoff so that callers can await relay readiness before issuing
  /// queries that would otherwise silently return empty results.
  ///
  /// Safe to call from multiple places — all callers share the same future.
  Future<void> ensureConnected() {
    logger.d('Ensuring relay connectivity…');
    if (_readyCompleter != null) return _readyCompleter!.future;
    _readyCompleter = Completer<void>();
    _connectWaitStopwatch = Stopwatch()..start();
    logger.i(
      'relay-connect-wait started at ${DateTime.now().toIso8601String()}',
    );
    _waitForConnection();
    return _readyCompleter!.future;
  }

  Future<void> _waitForConnection() async {
    const timeout = Duration(seconds: 30);
    const pollInterval = Duration(seconds: 1);

    // Already connected — resolve immediately.
    if (ndk.relays.connectedRelays.isNotEmpty) {
      logger.d('Already connected to a relay');
      _connectWaitStopwatch?.stop();
      logger.i(
        'relay-connect-wait done in ${_connectWaitStopwatch?.elapsedMilliseconds ?? 0}ms (already open)',
      );
      _readyCompleter!.complete();
      return;
    }

    // Try the seed-relay future with a short timeout.
    try {
      await ndk.relays.seedRelaysConnected.timeout(const Duration(seconds: 5));
    } catch (_) {
      logger.w('Seed relay connect timed out, polling for connectivity…');
    }

    // NDK can complete seedRelaysConnected even when no relay transport is
    // truly open. Guard on actual connectivity and, if needed, force a
    // reconnect attempt using configured bootstrap relays.
    if (ndk.relays.connectedRelays.isEmpty) {
      final configured = getIt<HostrConfig>().bootstrapRelays;
      if (configured.isNotEmpty) {
        logger.w(
          'No open relay after seed connect. Forcing reconnect on ${configured.length} bootstrap relays…',
        );
        try {
          await ndk.relays.reconnectRelays(configured);
        } catch (e) {
          logger.e('Bootstrap reconnect failed: $e');
        }
      }
    }

    // Poll until at least one relay is connected or we exceed the timeout.
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      logger.d('Checking relay connectivity…');
      if (ndk.relays.connectedRelays.isNotEmpty) {
        if (!_readyCompleter!.isCompleted) {
          _connectWaitStopwatch?.stop();
          logger.i('Relay connected after polling');
          logger.i(
            'relay-connect-wait done in ${_connectWaitStopwatch?.elapsedMilliseconds ?? 0}ms (open relays: ${ndk.relays.connectedRelays.map((r) => r.url).join(', ')})',
          );
          _readyCompleter!.complete();
        }
        logger.d('isConnected');
        return;
      }
      await Future.delayed(pollInterval);
    }

    logger.d('Finished polling for relay connectivity');

    // Give up — complete anyway so callers aren't blocked forever.
    if (!_readyCompleter!.isCompleted) {
      _connectWaitStopwatch?.stop();
      logger.w(
        'No relays connected after ${timeout.inSeconds}s (elapsed ${_connectWaitStopwatch?.elapsedMilliseconds ?? 0}ms), proceeding anyway',
      );
      _readyCompleter!.complete();
    }
  }

  Stream<Map<String, RelayConnectivity<dynamic>>> connectivity() {
    return ndk.relays.relayConnectivityChanges;
  }

  /// Fetches the user's NIP-65 relay list and connects to any relays
  /// not already connected. This populates NDK's cache so the outbox/inbox
  /// model works automatically for broadcasts and queries.
  Future<void> syncNip65(String pubkey) async {
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
  }

  /// Publishes the user's NIP-65 relay list, ensuring the given
  /// [hostrRelay] is included with read+write markers.
  Future<void> publishNip65({
    required String hostrRelay,
    required String pubkey,
  }) async {
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
  }
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
