import 'package:hostr/data/main.dart';
import 'package:ndk/domain_layer/entities/broadcast_state.dart'
    show RelayBroadcastResponse;
import 'package:ndk/ndk.dart' show Nip01Event, Filter;

import 'requests/requests.dart';

class CrudUseCase<T extends Nip01Event> {
  final Requests _requests;
  final int kind;
  final int? draftKind;

  CrudUseCase({required Requests requests, required this.kind, this.draftKind})
    : _requests = requests;

  Future<List<RelayBroadcastResponse>> create(T event) {
    return _requests.broadcast(event: event);
  }

  Future<List<RelayBroadcastResponse>> update(T event) {
    return _requests.broadcast(event: event);
  }

  Future<List<RelayBroadcastResponse>> delete(T event) {
    return _requests.broadcast(event: event);
  }

  Future<List<T>> list(Filter f) {
    return _requests.startRequestAsync<T>(filter: f);
  }

  Future<T> getOne(Filter f) {
    return _requests
        .startRequest<T>(filter: getCombinedFilter(f, Filter(limit: 1)))
        .first;
  }

  Future<T> getByAnchor() {
    return _requests.startRequest<T>(filter: Filter()).first;
  }

  Future<T> getById() {
    return _requests.startRequest<T>(filter: Filter()).first;
  }

  Future<int> count() {
    return _requests.count(filter: Filter(kinds: [kind]));
  }
}
