import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import 'nostr/main.dart';

/// Receives a raw Nostr event and converts it into a model
T parser<T extends Event>(Nip01Event event, KeyPair? key) {
  int eventKind = event.kind;
  // print('eventKind: $eventKind, ${T.toString()} should be returned, $event ');
  if (Reservation.kinds.contains(eventKind)) {
    return Reservation.fromNostrEvent(event) as T;
  } else if (Seal.kinds.contains(eventKind)) {
    return Seal.fromNostrEvent(event, key!) as T;
  } else if (Message.kinds.contains(eventKind)) {
    return Message.safeFromNostrEvent(event, key!) as T;
  } else if (Escrow.kinds.contains(eventKind)) {
    return Escrow.fromNostrEvent(event) as T;
  } else if (Listing.kinds.contains(eventKind)) {
    return Listing.fromNostrEvent(event) as T;
  } else if (ReservationRequest.kinds.contains(eventKind)) {
    return ReservationRequest.fromNostrEvent(event) as T;
  } else if (Review.kinds.contains(eventKind)) {
    return Review.fromNostrEvent(event) as T;
  }
  return event as T;
}
