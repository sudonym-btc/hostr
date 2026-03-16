import 'package:injectable/injectable.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart' show Filter;

import '../../util/main.dart';
import '../auth/auth.dart';
import '../crud.usecase.dart';

@Singleton()
class Heartbeats extends CrudUseCase<ReceivedHeartbeat> {
  final Auth _auth;

  Heartbeats({
    required super.requests,
    required super.logger,
    required Auth auth,
  }) : _auth = auth,
       super(kind: ReceivedHeartbeat.kinds[0]);

  Future<ReceivedHeartbeat> upsertCurrent({
    int? createdAt,
    List<List<String>> extraTags = const [],
  }) => logger.span('upsertCurrent', () async {
    final keyPair = _auth.activeKeyPair;
    if (keyPair == null) {
      throw StateError('No active key pair');
    }

    final heartbeat = ReceivedHeartbeat.create(
      pubKey: keyPair.publicKey,
      createdAt: createdAt,
      extraTags: extraTags,
    );

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
