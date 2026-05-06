import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:injectable/injectable.dart';
import 'package:meta/meta.dart' show visibleForTesting;
import 'package:models/nostr_kinds.dart'
    show kHostrOnlyKinds, kNostrKindIdentityClaims;
import 'package:models/nostr_parser.dart';
import 'package:ndk/entities.dart' show RelayBroadcastResponse;
import 'package:ndk/ndk.dart'
    show
        Filter,
        LogOutput,
        Logger,
        Ndk,
        Nip01Event,
        Nip01EventModel,
        Nip01Utils;
import 'package:ndk/shared/logger/log_event.dart';
import 'package:ndk/shared/nips/nip01/helpers.dart';
import 'package:rxdart/rxdart.dart';

import '../../config.dart' show HostrConfig;
import '../../injection.dart';
import '../../util/main.dart';
import '../auth/auth.dart';

export 'expandable_subscription.dart';

typedef NostrEventSigner = Future<Nip01Event> Function(Nip01Event event);

class BroadcastResult {
  final Nip01Event event;
  final List<RelayBroadcastResponse> responses;

  const BroadcastResult({required this.event, required this.responses});
}

/// Pure relay-guard logic: returns the relay list that should actually be used
/// for broadcasting [eventKind]. Hostr-only kinds are forced onto
/// [hostrRelay]; standard kinds pass through unchanged.
///
/// Extracted so it can be unit-tested without wiring up NDK / DI.
@visibleForTesting
List<String>? applyBroadcastRelayGuard({
  required int eventKind,
  required String hostrRelay,
  List<String>? relays,
}) {
  if (!kHostrOnlyKinds.contains(eventKind)) return relays;
  if (relays == null || !relays.every((r) => r == hostrRelay)) {
    return [hostrRelay];
  }
  return relays;
}

/// Pure relay-guard logic for **reads**: returns the relay list that should
/// be used when querying/subscribing for [eventKind]. Hostr-only kinds are
/// forced onto [hostrRelay] so the app never fetches proprietary events from
/// public relays (which would return nothing useful or spoofed data).
@visibleForTesting
List<String>? applyQueryRelayGuard({
  required int eventKind,
  required String hostrRelay,
  List<String>? relays,
}) {
  if (!kHostrOnlyKinds.contains(eventKind)) return relays;
  if (relays == null || !relays.every((r) => r == hostrRelay)) {
    return [hostrRelay];
  }
  return relays;
}

/// Applies [applyQueryRelayGuard] to a [Filter] that may contain multiple
/// kinds. If **every** kind in the filter is hostr-only the relay list is
/// forced; if **none** are, the list passes through unchanged. Mixed filters
/// are forced to the hostr relay as well (the hostr relay can serve standard
/// kinds too, and splitting the filter would be a larger refactor).
@visibleForTesting
List<String>? applyQueryRelayGuardForFilter({
  required Filter filter,
  required String hostrRelay,
  List<String>? relays,
}) {
  final kinds = filter.kinds;
  if (kinds == null || kinds.isEmpty) return relays;
  final hasHostrKind = kinds.any((k) => kHostrOnlyKinds.contains(k));
  if (!hasHostrKind) return relays;
  // At least one hostr-only kind → force onto hostr relay.
  if (relays == null || !relays.every((r) => r == hostrRelay)) {
    return [hostrRelay];
  }
  return relays;
}

@visibleForTesting
String requestInFlightKeyFor({
  required Filter filter,
  List<String>? relays,
  Duration? timeout,
  bool cacheRead = true,
  bool cacheWrite = true,
}) {
  return jsonEncode({
    'filter': cleanTags(filter)?.toMap() ?? filter.toMap(),
    'relays': relays,
    'timeoutUs': timeout?.inMicroseconds,
    'cacheRead': cacheRead,
    'cacheWrite': cacheWrite,
  });
}

typedef NostrParseErrorHandler =
    void Function(Nip01Event event, Object error, StackTrace stackTrace);

T? parseNostrEventForSdk<T extends Nip01Event>({
  required Nip01Event event,
  required NostrParseErrorHandler onParseError,
}) {
  try {
    return parser<T>(event);
  } catch (error, stackTrace) {
    onParseError(event, error, stackTrace);
    return null;
  }
}

