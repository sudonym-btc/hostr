import 'dart:async';

import 'package:models/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart'
    show RelayBroadcastResponse;
import 'package:ndk/ndk.dart' show Nip01Event, Filter;

import '../util/main.dart';
import 'requests/requests.dart';

class CrudUseCase<T extends Nip01Event> {
  final CustomLogger logger;
  final Requests requests;
  final int kind;
  final int? draftKind;

  /// Broadcast stream that emits whenever an entity is created, updated,
  /// or deleted through this use case. Consumers can listen to this to
  /// refresh their UI when mutations happen elsewhere.
  final StreamController<T> _updates = StreamController<T>.broadcast();
  Stream<T> get updates => _updates.stream;

  CrudUseCase({
    required this.requests,
    required this.kind,
    this.draftKind,
    required this.logger,
  });

  /// Notify listeners that an entity was mutated. Call this from external
  /// code (e.g. controllers that bypass [create]/[update]/[delete]) to
  /// trigger refresh in consuming widgets.
  void notifyUpdate(T event) => _updates.add(event);

  StreamWithStatus<T> subscribe(Filter f, {String? name}) {
    return requests.subscribe(
      filter: getCombinedFilter(f, Filter(kinds: [kind])),
      name: name != null ? '$T-$name' : '$T',
    );
  }

  Future<List<RelayBroadcastResponse>> create(T event) {
    return requests.broadcast(event: event).then((r) {
      _updates.add(event);
      return r;
    });
  }

  Future<List<RelayBroadcastResponse>> update(T event) {
    return requests.broadcast(event: event).then((r) {
      _updates.add(event);
      return r;
    });
  }

  Future<List<RelayBroadcastResponse>> delete(T event) {
    return requests.broadcast(event: event).then((r) {
      _updates.add(event);
      return r;
    });
  }

  Future<List<T>> list(Filter f, {String? name}) {
    return requests
        .query<T>(
          filter: getCombinedFilter(f, Filter(kinds: [kind])),
          name: '$T-list${name != null ? '-$name' : ''}',
        )
        .toList();
  }

  Future<T?> getOne(Filter f) async {
    await for (final event in requests.query<T>(
      filter: getCombinedFilter(f, Filter(kinds: [kind], limit: 1)),
      name: '$T-getOne',
    )) {
      return event;
    }
    return null;
  }

  // @TODO: Can't just be d tag as multiple pubkeys might have same. Pass A tag and get pubkey + dTag to filter correctly
  Future<T?> getOneByAnchor(String anchor) {
    return getOne(
      Filter(
        authors: [getPubKeyFromAnchor(anchor)],
        dTags: [getDTagFromAnchor(anchor)],
      ),
    );
  }

  Future<T> getById(String id) {
    return requests
        .query<T>(
          filter: Filter(kinds: [kind], ids: [id], limit: 1),
          name: '$T-getById',
        )
        .first;
  }

  Future<int> count() {
    return requests.count(filter: Filter(kinds: [kind]));
  }
}
