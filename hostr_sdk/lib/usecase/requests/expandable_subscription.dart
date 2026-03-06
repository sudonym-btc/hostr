import 'dart:async';
import 'dart:math';

import 'package:ndk/ndk.dart' show Filter, Nip01Event;

import '../../util/main.dart';
import 'requests.dart';

/// A long-lived [StreamWithStatus] whose underlying Nostr filter can be
/// expanded at any time without tearing down the public-facing stream.
///
/// ## Lifecycle
///
/// 1. **Initial subscribe** — runs a query for historical events, then opens a
///    live relay subscription. Status goes `Querying → QueryComplete → Live`.
///
/// 2. **Filter expansion** ([updateFilter]) — when new listing anchors, trade
///    IDs, etc. are discovered:
///    - A **delta query** fetches history only for the *new* filter values.
///    - On query completion the old live subscription is closed and a new one
///      is opened with the **full expanded filter** (+ `since` from the most
///      recent event).
///    - The output [stream] never closes or flickers — it stays `Live`.
///
/// 3. **Debounce** — rapid discoveries (e.g. during initial sync) are batched
///    into a single delta query + re-subscribe cycle.
///
/// At most **2** NDK connections are open at any time: the long-lived
/// subscription plus one in-flight delta query.
class ExpandableSubscription<T extends Nip01Event> {
  final Requests _requests;
  final CustomLogger _logger;
  final String _name;

  /// The user-facing output. Created once, lives until [close].
  final StreamWithStatus<T> stream = StreamWithStatus<T>();

  /// Dedup: event IDs already piped into [stream].
  final Set<String> _seenIds = {};

  /// The filter currently covered by the live subscription.
  Filter _currentFilter;

  /// Handle to the live NDK subscription — swapped on each expansion.
  LiveSubscriptionHandle? _liveHandle;

  /// In-flight delta query subscription (cancelled on close / new expansion).
  StreamSubscription<T>? _deltaQuerySub;

  /// Debounce machinery for [updateFilter].
  final Duration _debounceDuration;
  Timer? _debounceTimer;
  Filter? _pendingFullFilter;
  Filter? _pendingDeltaFilter;

  /// True after the initial query phase has completed.
  bool _initialQueryDone = false;

  /// True after [close] has been called.
  bool _closed = false;

  ExpandableSubscription({
    required Requests requests,
    required CustomLogger logger,
    required String name,
    required Filter initialFilter,
    Duration debounceDuration = const Duration(milliseconds: 500),
  }) : _requests = requests,
       _logger = logger,
       _name = name,
       _currentFilter = initialFilter,
       _debounceDuration = debounceDuration;

  // ── Public API ──────────────────────────────────────────────────────

  /// Kick off the initial query → live subscription cycle.
  void start() {
    if (_closed) return;
    _logger.d('ExpandableSubscription[$_name] starting');
    stream.addStatus(StreamStatusQuerying());

    _runQuery(
      filter: _currentFilter,
      queryName: '$_name-initial-q',
      onComplete: () {
        _initialQueryDone = true;
        stream.addStatus(StreamStatusQueryComplete());
        _openLiveSubscription(_currentFilter);
      },
    );
  }