Stream<T> parseNostrEventsForSdk<T extends Nip01Event>({
  required Stream<Nip01Event> source,
  required NostrParseErrorHandler onParseError,
}) {
  return source.expand((event) {
    final parsed = parseNostrEventForSdk<T>(
      event: event,
      onParseError: onParseError,
    );
    if (parsed == null) return <T>[];
    return [parsed];
  });
}

bool hasSuccessfulBroadcast(List<RelayBroadcastResponse> responses) {
  return responses.any((response) => response.broadcastSuccessful);
}

String formatBroadcastResponses(List<RelayBroadcastResponse> responses) {
  if (responses.isEmpty) return 'no relay responses';
  return responses
      .map(
        (response) =>
            '${response.relayUrl}{ok=${response.okReceived}, '
            'success=${response.broadcastSuccessful}, msg=${response.msg}}',
      )
      .join(', ');
}

String _shortHex(String? value) {
  if (value == null) return 'null';
  if (value.length <= 16) return value;
  return '${value.substring(0, 8)}...${value.substring(value.length - 8)}';
}

String _nostrEventDebugJson(Nip01Event event) {
  return jsonEncode(Nip01EventModel.fromEntity(event).toJson());
}

String _broadcastEventDebugSummary(Nip01Event event) {
  final calculatedId = Nip01Utils.calculateId(event);
  return [
    'kind=${event.kind}',
    'pubkey=${_shortHex(event.pubKey)}',
    'createdAt=${event.createdAt}',
    'tags=${event.tags.length}',
    'contentLength=${event.content.length}',
    'id=${_shortHex(event.id)}',
    'calculated=${_shortHex(calculatedId)}',
    'idValid=${event.id == calculatedId}',
    'sigPresent=${event.sig != null}',
    if (event.sig != null) 'sig=${_shortHex(event.sig)}',
  ].join(' ');
}

void throwIfBroadcastFailed(
  List<RelayBroadcastResponse> responses, {
  required String context,
}) {
  if (hasSuccessfulBroadcast(responses)) return;
  throw StateError(
    'Broadcast failed for $context: ${formatBroadcastResponses(responses)}',
  );
}

abstract class RequestsModel {
  Stream<T> query<T extends Nip01Event>({
    required Filter filter,
    Duration? timeout,
    List<String>? relays,
    String? name,
    bool cacheRead = true,
    bool cacheWrite = true,
  });
  StreamWithStatus<T> subscribe<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
    String? name,

    /// When false, the live subscription will not have a [since] filter applied
    /// based on the latest query result. Set this to false for event types
    /// (e.g. NIP-59 gift wraps) whose [created_at] is intentionally randomised
    /// into the past, so that newly arriving events are never filtered out.
    bool setSinceOnLiveFilter = true,
  });
  Future<int> count({
    required Filter filter,
    Duration? timeout,
    List<String>? relays,
  });

  Future<BroadcastResult> broadcastEvent({
    required Nip01Event event,
    List<String>? relays,
    NostrEventSigner? signer,
  });

  /// Opens a live-only NDK subscription (no historical query phase).
  ///
  /// Events are parsed and forwarded to [onData]. The caller is responsible
  /// for closing the subscription via [LiveSubscriptionHandle.cancel].
  ///
  /// Use this alongside [query] when you need to manage the query and live
  /// phases independently — e.g. expanding a filter on an existing
  /// [StreamWithStatus] without tearing it down.
  LiveSubscriptionHandle liveSubscription<T extends Nip01Event>({
    required Filter filter,
    required void Function(T) onData,
    void Function(Object, StackTrace?)? onError,
    required String name,
    List<String>? relays,
  });
}

/// Handle returned by [Requests.liveSubscription] for tearing down the
/// NDK relay subscription without affecting the caller's stream.
class LiveSubscriptionHandle {
  final Future<void> Function() _cancel;
  final String ndkSubName;

  /// @nodoc — package-internal. Use [Requests.liveSubscription] to obtain.
  LiveSubscriptionHandle(this._cancel, this.ndkSubName);

