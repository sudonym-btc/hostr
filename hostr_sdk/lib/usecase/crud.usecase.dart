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
  /// code (e.g. controllers that bypass [create]/[upsert]/[delete]) to
  /// trigger refresh in consuming widgets.
  void notifyUpdate(T event) => _updates.add(event);

  StreamWithStatus<T> subscribe(Filter f, {String? name}) {
    return requests.subscribe(
      filter: getCombinedFilter(f, Filter(kinds: [kind])),
      name: name != null ? '$T-$name' : '$T',
    );
  }

  Future<List<RelayBroadcastResponse>> upsert(T event) {
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
  // Collects individual getOne calls, debounces for an adaptive duration,
  // then fires a single combined query. Each requester's Completer is
  // resolved by matching the returned events against the original filter.
  //
  // Adaptive debounce: starts at 50ms for snappy UI response, extends to
  // 500ms when under high load (>5 pending requests) to maximize batching.
  static const Duration _getOneDebounceMin = Duration(milliseconds: 50);
  static const Duration _getOneDebounceMax = Duration(milliseconds: 500);
  static const int _getOneHighLoadThreshold = 5;
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

    // Adaptive debounce: use short delay when few pending requests (snappy UI),
    // extend when many requests are queued (maximize batching).
    final debounce = _getOneQueue.length > _getOneHighLoadThreshold
        ? _getOneDebounceMax
        : _getOneDebounceMin;

    // Reset the debounce timer on every new request.
    _getOneTimer?.cancel();
    _getOneTimer = Timer(debounce, _flushGetOneQueue);

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

  // ── findByTag batching ──────────────────────────────────────────────
  // Like getOne batching but for multi-result tag queries. Each caller
  // asks for all events matching tag=value; within the debounce window
  // all values are merged into one query:
  //   Filter(kinds: [kind], tags: {tag: [v1, v2, ..., vN]})
  // Results are dispatched back by matching each event's tag value.
  //
  // Uses the same adaptive debounce strategy as getOne.
  static const Duration _findByTagDebounceMin = Duration(milliseconds: 50);
  static const Duration _findByTagDebounceMax = Duration(milliseconds: 500);
  static const int _findByTagHighLoadThreshold = 5;
  final Map<String, List<_FindByTagRequest<T>>> _findByTagQueues = {};
  final Map<String, Timer?> _findByTagTimers = {};

  /// Find all events matching [tag]=[value]. Calls within the debounce
  /// window are batched into a single Nostr query. Returns the list of
  /// events whose [tag] contains [value].
  Future<List<T>> findByTag(String tag, String value) {
    final completer = Completer<List<T>>();
    _findByTagQueues
        .putIfAbsent(tag, () => [])
        .add(_FindByTagRequest(value: value, completer: completer));

    // Adaptive debounce: short delay for few requests, longer for many.
    final queueLen = _findByTagQueues[tag]?.length ?? 0;
    final debounce = queueLen > _findByTagHighLoadThreshold
        ? _findByTagDebounceMax
        : _findByTagDebounceMin;

    _findByTagTimers[tag]?.cancel();
    _findByTagTimers[tag] = Timer(debounce, () => _flushFindByTagQueue(tag));

    return completer.future;
  }

  void _flushFindByTagQueue(String tag) {
    final queue = _findByTagQueues.remove(tag);
    _findByTagTimers.remove(tag);
    if (queue == null || queue.isEmpty) return;

    final batch = List<_FindByTagRequest<T>>.from(queue);

    // Merge all requested values into one filter.
    final allValues = batch.map((r) => r.value).toSet().toList();

    logger.d(
      'findByTag batch: ${batch.length} requests for tag "$tag" '
      'combined into 1 query for $T with ${allValues.length} distinct values',
    );

    // Accumulate results per value.
    final results = <String, List<T>>{};

    requests
        .query<T>(
          filter: Filter(kinds: [kind], tags: {tag: allValues}),
          name: '$T-findByTag-batch',
        )
        .listen(
          (event) {
            // Match event against each requested value.
            for (final value in allValues) {
              final matches = event.tags.any(
                (t) => t.isNotEmpty && t[0] == tag && t.contains(value),
              );
              if (matches) {
                results.putIfAbsent(value, () => []).add(event);
              }
            }
          },
          onDone: () {
            for (final req in batch) {
              if (!req.completer.isCompleted) {
                req.completer.complete(results[req.value] ?? []);
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
}

/// A pending getOne request waiting to be batched.
class _GetOneRequest<T> {
  final Filter filter;
  final Completer<T?> completer;
  _GetOneRequest({required this.filter, required this.completer});
}

/// A pending findByTag request waiting to be batched.
class _FindByTagRequest<T> {
  final String value;
  final Completer<List<T>> completer;
  _FindByTagRequest({required this.value, required this.completer});
}
