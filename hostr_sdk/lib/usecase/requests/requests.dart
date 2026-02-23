import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:hostr_sdk/injection.dart';
import 'package:hostr_sdk/util/main.dart';
import 'package:injectable/injectable.dart';
import 'package:models/nostr_parser.dart';
import 'package:ndk/entities.dart' show RelayBroadcastResponse;
import 'package:ndk/ndk.dart' show Filter, LogOutput, Logger, Ndk, Nip01Event;
import 'package:ndk/shared/logger/log_event.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import 'package:rxdart/rxdart.dart';

abstract class RequestsModel {
  Stream<T> query<T extends Nip01Event>({
    required Filter filter,
    Duration? timeout,
    List<String>? relays,
    String? name,
  });
  StreamWithStatus<T> subscribe<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
    String? name,
  });
  Future<int> count({
    required Filter filter,
    Duration? timeout,
    List<String>? relays,
  });

  Future<List<RelayBroadcastResponse>> broadcast({
    required Nip01Event event,
    List<String>? relays,
  });

  Future<void> mock();
}

@Singleton(env: Env.allButTestAndMock)
class Requests extends RequestsModel {
  final Ndk ndk;
  final bool useCache = false;

  /// In-flight query dedup: filter key → broadcast stream.
  /// If a query with the same filter is already running, new callers
  /// share its broadcast stream instead of opening another relay subscription.
  final Map<String, Stream<Nip01Event>> _inFlightQueries = {};

  Requests({required this.ndk}) {
    Logger.log.addOutput(_SubscriptionDebugOutput(ndk));
  }

  // NDK does not let us subscribe to fetch old events, complete, and keep streaming, so we have to implement our own version
  @override
  StreamWithStatus<T> subscribe<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
    String? name,
  }) {
    final ndkSubName = name != null
        ? "$name-${Helpers.getRandomString(5)}"
        : "sub-${Helpers.getRandomString(10)}";
    if (name == null) {
      throw ArgumentError(
        'Name is required for subscribe to ensure proper cleanup of subscriptions. Please provide a name like "MyEntity-sub"',
      );
    }
    final response = StreamWithStatus<T>(
      onClose: () async {
        await ndk.requests.closeSubscription(ndkSubName);
      },
    );

    response.addStatus(StreamStatusQuerying());

    // @todo: should i be using queryFn, liveFn, which automatically cancels subscriptions, rather than adding the subscription manually here.
    final subscription = ndk.requests
        .query(
          name: name != null ? '$name-q' : 'q-${Helpers.getRandomString(5)}',
          filter: cleanTags(filter),
          cacheRead: true,
          cacheWrite: true,
        )
        .stream
        .doOnDone(() => response.addStatus(StreamStatusQueryComplete()))
        .concatWith([
          Rx.defer(() {
            final liveFilter = filter.clone();
            final maxCreatedAt = response.list.value.isEmpty
                ? null
                : response.list.value.map((e) => e.createdAt).reduce(max);
            final nextSince = maxCreatedAt == null ? null : maxCreatedAt + 1;
            liveFilter.since = maxCreatedAt == null
                ? liveFilter.since
                : (liveFilter.since == null || nextSince! > liveFilter.since!
                      ? nextSince
                      : liveFilter.since);
            response.addStatus(StreamStatusLive());

            return ndk.requests
                .subscription(
                  id: ndkSubName,
                  filter: cleanTags(liveFilter),
                  cacheRead: useCache,
                  cacheWrite: true,
                )
                .stream;
          }),
        ])
        .asyncMap((event) async => safeParserWithGiftWrap<T>(event, ndk))
        .where((event) => event != null)
        .cast<T>()
        .listen(response.add, onError: response.addError);
    response.addSubscription(subscription);

    return response;
  }

  /// Canonical key for a filter, used to dedup identical in-flight queries.
  String _filterKey(Filter filter) {
    return jsonEncode(cleanTags(filter)?.toMap() ?? filter.toMap());
  }

  @override
  Stream<T> query<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
    Duration? timeout,
    String? name,
  }) {
    final key = _filterKey(filter);

    // If there's already an in-flight query for this exact filter, share it.
    if (_inFlightQueries.containsKey(key)) {
      return _inFlightQueries[key]!
          .asyncMap((event) async => safeParserWithGiftWrap<T>(event, ndk))
          .where((event) => event != null)
          .cast<T>();
    }

    // Create the underlying stream and make it a broadcast so multiple
    // callers can listen. Clean up the map entry when the source completes
    // (doOnDone) OR when all listeners cancel before completion (onCancel).
    // Without the onCancel cleanup, consumers like .firstWhere() that cancel
    // after the first event leave a stale entry — subsequent queries with
    // the same filter hit the dead broadcast stream and hang forever.
    final source = ndk.requests
        .query(
          name: name ?? "query-${Helpers.getRandomString(5)}",
          filter: cleanTags(filter),
          cacheRead: false,
          cacheWrite: false,
          timeout: timeout,
        )
        .stream
        .doOnDone(() => _inFlightQueries.remove(key))
        .asBroadcastStream(
          onCancel: (subscription) {
            subscription.cancel();
            _inFlightQueries.remove(key);
          },
        );

    _inFlightQueries[key] = source;

    return source
        .asyncMap((event) async => safeParserWithGiftWrap<T>(event, ndk))
        .where((event) => event != null)
        .cast<T>();
  }

  // @TODO: There must be a better way to do this
  @override
  Future<int> count({
    required Filter filter,
    Duration? timeout,
    List<String>? relays,
  }) async {
    var results = await query(
      filter: filter,
      timeout: timeout,
      relays: relays,
    ).toList();
    return results.length;
  }

  @override
  Future<List<RelayBroadcastResponse>> broadcast({
    required Nip01Event event,
    List<String>? relays,
  }) {
    return ndk.broadcast.broadcast(nostrEvent: event).broadcastDoneFuture;
  }

  @override
  Future<void> mock() {
    // TODO: implement mock
    throw UnimplementedError();
  }
}

