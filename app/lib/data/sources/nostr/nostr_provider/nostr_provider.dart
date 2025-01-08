import 'package:dart_nostr/dart_nostr.dart';
import 'package:dart_nostr/nostr/model/ease.dart';
import 'package:dart_nostr/nostr/model/ok.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

abstract class NostrProvider {
  CustomLogger logger = CustomLogger();
  ReplaySubject<NostrEvent> events = ReplaySubject<NostrEvent>();

  NostrEventsStream startRequest(
      {required NostrRequest request,
      required void Function(String relay, NostrRequestEoseCommand ease) onEose,
      List<String>? relays});

  Future<List<NostrEvent>> startRequestAsync(
      {required NostrRequest request, List<String>? relays});

  Future<NostrEventOkCommand> sendEventToRelaysAsync(
      {required NostrEvent event, List<String>? relays});
}

@Singleton(as: NostrProvider, env: Env.allButTestAndMock)
class ProdNostrProvider extends NostrProvider {
  @override
  startRequest(
      {required NostrRequest request,
      required void Function(String relay, NostrRequestEoseCommand ease) onEose,
      List<String>? relays}) {
    return Nostr.instance.relaysService.startEventsSubscription(
        request: request, onEose: onEose, relays: relays);
  }

  @override
  startRequestAsync({required NostrRequest request, List<String>? relays}) {
    return Nostr.instance.relaysService.startEventsSubscriptionAsync(
        relays: relays, request: request, timeout: Duration(seconds: 5));
  }

  @override
  sendEventToRelaysAsync({required NostrEvent event, List<String>? relays}) {
    return Nostr.instance.relaysService.sendEventToRelaysAsync(event,
        relays: relays, timeout: Duration(seconds: 5));
  }
}
