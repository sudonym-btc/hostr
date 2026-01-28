import 'package:hostr/data/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart'
    show RelayBroadcastResponse;
import 'package:ndk/ndk.dart' show Nip01Event, Filter;

import 'requests/requests.dart';

class CrudUseCase<T extends Nip01Event> {
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
    return requests.startRequestAsync<T>(filter: f);
  }

  Future<T> getOne(Filter f) {
    return requests
        .startRequest<T>(filter: getCombinedFilter(f, Filter(limit: 1)))
        .first;
  }

  Future<T> getByAnchor() {
    return requests.startRequest<T>(filter: Filter()).first;
  }

  Future<T> getById() {
    return requests.startRequest<T>(filter: Filter()).first;
  }

  Future<int> count() {
    return requests.count(filter: Filter(kinds: [kind]));
  }
}