  /// Cancels the local listener and sends CLOSE to the relay.
  Future<void> cancel() => _cancel();
}

@Singleton(env: Env.allButTestAndMock)
class Requests extends RequestsModel {
  final Ndk _ndk;
  final Auth _auth;
  final HostrConfig _config;
  final bool useCache = false;
  final CustomLogger _logger;
  Ndk get ndk => _ndk;
  bool _loggedFirstQuery = false;

  /// In-flight query dedup: filter key → broadcast stream.
  /// If a query with the same filter is already running, new callers
  /// share its broadcast stream instead of opening another relay subscription.
  final Map<String, Stream<Nip01Event>> _inFlightQueries = {};

  Requests({
    required Ndk ndk,
    required CustomLogger logger,
    required Auth auth,
    required HostrConfig config,
  }) : _ndk = ndk,
       _auth = auth,
       _config = config,
       _logger = logger.scope('requests') {
    Logger.log.addOutput(_SubscriptionDebugOutput(ndk));
  }

  // NIP-01 doesn't specify a maximum subscription ID length, but many relay
  // implementations (including Damus / nostr-rs-relay) enforce a 64-char cap.
  static const int _maxSubIdLength = 64;

  // NDK appends "-" + 10 random chars to the name for query() calls on the
  // wire, so the safe maximum for any name we pass to ndk.requests.query() is
  // 64 - 11 = 53 chars.  ndk.requests.subscription() uses the id as-is, so
  // the full 64 chars are available there.
  static const int _ndkQuerySuffix = 11; // "-" + 10 random chars
  static const int _maxQueryNameLength = _maxSubIdLength - _ndkQuerySuffix;

  /// Truncates [id] to [_maxSubIdLength] for use as a live-subscription id
  /// (passed to [ndk.requests.subscription] which uses the value verbatim).
  static String capSubId(String id) =>
      id.length > _maxSubIdLength ? id.substring(0, _maxSubIdLength) : id;

  /// Truncates [name] to [_maxQueryNameLength] for use as a query name
  /// (NDK appends its own random suffix, so we need extra headroom).
  static String capQueryName(String name) => name.length > _maxQueryNameLength
      ? name.substring(0, _maxQueryNameLength)
      : name;

  // With a 6-char suffix ("-XXXXX") that leaves 57 chars for the base name,
  // but _namedRequest is only used for live-subscription IDs (not queries).
  String _namedRequest(String baseName, [int suffixLength = 5]) {
    final suffix = '-${Helpers.getRandomString(suffixLength)}';
    final maxBase = _maxSubIdLength - suffix.length;
    final truncated = baseName.length > maxBase
        ? baseName.substring(0, maxBase)
        : baseName;
    return '$truncated$suffix';
  }

  Stream<Nip01Event> _connectedStream({
    required Stream<Nip01Event> Function() open,
  }) {
    return Rx.defer(open);
  }

  Stream<T> _parseEvents<T extends Nip01Event>(Stream<Nip01Event> source) {
    return parseNostrEventsForSdk<T>(
      source: source,
      onParseError: _logParseError,
    );
  }

  void _logParseError(Nip01Event event, Object error, StackTrace stackTrace) {
    _logger.w(
      'Failed to parse Nostr event kind=${event.kind} id=${event.id}',
      error: error,
      stackTrace: stackTrace,
    );
  }

  Stream<Nip01Event> _openQueryStream({
    required String name,
    required Filter filter,
    Duration? timeout,
    List<String>? relays,
    bool cacheRead = true,
    bool cacheWrite = true,
  }) {
    return _connectedStream(
      open: () => ndk.requests
          .query(
            name: capQueryName(name),
            filter: cleanTags(filter),
            cacheRead: cacheRead,
            cacheWrite: cacheWrite,
            timeout: timeout,
            explicitRelays: relays,
          )
          .stream,
    );
  }

  Stream<Nip01Event> _openLiveStream({
    required String name,
    required Filter filter,
    bool cacheRead = false,
    List<String>? relays,
  }) {
    return _connectedStream(
      open: () => ndk.requests
          .subscription(
            id: capSubId(name),
            filter: cleanTags(filter),
            cacheRead: cacheRead,
            cacheWrite: true,
            explicitRelays: relays,
          )
          .stream,
    );
  }

