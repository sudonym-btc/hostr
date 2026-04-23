import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Filter;

import '../../util/main.dart';
import '../auth/auth.dart';
import '../crud.usecase.dart';
import '../requests/requests.dart';

@Singleton()
class Heartbeats extends CrudUseCase<ReceivedHeartbeat> {
  static const Duration defaultDebounceDuration = Duration(seconds: 5);

  final Auth _auth;
  final Duration _debounceDuration;
  Timer? _pendingUpsertTimer;
  Completer<ReceivedHeartbeat>? _pendingUpsertCompleter;
  int? _pendingCreatedAt;
  List<List<String>> _pendingExtraTags = const [];

  Heartbeats({
    required Requests requests,
    required CustomLogger logger,
    required Auth auth,
  }) : this.withDebounce(
         requests: requests,
         logger: logger,
         auth: auth,
         debounceDuration: defaultDebounceDuration,
       );

  @visibleForTesting
  Heartbeats.withDebounce({
    required super.requests,
    required super.logger,
    required Auth auth,
    Duration debounceDuration = defaultDebounceDuration,
  }) : _auth = auth,
       _debounceDuration = debounceDuration,
       super(kind: ReceivedHeartbeat.kinds[0]);

  Future<ReceivedHeartbeat> requestUpsertCurrent({
    int? createdAt,
    List<List<String>> extraTags = const [],
  }) => logger.span('requestUpsertCurrent', () {
    _pendingCreatedAt = createdAt;
    _pendingExtraTags = extraTags;

    final completer = _pendingUpsertCompleter ??=
        Completer<ReceivedHeartbeat>();

    _pendingUpsertTimer?.cancel();
    _pendingUpsertTimer = Timer(_debounceDuration, () async {
      final pendingCompleter = _pendingUpsertCompleter;
      final pendingCreatedAt = _pendingCreatedAt;
      final pendingExtraTags = _pendingExtraTags;

      _pendingUpsertTimer = null;
      _pendingUpsertCompleter = null;
      _pendingCreatedAt = null;
      _pendingExtraTags = const [];

      try {
        final heartbeat = await upsertCurrent(
          createdAt: pendingCreatedAt,
          extraTags: pendingExtraTags,
        );
        pendingCompleter?.complete(heartbeat);
      } catch (e, st) {
        pendingCompleter?.completeError(e, st);
      }
    });

    return completer.future;
  });

  Future<ReceivedHeartbeat> upsertCurrent({
    int? createdAt,
    List<List<String>> extraTags = const [],
  }) => logger.span('upsertCurrent', () async {
    final keyPair = _auth.activeKeyPair;
    if (keyPair == null) {
      throw StateError('No active key pair');
    }

    final unsignedHeartbeat = ReceivedHeartbeat.create(
      pubKey: keyPair.publicKey,
      createdAt: createdAt,
      extraTags: extraTags,
    );
    final heartbeat = requests.ndk.accounts.getPublicKey() == keyPair.publicKey
        ? ReceivedHeartbeat.fromNostrEvent(
            await requests.ndk.accounts.sign(unsignedHeartbeat),
          )
        : unsignedHeartbeat.signAs(keyPair, ReceivedHeartbeat.fromNostrEvent);

    await upsert(heartbeat);
    return heartbeat;
  });

  Future<ReceivedHeartbeat?> latestForUser(String pubkey) =>
      logger.span('latestForUser', () async {
        return getOne(Filter(authors: [pubkey], limit: 1));
      });

  Future<Map<String, ReceivedHeartbeat>> latestForUsers(
    Iterable<String> pubkeys,
  ) => logger.span('latestForUsers', () async {
    final authors = _normalizePubkeys(pubkeys);
    final events = await list(Filter(authors: authors), name: 'latestForUsers');
    return _latestByPubkey(events);
  });

  StreamWithStatus<ReceivedHeartbeat> subscribeUsers(
    Iterable<String> pubkeys, {
    String? name,
  }) => logger.spanSync('subscribeUsers', () {
    return subscribe(
      Filter(authors: _normalizePubkeys(pubkeys)),
      name: name ?? 'subscribeUsers',
    );
  });

  StreamWithStatus<ReceivedHeartbeat> queryUsers(
    Iterable<String> pubkeys, {
    String? name,
  }) => logger.spanSync('queryUsers', () {
    return query(
      Filter(authors: _normalizePubkeys(pubkeys)),
      name: name ?? 'queryUsers',
    );
  });

  List<String> _normalizePubkeys(Iterable<String> pubkeys) {
    final authors =
        pubkeys
            .map((pubkey) => pubkey.trim())
            .where((pubkey) => pubkey.isNotEmpty)
            .toSet()
            .toList()
          ..sort();

    if (authors.isEmpty) {
      throw ArgumentError.value(
        pubkeys,
        'pubkeys',
        'At least one pubkey is required',
      );
    }

    return authors;
  }

  Map<String, ReceivedHeartbeat> _latestByPubkey(
    Iterable<ReceivedHeartbeat> events,
  ) {
    final latest = <String, ReceivedHeartbeat>{};
    for (final event in events) {
      final current = latest[event.pubKey];
      if (current == null || event.createdAt >= current.createdAt) {
        latest[event.pubKey] = event;
      }
    }
    return latest;
  }
}
