import 'dart:math';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:dart_nostr/nostr/model/ease.dart';
import 'package:dart_nostr/nostr/model/ok.dart';
import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

import 'nostr_provider.dart';

// todo: must filter by since, before, and limit, must implement count, must implement replaceable events
@Singleton(as: NostrProvider, env: [Env.mock, Env.test])
class MockNostProvider extends NostrProvider {
  @override
  ReplaySubject<NostrEvent> events = ReplaySubject<NostrEvent>();

  @override
  NostrEventsStream startRequest(
      {required NostrRequest request,
      required void Function(String relay, NostrRequestEoseCommand ease) onEose,
      List<String>? relays}) {
    // Create filtered events stream with artificial delay
    final filteredEvents = events.stream
        .where((event) =>
            request.filters.every((filter) => matchEvent(event, filter)))
        .asyncMap((event) async {
      await Future.delayed(
          Duration(milliseconds: 100)); // Simulate network latency
      return event;
    }).take(request.filters.any((f) => f.limit != null)
            ? request.filters
                .map((f) => f.limit ?? double.infinity)
                .reduce(min)
                .toInt()
            : 999999999999); // Max int if no limit defined

    onEose(
        'mock',
        NostrRequestEoseCommand(
            subscriptionId: request.subscriptionId ?? "mock-subscription-id"));

    return NostrEventsStream(
        stream: filteredEvents,
        subscriptionId: request.subscriptionId ?? "mock-subscription-id",
        request: request);
  }

  @override
  Future<NostrEventOkCommand> sendEventToRelaysAsync(
      {required NostrEvent event, List<String>? relays}) async {
    events.add(event);
    return Future.value(NostrEventOkCommand(
        eventId: event.id!, isEventAccepted: true, message: ""));
  }

  matchEvent(NostrEvent event, NostrFilter filter) {
    if (filter.kinds != null && !filter.kinds!.contains(event.kind)) {
      return false;
    }
    if (filter.p != null && !filter.p!.contains(event.pubkey)) {
      return false;
    }
    if (filter.authors != null &&
        (!filter.authors!.contains(event.pubkey) ||
            (event.tags!.contains((tag) => tag[0] == "delegation") &&
                !filter.authors!.contains(event.tags!
                    .lastWhere((tag) => tag[0] == "delegation")[1])))) {
      return false;
    }

    return true;
  }

  @override
  Future<List<NostrEvent>> startRequestAsync(
      {required NostrRequest request, List<String>? relays}) {
    return startRequest(
      request: request,
      onEose: (relay, ease) => false,
    ).stream.toList();
  }
}
