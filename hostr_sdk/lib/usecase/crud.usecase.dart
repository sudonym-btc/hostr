import 'dart:async';

import 'package:hostr_sdk/datasources/nostr/mock.relay.dart' show matchEvent;
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

  // ── getOne batching ───────────────────────────────────────────────────
  // Collects individual getOne calls, debounces for [_getOneDebounceDuration],
  // then fires a single combined query. Each requester's Completer is
  // resolved by matching the returned events against the original filter.
  static const Duration _getOneDebounceDuration = Duration(milliseconds: 500);
  final List<_GetOneRequest<T>> _getOneQueue = [];
  Timer? _getOneTimer;

  Future<T?> getOne(Filter f, {bool batch = true}) {
    if (!batch) {
      return requests
          .query<T>(
            filter: getCombinedFilter(f, Filter(kinds: [kind], limit: 1)),
            name: '$T-getOne',
          )
          .cast<T?>()
          .firstWhere((_) => true, orElse: () => null);
    }

    final completer = Completer<T?>();
    _getOneQueue.add(_GetOneRequest(filter: f, completer: completer));

    // Reset the debounce timer on every new request.
    _getOneTimer?.cancel();
    _getOneTimer = Timer(_getOneDebounceDuration, _flushGetOneQueue);

    return completer.future;
  }

  void _flushGetOneQueue() {
    if (_getOneQueue.isEmpty) return;

    final batch = List<_GetOneRequest<T>>.from(_getOneQueue);
    _getOneQueue.clear();
    _getOneTimer = null;

    // Build a combined filter by merging all individual filters.
    var combinedFilter = Filter(kinds: [kind]);
    for (final req in batch) {
      combinedFilter = getCombinedFilter(req.filter, combinedFilter);
    }

    logger.d(
      'getOne batch: ${batch.length} requests combined into 1 query '
      'for $T with filter: ${combinedFilter.toJson()}',
    );

    requests
        .query<T>(filter: combinedFilter, name: '$T-getOne-batch')
        .listen(
          (event) {
            for (final req in batch) {
              if (req.completer.isCompleted) continue;
              final matchFilter = getCombinedFilter(
                req.filter,
                Filter(kinds: [kind]),
              );
              if (matchEvent(event, matchFilter)) {
                req.completer.complete(event);
              }
            }
          },
          onDone: () {
            final unmatchedReqs = batch
                .where((r) => !r.completer.isCompleted)
                .toList();
            if (unmatchedReqs.isNotEmpty) {
              logger.d(
                'getOne batch: ${unmatchedReqs.length} unmatched requests, '
                'firing individual queries for each',
              );
              // NDK's JIT engine may strip authors it already cached from
              // the relay filter, causing some requesters to never see
              // their event. Fall back to individual queries for those.
              for (final req in unmatchedReqs) {
                getOne(req.filter, batch: false).then(
                  (result) => req.completer.complete(result),
                  onError: (Object e) => req.completer.completeError(e),
                );
              }
            }
          },
          onError: (Object error) {
            for (final req in batch) {
              if (!req.completer.isCompleted) {
                req.completer.completeError(error);
              }
            }
          },
        );
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

/// A pending getOne request waiting to be batched.
class _GetOneRequest<T> {
  final Filter filter;
  final Completer<T?> completer;
  _GetOneRequest({required this.filter, required this.completer});
}
