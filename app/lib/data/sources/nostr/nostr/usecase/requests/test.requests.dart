import 'dart:async';

import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:models/nostr_parser.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/entities.dart' show RelayBroadcastResponse;
import 'package:ndk/ndk.dart' show Nip01Event, Filter, Ndk;

import '../../../mock.relay.dart';
import 'requests.dart';

class _Subscription<T extends Nip01Event> {
  final String id;
  final Filter filter;
  final SubscriptionResponse response;

  _Subscription({
    required this.id,
    required this.filter,
    required this.response,
  });
}

@Singleton(as: Requests, env: [Env.test, Env.mock])
class TestRequests extends Requests implements RequestsModel {
  @override
  final Ndk ndk;
  final List<Nip01Event> _events = [];
  final List<_Subscription> _subscriptions = [];
  int _subCounter = 0;

  TestRequests({required this.ndk}) : super(ndk: ndk);

  @override
  mock() async {
    for (Nip01Event e in await MOCK_EVENTS()) {
      addEvent(e);
    }
  }

  /// Add an event to the mock storage and notify subscriptions.
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
        sub.response.add(event as dynamic);
      }
    }
  }

  @override
  SubscriptionResponse<T> subscribe<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
  }) {
    final subId = 'sub_${_subCounter++}';
    final SubscriptionResponse response = SubscriptionResponse(subId);

    final subscription = _Subscription<T>(
      id: subId,
      filter: filter,
      response: response,
    );

    _subscriptions.add(subscription);

    final initialEvents = _events.where((event) => matchEvent(event, filter));
    response.addStatus(SubscriptionStatusQuerying());

    final initialFuture = () async {
      final List<T> parsedEvents = [];
      for (final event in initialEvents) {
        final parsedEvent = await parserWithGiftWrap<T>(event, ndk);
        response.add(parsedEvent);
        parsedEvents.add(parsedEvent);
      }
      return parsedEvents;
    }();

    response.addStatus(SubscriptionStatusQueryComplete());

    initialFuture.then((events) {
      response.addAll(events);
      response.addStatus(SubscriptionStatusQueryComplete());
      response.addStatus(SubscriptionStatusLive());
    });

    return SubscriptionResponse<T>(subId);
  }

  @override
  Stream<T> query<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
    Duration? timeout,
  }) async* {
    // Return matching events then close
    for (var event in _events) {
      if (matchEvent(event, filter)) {
        final parsedEvent = await parserWithGiftWrap<T>(event, ndk);
        yield parsedEvent;
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
        relayUrl: 'mock://localhost',
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

  /// Seed events for testing.
  void seedEvents(List<Nip01Event> events) {
    for (var event in events) {
      addEvent(event);
    }
  }
}
