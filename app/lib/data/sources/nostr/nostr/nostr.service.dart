import 'package:dart_nostr/dart_nostr.dart';
import 'package:dart_nostr/nostr/model/ease.dart';
import 'package:dart_nostr/nostr/model/ok.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:injectable/injectable.dart';
import 'package:rxdart/rxdart.dart';

abstract class NostrService {
  CustomLogger logger = CustomLogger();
  ReplaySubject<NostrEvent> events = ReplaySubject<NostrEvent>();

  NostrEventsStream startRequest<T extends NostrEvent>(
      {required NostrRequest request,
      required void Function(String relay, NostrRequestEoseCommand ease) onEose,
      List<String>? relays});

  Future<List<NostrEvent>> startRequestAsync<T extends NostrEvent>(
      {required NostrRequest request, List<String>? relays, Duration? timeout});

  Future<int> count(NostrFilter filter);

  Future<NostrEventOkCommand> sendEventToRelaysAsync(
      {required NostrEvent event, List<String>? relays});
}

@Singleton(as: NostrService, env: Env.allButTestAndMock)
class ProdNostrService extends NostrService {
  @override
  startRequest<T extends NostrEvent>(
      {required NostrRequest request,
      required void Function(String relay, NostrRequestEoseCommand ease) onEose,
      List<String>? relays}) {
    NostrEventsStream n = Nostr.instance.relaysService.startEventsSubscription(
        request: request, onEose: onEose, relays: relays);

    return NostrEventsStream(
        stream: n.stream.asyncMap((event) async {
          return parser<T>(event, await getIt<KeyStorage>().getActiveKeyPair(),
              await getIt<NwcStorage>().getUri());
        }),
        subscriptionId: n.subscriptionId,
        request: n.request);
  }

  @override
  startRequestAsync<T extends NostrEvent>(
      {required NostrRequest request,
      List<String>? relays,
      Duration? timeout}) async {
    List<NostrEvent> res =
        await Nostr.instance.relaysService.startEventsSubscriptionAsync(
            relays: relays,
            request: request,
            onEose: (String relay, NostrRequestEoseCommand ease) {
              logger.i('onEose $relay, $ease');
            },
            shouldThrowErrorOnTimeoutWithoutEose: false,
            timeout: timeout ?? Duration(seconds: 5));
    List<T> parsedEvents = await Future.wait(res.map((event) async {
      return parser<T>(event, await getIt<KeyStorage>().getActiveKeyPair(),
          await getIt<NwcStorage>().getUri());
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
  // print('eventKind: $eventKind, ${T.toString()} should be returned, $event ');
  if (Reservation.kinds.contains(eventKind)) {
    return Reservation.fromNostrEvent(event) as T;
  } else if (GiftWrap.kinds.contains(eventKind)) {
    return GiftWrap.fromNostrEvent(event, key!, nwc) as T;
  } else if (Seal.kinds.contains(eventKind)) {
    return Seal.fromNostrEvent(event, key!, nwc) as T;
  } else if (Message.kinds.contains(eventKind)) {
    return Message.fromNostrEvent(event, key!, nwc) as T;
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
