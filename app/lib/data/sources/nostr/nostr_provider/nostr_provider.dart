import 'package:dart_nostr/dart_nostr.dart';
import 'package:dart_nostr/nostr/model/ease.dart';
import 'package:dart_nostr/nostr/model/ok.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

abstract class NostrSource {
  CustomLogger logger = CustomLogger();
  ReplaySubject<NostrEvent> events = ReplaySubject<NostrEvent>();

  NostrEventsStream startRequest(
      {required NostrRequest request,
      required void Function(String relay, NostrRequestEoseCommand ease) onEose,
      List<String>? relays});

  Future<List<NostrEvent>> startRequestAsync(
      {required NostrRequest request, List<String>? relays});

  Future<int> count(NostrFilter filter);

  Future<NostrEventOkCommand> sendEventToRelaysAsync(
      {required NostrEvent event, List<String>? relays});
}

@Singleton(as: NostrSource, env: Env.allButTestAndMock)
class ProdNostrProvider extends NostrSource {
  @override
  startRequest(
      {required NostrRequest request,
      required void Function(String relay, NostrRequestEoseCommand ease) onEose,
      List<String>? relays}) {
    NostrEventsStream n = Nostr.instance.relaysService.startEventsSubscription(
        request: request, onEose: onEose, relays: relays);

    return NostrEventsStream(
        stream: n.stream.map(parser),
        subscriptionId: n.subscriptionId,
        request: n.request);
  }

  @override
  startRequestAsync({required NostrRequest request, List<String>? relays}) {
    return Nostr.instance.relaysService
        .startEventsSubscriptionAsync(
            relays: relays, request: request, timeout: Duration(seconds: 5))
        .then((events) => events.map(parser).toList());
  }

  @override
  sendEventToRelaysAsync({required NostrEvent event, List<String>? relays}) {
    return Nostr.instance.relaysService.sendEventToRelaysAsync(event,
        relays: relays, timeout: Duration(seconds: 5));
  }

  @override
  count(NostrFilter filter) {
    return Nostr.instance.relaysService
        .sendCountEventToRelaysAsync(
            NostrCountEvent.fromPartialData(eventsFilter: filter),
            timeout: Duration(seconds: 5))
        .then((value) => value.count);
  }
}

/// Receives a raw Nostr event and converts it into a model
T parser<T extends NostrEvent>(NostrEvent event) {
  int eventKind = event.kind!;
  if (Reservation.kinds.contains(eventKind)) {
    return Reservation.fromNostrEvent(event) as T;
  } else if (GiftWrap.kinds.contains(eventKind)) {
    return GiftWrap.fromNostrEvent(event) as T;
  } else if (Escrow.kinds.contains(eventKind)) {
    return Escrow.fromNostrEvent(event) as T;
  } else if (Listing.kinds.contains(eventKind)) {
    return Listing.fromNostrEvent(event) as T;
  } else if (ReservationRequest.kinds.contains(eventKind)) {
    return ReservationRequest.fromNostrEvent(event) as T;
  } else if (Review.kinds.contains(eventKind)) {
    return Review.fromNostrEvent(event) as T;
  } else if (Profile.kinds.contains(eventKind)) {
    return Profile.fromNostrEvent(event) as T;
  } else if (ZapReceipt.kinds.contains(eventKind)) {
    return ZapReceipt.fromNostrEvent(event) as T;
  } else if (ZapRequest.kinds.contains(eventKind)) {
    return ZapRequest.fromNostrEvent(event) as T;
  }
  return event as T;
}
