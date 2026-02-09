import 'package:ndk/domain_layer/entities/broadcast_state.dart'
    show RelayBroadcastResponse;
import 'package:ndk/ndk.dart' show Nip01Event, Filter;

import '../util/main.dart';
import 'requests/requests.dart';

class CrudUseCase<T extends Nip01Event> {
  final CustomLogger logger = CustomLogger();
  final Requests requests;
  final int kind;
  final int? draftKind;

  CrudUseCase({required this.requests, required this.kind, this.draftKind});

  Future<List<RelayBroadcastResponse>> create(T event) {
    return requests.broadcast(event: event);
  }

  Future<List<RelayBroadcastResponse>> update(T event) {
    return requests.broadcast(event: event);
  }

  Future<List<RelayBroadcastResponse>> delete(T event) {
    return requests.broadcast(event: event);
  }

  Future<List<T>> list(Filter f) {
    return requests
        .query<T>(filter: getCombinedFilter(f, Filter(kinds: [kind])))
        .toList();
  }

  Future<T?> getOne(Filter f) {
    return requests
        .query<T>(filter: getCombinedFilter(f, Filter(kinds: [kind], limit: 1)))
        .first;
  }

  Future<T> getById(String id) {
    return requests
        .query<T>(
          filter: Filter(kinds: [kind], ids: [id], limit: 1),
        )
        .first;
  }

  Future<int> count() {
    return requests.count(filter: Filter(kinds: [kind]));
  }
}