  /// Expand the subscription filter.
  ///
  /// [expandedFilter] is the **full** new filter (superset of current).
  /// [deltaFilter] covers *only* the newly-added values so the delta query
  /// doesn't re-fetch everything. If null, falls back to [expandedFilter]
  /// (safe but fetches duplicates that are deduped locally).
  void updateFilter({required Filter expandedFilter, Filter? deltaFilter}) {
    if (_closed) return;

    _pendingFullFilter = expandedFilter;
    _pendingDeltaFilter = _mergeDeltaFilters(
      _pendingDeltaFilter,
      deltaFilter ?? expandedFilter,
    );

    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, _flushPendingExpansion);
  }

  /// Tear down everything. [stream] is closed and cannot be reused.
  Future<void> close() async {
    if (_closed) return;
    _closed = true;
    _debounceTimer?.cancel();
    await _deltaQuerySub?.cancel();
    await _liveHandle?.cancel();
    await stream.close();
    _seenIds.clear();
    _logger.d('ExpandableSubscription[$_name] closed');
  }

  /// Soft teardown for logout. Cancels subscriptions and clears state
  /// but keeps the [stream] object alive so listeners stay attached.
  /// Call [start] again after re-login to resume.
  Future<void> reset() async {
    _debounceTimer?.cancel();
    _pendingFullFilter = null;
    _pendingDeltaFilter = null;
    await _deltaQuerySub?.cancel();
    _deltaQuerySub = null;
    await _liveHandle?.cancel();
    _liveHandle = null;
    _seenIds.clear();
    _initialQueryDone = false;
    _closed = false;
    await stream.reset();
    _logger.d('ExpandableSubscription[$_name] reset');
  }

  // ── Internals ───────────────────────────────────────────────────────

  void _flushPendingExpansion() {
    final fullFilter = _pendingFullFilter;
    final deltaFilter = _pendingDeltaFilter;
    _pendingFullFilter = null;
    _pendingDeltaFilter = null;

    if (fullFilter == null || _closed) return;

    _logger.d(
      'ExpandableSubscription[$_name] expanding filter '
      '(delta: ${deltaFilter != null})',
    );

    // Cancel any in-flight delta query from a previous expansion.
    _deltaQuerySub?.cancel();

    _runQuery(
      filter: deltaFilter ?? fullFilter,
      queryName: '$_name-delta-q',
      onComplete: () {
        // Swap the live subscription to the expanded filter.
        _closeLiveAndReopen(fullFilter);
      },
    );
  }

  /// Runs a one-shot query, pipes results into [stream] with dedup.
  void _runQuery({
    required Filter filter,
    required String queryName,
    required void Function() onComplete,
  }) {
    _deltaQuerySub?.cancel();
    _deltaQuerySub = _requests
        .query<T>(filter: filter, name: queryName)
        .listen(
          _dedupAdd,
          onError: stream.addError,
          onDone: () {
            _deltaQuerySub = null;
            if (!_closed) onComplete();
          },
        );
  }

  /// Closes the current live subscription and opens a new one with
  /// [expandedFilter]. Uses `since` from the most recent known event.
  void _closeLiveAndReopen(Filter expandedFilter) {
    _liveHandle?.cancel();
    _liveHandle = null;
    _currentFilter = expandedFilter;
    _openLiveSubscription(expandedFilter);
  }

  void _openLiveSubscription(Filter filter) {
    if (_closed) return;

    final liveFilter = filter.clone();

    // Set `since` to just after the newest event we've seen to avoid
    // re-fetching events already in the accumulator.
    if (stream.list.value.isNotEmpty) {
      final maxCreatedAt = stream.list.value
          .map((e) => e.createdAt)
          .reduce(max);
      final nextSince = maxCreatedAt + 1;
      liveFilter.since = liveFilter.since == null
          ? nextSince
          : (nextSince > liveFilter.since! ? nextSince : liveFilter.since);
    }

    if (!(_initialQueryDone && stream.status.value is! StreamStatusLive)) {
      // Only emit Live if we're past the initial query phase and not
      // already live (avoid re-emitting on expansion).
    }
    if (_initialQueryDone) {
      stream.addStatus(StreamStatusLive());
    }

    _liveHandle = _requests.liveSubscription<T>(
      filter: liveFilter,
      name: '$_name-live',
      onData: _dedupAdd,
      onError: stream.addError,
    );

    _logger.d(
      'ExpandableSubscription[$_name] live subscription opened: '
      '${_liveHandle!.ndkSubName}',
    );
  }

  void _dedupAdd(T event) {
    if (_seenIds.add(event.id)) {
      stream.add(event);
    }
  }

  /// Merges two delta filters by combining their tag values and other arrays.
  /// This ensures rapid successive [updateFilter] calls produce a single
  /// combined delta query.
  Filter? _mergeDeltaFilters(Filter? existing, Filter? incoming) {
    if (existing == null) return incoming;
    if (incoming == null) return existing;
    return getCombinedFilter(existing, incoming);
  }
}
