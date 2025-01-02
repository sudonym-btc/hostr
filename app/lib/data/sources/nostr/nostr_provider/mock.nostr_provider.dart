import 'package:dart_nostr/dart_nostr.dart';
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
  NostrEventsStream startRequest({required NostrRequest request}) {
    return NostrEventsStream(
        stream: events.stream.where((event) =>
            request.filters.every((filter) => matchEvent(event, filter))),
        subscriptionId: request.subscriptionId ?? "mock-subscription-id",
        request: request);
  }

  @override
  void sendEventToRelays(NostrEvent event) {
    events.add(event);
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
}
