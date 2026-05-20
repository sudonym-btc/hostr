import 'dart:async';

import 'package:injectable/injectable.dart' hide Order;
import 'package:ndk/entities.dart' show RelayBroadcastResponse;
import 'package:ndk/ndk.dart' show Nip01Event, Filter, Ndk;

import '../../datasources/nostr/mock.relay.dart';
import '../../injection.dart';
import '../../util/main.dart';
import 'requests.dart';

class _Subscription<T extends Nip01Event> {
  final String id;
  final Filter filter;
  final StreamWithStatus<T> response;
  final void Function(Nip01Event event) emit;

  _Subscription({
    required this.id,
    required this.filter,
    required this.response,
    required this.emit,
  });
}

/// Returns the key used to replace an event in the in-memory relay store.
///
/// Nostr replaceable events are scoped by author and kind. Addressable events
/// add a `d` tag identifier, which is what keeps different authors' events for
/// the same trade from clobbering each other.
String? inMemoryReplacementKeyFor(Nip01Event event) {
  if (_isAddressableKind(event.kind)) {
    final dTag = event.getFirstTag('d') ?? '';
    return '${event.kind}:${event.pubKey}:$dTag';
  }

  if (_isRegularReplaceableKind(event.kind)) {
    return '${event.kind}:${event.pubKey}:';
  }

  return null;
}

bool _isRegularReplaceableKind(int kind) {
  return kind == 0 || kind == 3 || (kind >= 10000 && kind < 20000);
}

bool _isAddressableKind(int kind) {
  return kind >= 30000 && kind < 40000;
}

/// Pure in-memory implementation of [Requests].
///
/// No relay, chain, or Docker needed.  All events live in a local list and
/// subscriptions are notified synchronously when new events arrive.
///
/// Registered for [Env.test] and [Env.mock] — any scenario where you want
/// deterministic data without I/O.
///
/// Seed data via [seedEvents] or [addEvent].
@Singleton(as: Requests, env: [Env.test, Env.mock])
class InMemoryRequests extends Requests implements RequestsModel {
  final Ndk _ndk;
  @override
  Ndk get ndk => _ndk;
  final CustomLogger _logger;
  final List<Nip01Event> _events = [];
  final List<_Subscription> _subscriptions = [];
  int _subCounter = 0;

  InMemoryRequests({
    required super.ndk,
    required super.auth,
    required super.logger,
    required super.config,
  }) : _ndk = ndk,
       _logger = logger.scope('in-memory-requests'),
       super();

  /// Add an event to the in-memory store and notify active subscriptions.
  void addEvent(Nip01Event event) {
    final replacementKey = inMemoryReplacementKeyFor(event);
    if (replacementKey != null) {
      _events.removeWhere(
        (existing) => inMemoryReplacementKeyFor(existing) == replacementKey,
      );
    }

    _events.add(event);

    // Notify matching subscriptions
    for (var sub in _subscriptions) {
      if (matchEvent(event, sub.filter)) {
        sub.emit(event);
      }
    }
  }

  @override
  StreamWithStatus<T> subscribe<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
    String? name,
    bool setSinceOnLiveFilter = true,
  }) {
    final subId = 'sub_${_subCounter++}';
    late final _Subscription<T> subscription;
    final StreamWithStatus<T> response = StreamWithStatus<T>(
      onClose: () {
        _subscriptions.remove(subscription);
      },
    );
    subscription = _Subscription<T>(
      id: subId,
      filter: filter,
      response: response,
      emit: (event) {
        final parsedEvent = _parseEvent<T>(event);
        if (parsedEvent != null) {
          response.add(parsedEvent);
        }
      },
    );

    _subscriptions.add(subscription);

    final initialEvents = _events
        .where((event) => matchEvent(event, filter))
        .toList();
    response.addStatus(StreamStatusQuerying());

    final initialFuture = () async {
      final List<T> parsedEvents = [];
      for (final event in initialEvents) {
        final parsedEvent = _parseEvent<T>(event);
        if (parsedEvent != null) {
          parsedEvents.add(parsedEvent);
        }
      }
      return parsedEvents;
    }();

    initialFuture.then((events) {
      response.addAll(events);
      response.addStatus(StreamStatusQueryComplete());
      response.addStatus(StreamStatusLive());
    });

    return response;
  }

  @override
  Stream<T> query<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
    Duration? timeout,
    String? name,
    bool cacheRead = true,
    bool cacheWrite = true,
  }) async* {
    // Return matching events then close
    final snapshot = List<Nip01Event>.of(_events);
    for (var event in snapshot) {
      if (matchEvent(event, filter)) {
        final parsedEvent = _parseEvent<T>(event);
        if (parsedEvent != null) {
          yield parsedEvent;
        }
      }
    }
  }

  @override
  Future<int> count({
    required Filter filter,
    Duration? timeout,
    List<String>? relays,
  }) async {
    return _events.where((event) => matchEvent(event, filter)).length;
  }

  @override
  Future<BroadcastResult> broadcastEvent({
    required Nip01Event event,
    List<String>? relays,
    NostrEventSigner? signer,
  }) async {
    final eventToBroadcast = event.sig == null && signer != null
        ? await signer(event)
        : event;
    addEvent(eventToBroadcast);
    return BroadcastResult(
      event: eventToBroadcast,
      responses: [
        RelayBroadcastResponse(
          relayUrl: 'in-memory://localhost',
          okReceived: true,
          broadcastSuccessful: true,
          msg: '',
        ),
      ],
    );
  }

  /// Clean up subscriptions.
  Future<void> dispose() async {
    for (var sub in _subscriptions) {
      await sub.response.close();
    }
    _subscriptions.clear();
  }

  @override
  LiveSubscriptionHandle liveSubscription<T extends Nip01Event>({
    required Filter filter,
    required void Function(T) onData,
    void Function(Object, StackTrace?)? onError,
    required String name,
    List<String>? relays,
  }) {
    final subId = 'live_${_subCounter++}';
    late final _Subscription<T> subscription;
    final StreamWithStatus<T> response = StreamWithStatus<T>(
      onClose: () {
        _subscriptions.remove(subscription);
      },
    );
    subscription = _Subscription<T>(
      id: subId,
      filter: filter,
      response: response,
      emit: (event) {
        final parsedEvent = _parseEvent<T>(event);
        if (parsedEvent != null) {
          response.add(parsedEvent);
        }
      },
    );
    _subscriptions.add(subscription);

    final listener = response.stream.listen(onData, onError: onError);
    response.addStatus(StreamStatusLive());

    return LiveSubscriptionHandle(() async {
      await listener.cancel();
      _subscriptions.remove(subscription);
    }, subId);
  }

  T? _parseEvent<T extends Nip01Event>(Nip01Event event) {
    return parseNostrEventForSdk<T>(event: event, onParseError: _logParseError);
  }

  void _logParseError(Nip01Event event, Object error, StackTrace stackTrace) {
    _logger.w(
      'Failed to parse in-memory Nostr event kind=${event.kind} id=${event.id}',
      error: error,
      stackTrace: stackTrace,
    );
  }

  /// Seed events in bulk.
  void seedEvents(List<Nip01Event> events) {
    for (var event in events) {
      addEvent(event);
    }
  }
}
