import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

abstract class NostrProvider {
  ReplaySubject<NostrEvent> events = ReplaySubject<NostrEvent>();
  NostrEventsStream startRequest({required NostrRequest request});
  void sendEventToRelays(NostrEvent event);
}

@Singleton(as: NostrProvider, env: Env.allButTestAndMock)
class ProdNostrProvider extends NostrProvider {
  @override
  startRequest({required NostrRequest request}) {
    return Nostr.instance.relaysService
        .startEventsSubscription(request: request);
  }

  @override
  void sendEventToRelays(NostrEvent event) {
    Nostr.instance.relaysService.sendEventToRelays(event);
  }
}