/// Monitors NDK log output for relay subscription-limit NOTICE messages.
/// When the relay reports "Maximum concurrent subscription count reached",
/// dumps all currently in-flight requests/subscriptions with full detail
/// so the developer can identify leaks.
class _SubscriptionDebugOutput extends LogOutput {
  final Ndk _ndk;
  _SubscriptionDebugOutput(this._ndk);

  @override
  void output(LogEvent event) {
    if (event.message.contains('Subscription error') ||
        event.message.contains('concurrent subscription')) {
      _dumpAllSubscriptions();
    }
  }

  // Print line-by-line to avoid Flutter's ~1024-char print() truncation.
  void _p(String line) {
    // ignore: avoid_print
    print(line);
  }

  void _dumpAllSubscriptions() {
    final inFlight = _ndk.relays.globalState.inFlightRequests;

    final subscriptions = inFlight.values
        .where((s) => !s.request.closeOnEOSE)
        .toList();
    final queries = inFlight.values
        .where((s) => s.request.closeOnEOSE)
        .toList();

    _p('');
    _p('╔══════════════════════════════════════════════════════════════');
    _p('║  SUBSCRIPTION LIMIT HIT — ${inFlight.length} in-flight requests');
    _p('╠══════════════════════════════════════════════════════════════');
    _p(
      '║  Subscriptions (live): ${subscriptions.length}  |  Queries (one-shot): ${queries.length}',
    );

    // ── Live subscriptions (printed first — these are the persistent ones) ──
    if (subscriptions.isNotEmpty) {
      _p('╠══════════════════════════════════════════════════════════════');
      _p('║  LIVE SUBSCRIPTIONS');
      _p('╠══════════════════════════════════════════════════════════════');
      for (final state in subscriptions) {
        _printRequestState(state, 'SUB');
      }
    }

    // ── One-shot queries (grouped by name to spot duplicates) ──
    if (queries.isNotEmpty) {
      _p('╠══════════════════════════════════════════════════════════════');
      _p('║  QUERIES (one-shot)');
      _p('╠══════════════════════════════════════════════════════════════');

      // Group by name for a summary line first
      final nameGroups = <String, int>{};
      for (final q in queries) {
        final name = q.request.name ?? 'unnamed';
        nameGroups[name] = (nameGroups[name] ?? 0) + 1;
      }
      for (final entry in nameGroups.entries) {
        _p('║    ${entry.key}: ${entry.value}x');
      }
      _p('║  ──────────────────────────────────────────────────────────');

      for (final state in queries) {
        _printRequestState(state, 'QUERY');
      }
    }

    _p('║');
    _p('╚══════════════════════════════════════════════════════════════');
  }

  void _printRequestState(dynamic state, String type) {
    final req = state.request;
    _p('║');
    _p('║  [$type] ${req.name ?? "unnamed"}');
    _p('║    id: ${state.id}');

    for (var i = 0; i < req.filters.length; i++) {
      final f = req.filters[i];
      final parts = <String>[];
      if (f.kinds != null) parts.add('kinds=${f.kinds}');
      if (f.authors != null) parts.add('authors=${_truncate(f.authors)}');
      if (f.ids != null) parts.add('ids=${_truncate(f.ids)}');
      if (f.since != null) parts.add('since=${f.since}');
      if (f.until != null) parts.add('until=${f.until}');
      if (f.limit != null) parts.add('limit=${f.limit}');
      if (f.tags != null) {
        for (final tag in f.tags!.entries) {
          parts.add('#${tag.key}=${_truncate(tag.value)}');
        }
      }
      _p('║    filter[$i]: ${parts.isEmpty ? "(empty)" : parts.join(", ")}');
    }

    if (state.requests.isNotEmpty) {
      for (final e in state.requests.entries) {
        final flags = <String>[];
        if (e.value.receivedEOSE) flags.add('EOSE');
        if (e.value.receivedClosed) flags.add('CLOSED');
        final suffix = flags.isEmpty ? '' : ' (${flags.join(",")})';
        _p('║    relay: ${e.key}$suffix');
      }
    }
  }

  String _truncate(List<String>? list) {
    if (list == null) return 'null';
    if (list.length <= 3) return list.toString();
    return '[${list.take(3).join(", ")}, ...(${list.length} total)]';
  }
}
