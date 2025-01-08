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
  // @override
  // ReplaySubject<NostrEvent> events = ReplaySubject<NostrEvent>();

  @override
  NostrEventsStream startRequest(
      {required NostrRequest request,
      required void Function(String relay, NostrRequestEoseCommand ease) onEose,
      List<String>? relays}) {
    logger.i("startRequest $request");
    // Create filtered events stream with artificial delay
    final filteredEvents = events.stream

        /// Nostr filters act as OR, so we need to check if any filter matches
        .where((event) =>
            request.filters.any((filter) => matchEvent(event, filter)))
        .doOnData((event) => logger.t("matched event $event"))

        /// Simulate network delay for each event
        .asyncExpand((event) async* {
      await Future.delayed(Duration(milliseconds: 500));
      yield event;
    })

        /// Limit the number of events, Max int if no limit defined
        .take(request.filters.any((f) => f.limit != null)
            ? request.filters
                .map((f) => f.limit ?? 999999999999)
                .reduce(min)
                .toInt()
            : 999999999999);
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
    logger.i("sendEventToRelaysAsync $event");
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
