import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:models/nostr_parser.dart';
import 'package:models/stubs/main.dart';
import 'package:ndk/entities.dart' show RelayBroadcastResponse;
import 'package:ndk/ndk.dart' show Nip01Event, Filter, Ndk;
import 'package:rxdart/rxdart.dart';

import '../../../mock.relay.dart';
import 'requests.dart';

class _Subscription<T extends Nip01Event> {
  final String id;
  final Filter filter;
  final BehaviorSubject<T> controller;

  _Subscription({
    required this.id,
    required this.filter,
    required this.controller,
  });
}

@Singleton(as: Requests, env: [Env.test, Env.mock])
class TestRequests extends Requests implements RequestsModel {
  @override
  final Ndk ndk;
  final List<Nip01Event> _events = [];
  final List<_Subscription> _subscriptions = [];
  final BehaviorSubject<Nip01Event> _onAddEvent = BehaviorSubject();
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
    // Update existing event if it has an 'a' tag match
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
    _onAddEvent.add(event);

    // Notify matching subscriptions
    for (var sub in _subscriptions) {
      if (matchEvent(event, sub.filter)) {
        sub.controller.add(event as dynamic);
      }
    }
  }

  @override
  Stream<T> subscribe<T extends Nip01Event>({
    required Filter filter,
    List<String>? relays,
  }) {
    final subId = 'sub_${_subCounter++}';
    final controller = BehaviorSubject<T>();

    final subscription = _Subscription<T>(
      id: subId,
      filter: filter,
      controller: controller,
    );

    _subscriptions.add(subscription);

    // Return existing matching events immediately
    for (var event in _events) {
      if (matchEvent(event, filter)) {
        parserWithGiftWrap<T>(event, ndk).then((parsedEvent) {
          controller.add(parsedEvent);
        });
      }
    }

    // Listen for future events
    _onAddEvent.where((event) => matchEvent(event, filter)).listen((
      event,
    ) async {
      final parsedEvent = await parserWithGiftWrap<T>(event, ndk);
      controller.add(parsedEvent);
    });

    return controller.stream;
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
      sub.controller.close();
    }
    _subscriptions.clear();
    _onAddEvent.close();
  }

  /// Seed events for testing.
  void seedEvents(List<Nip01Event> events) {
    for (var event in events) {
      addEvent(event);
    }
  }
}
