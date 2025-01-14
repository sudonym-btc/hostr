import 'package:dart_nostr/dart_nostr.dart';
import 'package:dart_nostr/nostr/model/ease.dart';
import 'package:dart_nostr/nostr/model/ok.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/services/nwc.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

abstract class NostrService {
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

@Singleton(as: NostrService, env: Env.allButTestAndMock)
class ProdNostrService extends NostrService {
  @override
  startRequest(
      {required NostrRequest request,
      required void Function(String relay, NostrRequestEoseCommand ease) onEose,
      List<String>? relays}) {
    NostrEventsStream n = Nostr.instance.relaysService.startEventsSubscription(
        request: request, onEose: onEose, relays: relays);

    return NostrEventsStream(
        stream: n.stream.asyncMap((event) async {
          Uri nwcUri = parseNwc((await getIt<NwcStorage>().get()).first);
          NostrKeyPairs? keyPair = await getIt<KeyStorage>().getActiveKeyPair();
          return parser(event, keyPair, nwcUri);
        }),
        subscriptionId: n.subscriptionId,
        request: n.request);
  }

  @override
  startRequestAsync(
      {required NostrRequest request, List<String>? relays}) async {
    List<NostrEvent> res = await Nostr.instance.relaysService
        .startEventsSubscriptionAsync(
            relays: relays, request: request, timeout: Duration(seconds: 5));
    List<NostrEvent> parsedEvents = await Future.wait(res.map((event) async {
      Uri nwcUri = parseNwc((await getIt<NwcStorage>().get()).first);
      NostrKeyPairs? keyPair = await getIt<KeyStorage>().getActiveKeyPair();
      return parser(event, keyPair, nwcUri);
    }).toList());
    return parsedEvents;
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
T parser<T extends NostrEvent>(NostrEvent event, NostrKeyPairs? key, Uri? nwc) {
  int eventKind = event.kind!;

  if (Reservation.kinds.contains(eventKind)) {
    return Reservation.fromNostrEvent(event) as T;
  } else if (GiftWrap.kinds.contains(eventKind)) {
    return GiftWrap.fromNostrEvent(event, key!, nwc) as T;
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
  } else if (NwcInfo.kinds.contains(eventKind)) {
    return NwcInfo.fromNostrEvent(event) as T;
  } else if (NwcRequest.kinds.contains(eventKind)) {
    return NwcRequest.fromNostrEvent(event, nwc!) as T;
  } else if (NwcResponse.kinds.contains(eventKind)) {
    return NwcResponse.fromNostrEvent(event, nwc!) as T;
  }
  return event as T;
}
