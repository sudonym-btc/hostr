import 'package:ndk/ndk.dart';

import 'nostr/main.dart';

/// Receives a raw Nostr event and converts it into a model
T parser<T extends Nip01Event>(Nip01Event event) {
  int eventKind = event.kind;

  // print('eventKind: $eventKind, ${T.toString()} should be returned, $event ');
  try {
    if (Reservation.kinds.contains(eventKind)) {
      return Reservation.fromNostrEvent(event) as T;
    } else if (Message.kinds.contains(eventKind)) {
      return Message.safeFromNostrEvent(event) as T;
    } else if (Escrow.kinds.contains(eventKind)) {
      return Escrow.fromNostrEvent(event) as T;
    } else if (Listing.kinds.contains(eventKind)) {
      return Listing.fromNostrEvent(event) as T;
    } else if (ReservationRequest.kinds.contains(eventKind)) {
      return ReservationRequest.fromNostrEvent(event) as T;
    } else if (Review.kinds.contains(eventKind)) {
      return Review.fromNostrEvent(event) as T;
    } else if (BadgeAward.kinds.contains(eventKind)) {
      return BadgeAward.fromNostrEvent(event) as T;
    } else if (BadgeDefinition.kinds.contains(eventKind)) {
      return BadgeDefinition.fromNostrEvent(event) as T;
    }
  } catch (e) {
    // If parsing fails, return the raw event
    return event as T;
  }
  return event as T;
}

Future<T> parserWithGiftWrap<T extends Nip01Event>(
    Nip01Event event, Ndk ndk) async {
  int eventKind = event.kind;

  if (eventKind == GiftWrap.kGiftWrapEventkind) {
    final unwrappedEvent = await ndk.giftWrap.fromGiftWrap(giftWrap: event);
    return parser<T>(unwrappedEvent);
  }
  return parser(event) as T;
}
