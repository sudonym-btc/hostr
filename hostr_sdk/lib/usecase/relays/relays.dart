import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart' hide Requests;

import '../../config.dart';
import '../../injection.dart';
import '../../util/main.dart';
import '../requests/requests.dart';
import '../storage/storage.dart';
import 'relay_preflight.dart';

@Singleton(env: Env.allButTestAndMock)
class Relays {
  final CustomLogger _logger;
  final Ndk _ndk;
  final RelayStorage _relayStorage;
  Future<void>? _startSeedRelaysFuture;
  Future<void>? _coreRelayReadyFuture;
  Future<void>? _reconnectNowFuture;
  DateTime? _lastReconnectNowAt;
  final Map<String, DateTime> _nextCoreRelayConnectTry = {};
  CustomLogger get logger => _logger;
  Ndk get ndk => _ndk;
  RelayStorage get relayStorage => _relayStorage;

  static const _coreRelayConnectRetryInterval = Duration(seconds: 15);
  static const _reconnectNowDebounce = Duration(seconds: 10);
  static const _developmentRelay = 'wss://relay.hostr.development';

  Relays({
    required Ndk ndk,
    required RelayStorage relayStorage,
    required CustomLogger logger,
  }) : _ndk = ndk,
       _relayStorage = relayStorage,
       _logger = logger.scope('relays');

  /// Returns a relay URL hint for the given [pubkey] by looking up their
  /// NIP-65 write relays. Returns the first write relay found, or empty
  /// string if none is cached.
  Future<String> relayHintFor(String pubkey) async {
    try {
      final relayList = await _ndk.userRelayLists.getSingleUserRelayList(
        pubkey,
      );
      if (relayList != null) {
        final writeUrls = relayList.relays.entries
            .where(
              (e) =>
                  e.value == ReadWriteMarker.readWrite ||
                  e.value == ReadWriteMarker.writeOnly,
            )
            .map((e) => e.key);
        if (writeUrls.isNotEmpty) return writeUrls.first;
      }
    } catch (_) {
      // Lookup failure — return empty hint
    }
    return '';
  }

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

  Future<void> startSeedRelays() {
    return _startSeedRelaysFuture ??= _logger
        .span('startSeedRelays', _startSeedRelays)
        .catchError((Object error) {
          _startSeedRelaysFuture = null;
          throw error;
        });
  }

  Future<void> _startSeedRelays() async {
    final config = getIt<HostrConfig>();
    _blockDevelopmentRelayOutsideDevelopment(config);

    final coreRelays = config.hostrRelay.isNotEmpty
        ? [config.hostrRelay]
        : config.bootstrapRelays;
    if (coreRelays.isEmpty) return;

    // On native platforms we warm up the first relay socket before delegating
    // to NDK. On web this is a no-op because dart:io WebSocket is unavailable.
    await warmUpRelayConnection(coreRelays.first);

    await Future.wait(
      coreRelays.map(
        (url) => _ndk.relays.connectRelay(
          dirtyUrl: url,
          connectionSource: ConnectionSource.seed,
        ),
      ),
    );
  }

  void _blockDevelopmentRelayOutsideDevelopment(HostrConfig config) {
    if (config.hostrRelay == _developmentRelay) return;
    // Temporary guard: prod NIP-65 data was polluted with the development
    // relay. The better fix is to remove that relay from the NIP-65 event.
    _ndk.relays.globalState.blockedRelays.add(_developmentRelay);
  }

  /// Returns a future that completes once at least one relay is connected.
  ///
  /// On a cold start over wireless/Tailscale the initial WebSocket handshake
  /// may take several seconds. This method waits for the core Hostr relay
  /// readiness condition used by startup before Hostr-specific flows proceed.
  ///
  /// Safe to call from multiple places — all callers share the same future
  /// until it fails, after which the next call retries.
  Future<void> awaitCoreRelay({
    Duration timeout = const Duration(seconds: 30),
  }) {
    return _coreRelayReadyFuture ??= _logger
        .span('awaitCoreRelay', () => _waitForConnection(timeout: timeout))
        .catchError((Object error) {
          _coreRelayReadyFuture = null;
          throw error;
        });
  }

  Future<void> _waitForConnection({
    Duration timeout = const Duration(seconds: 30),
  }) => _logger.span('_waitForConnection', () async {
    const pollInterval = Duration(seconds: 1);

    final config = getIt<HostrConfig>();
    final preferredRelay = config.hostrRelay;

    // Poll until the Hostr relay is connected, or at least one relay when
    // no Hostr relay is configured. Hostr-specific requests are guarded onto
    // the Hostr relay, so an arbitrary third-party connection is not enough
    // for the app to be ready.
    final deadline = DateTime.now().add(timeout);
    while (DateTime.now().isBefore(deadline)) {
      final connectedUrls = _ndk.relays.connectedRelays
          .map((relay) => relay.url)
          .toSet();
      if (preferredRelay.isNotEmpty) {
        if (connectedUrls.contains(preferredRelay)) return;
      } else if (connectedUrls.isNotEmpty) {
        return;
      }

      final reconnectTargets = preferredRelay.isNotEmpty
          ? [preferredRelay]
          : config.bootstrapRelays;
      for (final url in reconnectTargets) {
        if (connectedUrls.contains(url) || _ndk.relays.isRelayConnecting(url)) {
          continue;
        }
        _connectCoreRelayCandidate(url);
      }

      final targetDescription = preferredRelay.isNotEmpty
          ? preferredRelay
          : 'any relay';
      _logger.d(
        'Checking relay connectivity for $targetDescription… '
        'connected=${connectedUrls.length}/${config.bootstrapRelays.length}',
      );
      await Future.delayed(pollInterval);
    }
    throw Exception('Timed out waiting for relay connection after $timeout');
  });

