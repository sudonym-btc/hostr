import 'package:dart_nostr/dart_nostr.dart';
import 'package:dart_nostr/nostr/model/ease.dart';
import 'package:dart_nostr/nostr/model/ok.dart';
import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

abstract class NostrProvider {
  ReplaySubject<NostrEvent> events = ReplaySubject<NostrEvent>();
  NostrEventsStream startRequest(
      {required NostrRequest request,
      required void Function(String relay, NostrRequestEoseCommand ease)
          onEose});
  Future<List<NostrEvent>> startRequestAsync({required NostrRequest request});
  Future<NostrEventOkCommand> sendEventToRelaysAsync(NostrEvent event);
}

@Singleton(as: NostrProvider, env: Env.allButTestAndMock)
class ProdNostrProvider extends NostrProvider {
  @override
  startRequest(
      {required NostrRequest request,
      required void Function(String relay, NostrRequestEoseCommand ease)
          onEose}) {
    return Nostr.instance.relaysService
        .startEventsSubscription(request: request, onEose: onEose);
  }

  @override
  startRequestAsync({required NostrRequest request}) {
    return Nostr.instance.relaysService.startEventsSubscriptionAsync(
        request: request, timeout: Duration(seconds: 5));
  }

  @override
  sendEventToRelaysAsync(NostrEvent event) {
    return Nostr.instance.relaysService
        .sendEventToRelaysAsync(event, timeout: Duration(seconds: 5));
  }
}
