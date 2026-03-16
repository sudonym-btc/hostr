import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:models/nostr_parser.dart';
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
  final List<Nip01Event> _events = [];
  final List<_Subscription> _subscriptions = [];
  int _subCounter = 0;

  InMemoryRequests({
    required super.ndk,
    required super.auth,
    required super.logger,
  }) : _ndk = ndk,
       super();

  /// Add an event to the in-memory store and notify active subscriptions.
  void addEvent(Nip01Event event) {
    // Update existing event if it has an 'a' tag match @TODO SHOULD BE D TAG!
    List<Nip01Event> existingEvents = _events
        .where(
          (e) =>
              e.pubKey == event.pubKey &&
              e.getFirstTag('a') != null &&
              event.getFirstTag('a') != null &&
              e.getFirstTag('a') == event.getFirstTag('a'),
        )
        .toList();

    if (existingEvents.isNotEmpty) {
      for (var e in existingEvents) {
        _events.remove(e);
      }
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
        final parsedEvent = safeParser<T>(event);
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
        final parsedEvent = safeParser<T>(event);
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
  }) async* {
    // Return matching events then close
    final snapshot = List<Nip01Event>.of(_events);
    for (var event in snapshot) {
      if (matchEvent(event, filter)) {
        final parsedEvent = safeParser<T>(event);
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
  Future<List<RelayBroadcastResponse>> broadcast({
    required Nip01Event event,
    List<String>? relays,
  }) async {
    addEvent(event);
    return [
      RelayBroadcastResponse(
        relayUrl: 'in-memory://localhost',
        okReceived: true,
        broadcastSuccessful: true,
        msg: '',
      ),
    ];
  }

  /// Clean up subscriptions.
  void dispose() {
    for (var sub in _subscriptions) {
      sub.response.close();
    }
    _subscriptions.clear();
  }

  @override
  LiveSubscriptionHandle liveSubscription<T extends Nip01Event>({
    required Filter filter,
    required void Function(T) onData,
    void Function(Object, StackTrace?)? onError,
    required String name,
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
        final parsedEvent = safeParser<T>(event);
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

  /// Seed events in bulk.
  void seedEvents(List<Nip01Event> events) {
    for (var event in events) {
      addEvent(event);
    }
  }
}