  void _connectCoreRelayCandidate(String url) {
    final now = DateTime.now();
    final nextTry = _nextCoreRelayConnectTry[url];
    if (nextTry != null && now.isBefore(nextTry)) return;

    _nextCoreRelayConnectTry[url] = now.add(_coreRelayConnectRetryInterval);
    unawaited(
      _ndk.relays
          .connectRelay(
            dirtyUrl: url,
            connectionSource: ConnectionSource.seed,
            connectTimeout: 10,
          )
          .then((result) {
            if (result.first) {
              _nextCoreRelayConnectTry.remove(url);
            } else {
              _nextCoreRelayConnectTry[url] = DateTime.now().add(
                _coreRelayConnectRetryInterval,
              );
            }
          })
          .catchError((Object error, StackTrace stackTrace) {
            _nextCoreRelayConnectTry[url] = DateTime.now().add(
              _coreRelayConnectRetryInterval,
            );
            _logger.w(
              'Relay connection attempt failed for $url',
              error: error,
              stackTrace: stackTrace,
            );
          }),
    );
  }

  Stream<Map<String, RelayConnectivity<dynamic>>> connectivity() {
    return _ndk.relays.relayConnectivityChanges;
  }

  Future<void> reconnectNow() {
    final inFlight = _reconnectNowFuture;
    if (inFlight != null) return inFlight;

    final now = DateTime.now();
    final lastReconnect = _lastReconnectNowAt;
    if (lastReconnect != null &&
        now.difference(lastReconnect) < _reconnectNowDebounce) {
      _logger.d('Skipping relay reconnect; last attempt was recent');
      return Future.value();
    }

    _lastReconnectNowAt = now;
    return _reconnectNowFuture = _logger
        .span('reconnectNow', () async {
          await _ndk.connectivity.tryReconnect();
        })
        .whenComplete(() {
          _reconnectNowFuture = null;
        });
  }

  /// Fetches the user's NIP-65 relay list into NDK's cache.
  ///
  /// NDK's JIT engine connects to the selected read/write relays on demand, so
  /// startup does not need to eagerly connect to every relay in the list.
  Future<bool> loadNip65Hints(String pubkey) =>
      logger.span('loadNip65Hints', () async {
        logger.i('Syncing NIP-65 relay list for $pubkey');
        try {
          await _discoverNip65OnBootstrapRelays(pubkey);
          final relayList = await ndk.userRelayLists.getSingleUserRelayList(
            pubkey,
          );
          if (relayList == null || relayList.urls.isEmpty) {
            logger.i('No NIP-65 relay list found for $pubkey');
            return false;
          }
          logger.i('Found ${relayList.urls.length} relays in NIP-65 list');
          return true;
        } catch (e) {
          logger.e('Error syncing NIP-65 relay list: $e');
          return false;
        }
      });

  Future<void> _discoverNip65OnBootstrapRelays(String pubkey) async {
    final relays = getIt<HostrConfig>().bootstrapRelays;
    if (relays.isEmpty) return;

    Nip01Event? latest;
    await for (final event in getIt<Requests>().query<Nip01Event>(
      filter: Filter(authors: [pubkey], kinds: [Nip65.kKind], limit: 1),
      relays: relays,
      name: 'Nip65-discovery',
    )) {
      if (latest == null || latest.createdAt < event.createdAt) {
        latest = event;
      }
    }

    if (latest == null) return;
    final nip65 = Nip65.fromEvent(latest);
    final userRelayList = UserRelayList.fromNip65(nip65);
    await ndk.config.cache.saveUserRelayList(userRelayList);
  }

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
        broadcastRelays: [hostrRelay],
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

  @override
  Future<void> startSeedRelays() async {}

  @override
  Future<void> awaitCoreRelay({
    Duration timeout = const Duration(seconds: 30),
  }) async {}

  @override
  Future<void> reconnectNow() async {}

  /// Reads kind-10002 (NIP-65) events from [InMemoryRequests] and
  /// pre-seeds NDK's [CacheManager] so that
  /// `ndk.userRelayLists.getSingleUserRelayList(pubkey)` returns
  /// instantly from cache — zero WebSocket IO.
  @override
  Future<bool> loadNip65Hints(String pubkey) async {
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
      return false;
    }
    final nip65 = Nip65.fromEvent(latest);
    final userRelayList = UserRelayList.fromNip65(nip65);
    await ndk.config.cache.saveUserRelayList(userRelayList);
    logger.i(
      'MockRelays: cached ${userRelayList.urls.length} relays for $pubkey',
    );
    return true;
  }

  /// No relay to publish NIP-65 to.
  @override
  Future<void> publishNip65({
    required String hostrRelay,
    required String pubkey,
  }) async {}
}