  // NDK does not let us subscribe to fetch old events, complete, and keep streaming, so we have to implement our own version
  @override
  StreamWithStatus<T> subscribe<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
    String? name,
    bool setSinceOnLiveFilter = true,
  }) => _logger.spanSync('subscribe', () {
    if (name == null) {
      throw ArgumentError(
        'Name is required for subscribe to ensure proper cleanup of subscriptions. Please provide a name like "MyEntity-sub"',
      );
    }
    final ndkSubName = _namedRequest(name);
    final response = StreamWithStatus<T>(
      onClose: () async {
        await ndk.requests.closeSubscription(ndkSubName);
      },
    );

    // ── Relay guard: hostr-specific kinds should only query the hostr relay ──
    final guardedRelays = applyQueryRelayGuardForFilter(
      filter: filter,
      hostrRelay: _config.hostrRelay,
      relays: relays,
    );
    if (guardedRelays != relays) {
      _logger.d(
        'subscribe guard: forced filter kinds=${filter.kinds} onto hostr relay',
      );
    }
    relays = guardedRelays;

    response.addStatus(StreamStatusQuerying());

    int? lastCreatedAt;
    Filter? liveFilter;

    final queryStream = _openQueryStream(
      name: '$name-q',
      filter: filter,
      relays: relays,
    );

    final subscription =
        _parseEvents<T>(
          queryStream
              .doOnDone(() {
                response.addStatus(StreamStatusQueryComplete());

                liveFilter = filter.clone();
                if (setSinceOnLiveFilter && lastCreatedAt != null) {
                  final nextSince = lastCreatedAt! + 1;
                  liveFilter!.since =
                      liveFilter!.since == null ||
                          nextSince > liveFilter!.since!
                      ? nextSince
                      : liveFilter!.since;
                }

                response.addStatus(StreamStatusLive());
              })
              .concatWith([
                Rx.defer(() {
                  final effectiveLiveFilter = liveFilter ?? filter.clone();
                  return _openLiveStream(
                    name: ndkSubName,
                    filter: effectiveLiveFilter,
                    cacheRead: useCache,
                    relays: relays,
                  );
                }),
              ]),
        ).listen((item) {
          lastCreatedAt = lastCreatedAt == null
              ? item.createdAt
              : max(lastCreatedAt!, item.createdAt);
          response.add(item);
        }, onError: response.addError);
    response.addSubscription(subscription);

    return response;
  });

  @override
  Stream<T> query<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
    Duration? timeout,
    String? name,
    bool cacheRead = true,
    bool cacheWrite = true,
  }) => _logger.spanSync('query', () {
    // ── Relay guard: hostr-specific kinds should only query the hostr relay ──
    final guardedRelays = applyQueryRelayGuardForFilter(
      filter: filter,
      hostrRelay: _config.hostrRelay,
      relays: relays,
    );
    if (guardedRelays != relays) {
      _logger.d(
        'query guard: forced filter kinds=${filter.kinds} onto hostr relay',
      );
    }
    relays = guardedRelays;

    final key = requestInFlightKeyFor(
      filter: filter,
      relays: relays,
      timeout: timeout,
      cacheRead: cacheRead,
      cacheWrite: cacheWrite,
    );

    // If there's already an in-flight query with identical behavior, share it.
    if (_inFlightQueries.containsKey(key)) {
      return _parseEvents<T>(_inFlightQueries[key]!);
    }

    final sw = Stopwatch()..start();
    final queryName = name ?? _namedRequest('query');
    final source =
        _openQueryStream(
              name: queryName,
              filter: filter,
              timeout: timeout,
              relays: relays,
              cacheRead: cacheRead,
              cacheWrite: cacheWrite,
            )
            .doOnListen(() {
              final now = DateTime.now().toIso8601String();
              if (!_loggedFirstQuery) {
                _loggedFirstQuery = true;
                _logger.i('first-req timestamp: $now name=$queryName');
              }
              _logger.d('req timestamp: $now name=$queryName filter=$filter');
            })
            .doOnDone(() {
              sw.stop();
              _logger.d(
                'query name=${capQueryName(queryName)} completed in ${sw.elapsedMilliseconds}ms',
              );
              _inFlightQueries.remove(key);
            })
            .doOnError((_, _) {
              sw.stop();
              _inFlightQueries.remove(key);
            })
            .shareReplay();

    _inFlightQueries[key] = source;

    return _parseEvents<T>(source);
  });

  // @TODO: There must be a better way to do this
  @override
  Future<int> count({
    required Filter filter,
    Duration? timeout,
    List<String>? relays,
  }) => _logger.span('count', () async {
    var results = await query(
      filter: filter,
      timeout: timeout,
      relays: relays,
    ).toList();
    return results.length;
  });

  @override
  Future<BroadcastResult> broadcastEvent({
    required Nip01Event event,
    List<String>? relays,
    NostrEventSigner? signer,
  }) async {
    // ── Relay guard: app-specific events must never leak to external relays ──
    final guardedRelays = applyBroadcastRelayGuard(
      eventKind: event.kind,
      hostrRelay: _config.hostrRelay,
      relays: relays,
    );
    if (guardedRelays != relays) {
      _logger.w(
        'broadcast guard: forced kind ${event.kind} onto hostr relay only',
      );
    }
    relays = guardedRelays;

    var eventToBroadcast = event;

    if (event.sig == null) {
      eventToBroadcast = await (signer ?? _auth.signEvent)(event);
    }
    if (eventToBroadcast.sig != null && eventToBroadcast.id.isEmpty) {
      eventToBroadcast = eventToBroadcast.copyWith(
        id: Nip01Utils.calculateId(eventToBroadcast),
      );
    }

    _logger.d(
      'broadcast event: ${_broadcastEventDebugSummary(eventToBroadcast)}',
    );
    if (eventToBroadcast.kind == kNostrKindIdentityClaims) {
      _logger.d(
        'broadcast identity claim JSON: ${_nostrEventDebugJson(eventToBroadcast)}',
      );
    }

    final responses = await ndk.broadcast
        .broadcast(nostrEvent: eventToBroadcast, specificRelays: relays)
        .broadcastDoneFuture;
    throwIfBroadcastFailed(
      responses,
      context: 'kind ${event.kind} ${event.id}',
    );
    return BroadcastResult(event: eventToBroadcast, responses: responses);
  }

  /// Opens a live-only NDK subscription (no query phase) and forwards
  /// parsed events to [onData].
  ///
  /// This is the live half of [subscribe] extracted for use cases where
  /// the caller manages its own [StreamWithStatus] and query lifecycle —
  /// e.g. [ExpandableSubscription] which needs to close and re-open the
  /// live subscription with an expanded filter while keeping the same
  /// output stream.
  @override
  LiveSubscriptionHandle liveSubscription<T extends Nip01Event>({
    required Filter filter,
    required void Function(T) onData,
    void Function(Object, StackTrace?)? onError,
    required String name,
    List<String>? relays,
  }) => _logger.spanSync('liveSubscription', () {
    // ── Relay guard: hostr-specific kinds should only query the hostr relay ──
    final guardedRelays = applyQueryRelayGuardForFilter(
      filter: filter,
      hostrRelay: _config.hostrRelay,
      relays: relays,
    );
    if (guardedRelays != relays) {
      _logger.d(
        'liveSubscription guard: forced filter kinds=${filter.kinds} onto hostr relay',
      );
    }
    relays = guardedRelays;

    final ndkSubName = _namedRequest(name);

    _logger.d('liveSubscription opening: $ndkSubName filter=$filter');

    final listener = _parseEvents<T>(
      _openLiveStream(
        name: ndkSubName,
        filter: filter,
        cacheRead: useCache,
        relays: relays,
      ),
    ).listen(onData, onError: onError);

    return LiveSubscriptionHandle(() async {
      _logger.d('liveSubscription closing: $ndkSubName');
      await listener.cancel();
      await ndk.requests.closeSubscription(ndkSubName);
    }, ndkSubName);
  });
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
