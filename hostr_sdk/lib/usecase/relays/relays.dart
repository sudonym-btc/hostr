import 'package:hostr_sdk/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/ndk.dart';

import '../../util/main.dart';
import '../storage/storage.dart';

@Singleton(env: Env.allButTestAndMock)
class Relays {
  final CustomLogger logger;
  final Ndk ndk;
  final RelayStorage relayStorage;
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
  Future<void> publishNip65({required String hostrRelay}) async {
    logger.i('Publishing NIP-65 relay list with hostr relay: $hostrRelay');
    try {
      await ndk.userRelayLists.broadcastAddNip65Relay(
        relayUrl: hostrRelay,
        marker: ReadWriteMarker.readWrite,
        broadcastRelays: ndk.relays.connectedRelays.map((r) => r.url),
      );
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
}
