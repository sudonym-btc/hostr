import 'dart:async';
import 'dart:math';

import 'package:ndk/ndk.dart' show Filter, Nip01Event;

import '../../util/main.dart';
import 'requests.dart';

/// A long-lived [StreamWithStatus] whose underlying Nostr filter is driven
/// by a [StreamWithStatus]<[Filter]> input.
///
/// ## Design
///
/// The filter source carries both **data** (accumulated filters as trade IDs
/// are discovered) and **status** (whether the discovery process is complete).
/// This subscription's own liveness is the AND of two conditions:
///
/// 1. **Filter source is live** — all trade IDs that exist have been discovered.
/// 2. **Relay catch-up is done** — historical events for all known trade IDs
///    have been fetched and the live relay subscription is open.
///
/// ## Lifecycle
///
/// 1. Call the constructor with a [filterSource]. The subscription immediately
///    begins listening to filter emissions.
///
/// 2. Each filter emission is the **full accumulated filter** (superset of
///    all previous ones). The subscription internally diffs against its
///    current filter to derive a delta query.
///
/// 3. Rapid filter emissions are debounced into a single delta-query +
///    re-subscribe cycle.
///
/// 4. [StreamStatusLive] is emitted only when both conditions above are met.
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
  Filter? _currentFilter;

  /// Handle to the live NDK subscription — swapped on each expansion.
  LiveSubscriptionHandle? _liveHandle;

  /// In-flight delta query subscription (cancelled on close / new expansion).
  StreamSubscription<T>? _deltaQuerySub;

  /// Subscriptions to the filter source.
  StreamSubscription<Filter>? _filterDataSub;
  StreamSubscription<StreamStatus>? _filterStatusSub;

  /// Debounce machinery for filter emissions.
  final Duration _debounceDuration;
  Timer? _debounceTimer;
  Filter? _pendingFilter;

  /// True after at least one relay query + live subscription cycle has
  /// completed (i.e. we've fetched historical data for the current filter).
  bool _relayCaughtUp = false;

  /// True once the filter source has emitted [StreamStatusLive].
  bool _filterSourceLive = false;

  /// True after [close] has been called.
  bool _closed = false;

  ExpandableSubscription({
    required Requests requests,
    required CustomLogger logger,
    required String name,
    required StreamWithStatus<Filter> filterSource,
    Duration debounceDuration = const Duration(milliseconds: 500),
  }) : _requests = requests,
       _logger = logger,
       _name = name,
       _debounceDuration = debounceDuration {
    _subscribeToFilterSource(filterSource);
  }

  // ── Public API ──────────────────────────────────────────────────────

  /// Tear down everything. [stream] is closed and cannot be reused.
  Future<void> close() => _logger.span('close', () async {
    if (_closed) return;
    _closed = true;
    _debounceTimer?.cancel();
    await _filterDataSub?.cancel();
    await _filterStatusSub?.cancel();
    await _deltaQuerySub?.cancel();
    await _liveHandle?.cancel();
    await stream.close();
    _seenIds.clear();
    _logger.d('ExpandableSubscription[$_name] closed');
  });

  /// Soft teardown for logout. Cancels subscriptions and clears state
  /// but keeps the [stream] object alive so listeners stay attached.
  Future<void> reset() => _logger.span('reset', () async {
    _debounceTimer?.cancel();
    _pendingFilter = null;
    await _filterDataSub?.cancel();
    _filterDataSub = null;
    await _filterStatusSub?.cancel();
    _filterStatusSub = null;
    await _deltaQuerySub?.cancel();
    _deltaQuerySub = null;
    await _liveHandle?.cancel();
    _liveHandle = null;
    _seenIds.clear();
    _currentFilter = null;
    _relayCaughtUp = false;
    _filterSourceLive = false;
    _closed = false;
    await stream.reset();
    _logger.d('ExpandableSubscription[$_name] reset');
  });

  // ── Filter source wiring ────────────────────────────────────────────

  void _subscribeToFilterSource(StreamWithStatus<Filter> filterSource) {
    stream.addStatus(StreamStatusQuerying());

    // Listen to filter data: each emission is the full accumulated filter.
    _filterDataSub = filterSource.replay.listen(
      _onFilterEmission,
      onError: stream.addError,
    );

    // Listen to filter status: track when source goes live.
    _filterStatusSub = filterSource.status.listen((status) {
      if (status is StreamStatusLive && !_filterSourceLive) {
        _filterSourceLive = true;
        _logger.d(
          'ExpandableSubscription[$_name] filter source is live',
        );
        _maybeEmitLive();
      }
    });
  }

  void _onFilterEmission(Filter incomingFilter) {
    if (_closed) return;

    // Debounce rapid emissions into a single query cycle.
    _pendingFilter = incomingFilter;
    _debounceTimer?.cancel();
    _debounceTimer = Timer(_debounceDuration, _flushPendingFilter);
  }

  // ── Internals ───────────────────────────────────────────────────────

  void _flushPendingFilter() {
    final fullFilter = _pendingFilter;
    _pendingFilter = null;

    if (fullFilter == null || _closed) return;

    if (_currentFilter == null) {
      // First filter — run a full initial query.
      _logger.d('ExpandableSubscription[$_name] initial filter received');
      _currentFilter = fullFilter;
      _relayCaughtUp = false;

      _runQuery(
        filter: fullFilter,
        queryName: '$_name-initial-q',
        onComplete: () {
          _relayCaughtUp = true;
          stream.addStatus(StreamStatusQueryComplete());
          _openLiveSubscription(fullFilter);
          _maybeEmitLive();
        },
      );
    } else {
      // Subsequent filter — run delta query then re-open live sub.
      _logger.d('ExpandableSubscription[$_name] expanding filter');
      _relayCaughtUp = false;

      // Cancel any in-flight delta query from a previous expansion.
      _deltaQuerySub?.cancel();

      _runQuery(
        filter: fullFilter,
        queryName: '$_name-delta-q',
        onComplete: () {
          _relayCaughtUp = true;
          _closeLiveAndReopen(fullFilter);
          _maybeEmitLive();
        },
      );
    }
  }

  /// Emits [StreamStatusLive] when both conditions are met:
  /// 1. Filter source has reported Live (all trade IDs discovered).
  /// 2. Relay has caught up (historical query done + live sub open).
  void _maybeEmitLive() {
    if (_closed) return;
    if (!_filterSourceLive || !_relayCaughtUp) return;
    if (stream.status.value is StreamStatusLive) return;

    _logger.d('ExpandableSubscription[$_name] → StreamStatusLive');
    stream.addStatus(StreamStatusLive());
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
}
