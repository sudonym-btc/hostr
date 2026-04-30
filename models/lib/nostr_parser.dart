import 'package:ndk/ndk.dart';

import 'nostr/main.dart';

/// Receives a raw Nostr event and converts it into a model
T parser<T extends Nip01Event>(Nip01Event event) {
  int eventKind = event.kind;

  if (Reservation.kinds.contains(eventKind)) {
    return Reservation.fromNostrEvent(event) as T;
  } else if (ReservationTransition.kinds.contains(eventKind)) {
    return ReservationTransition.fromNostrEvent(event) as T;
  } else if (Message.kinds.contains(eventKind)) {
    return Message.safeParse(event) as T;
  } else if (ReceivedHeartbeat.kinds.contains(eventKind)) {
    return ReceivedHeartbeat.fromNostrEvent(event) as T;
  } else if (SeenStatus.kinds.contains(eventKind)) {
    return SeenStatus.fromNostrEvent(event) as T;
  } else if (TypingIndicator.kinds.contains(eventKind)) {
    return TypingIndicator.fromNostrEvent(event) as T;
  } else if (SeenMessages.kinds.contains(eventKind)) {
    return SeenMessages.fromNostrEvent(event) as T;
  } else if (EscrowServiceSelected.kinds.contains(eventKind)) {
    return EscrowServiceSelected.fromNostrEvent(event) as T;
  } else if (EscrowService.kinds.contains(eventKind)) {
    return EscrowService.fromNostrEvent(event) as T;
  } else if (EscrowMethod.kinds.contains(eventKind)) {
    return EscrowMethod.fromNostrEvent(event) as T;
  } else if (Listing.kinds.contains(eventKind)) {
    return Listing.fromNostrEvent(event) as T;
  } else if (Review.kinds.contains(eventKind)) {
    return Review.fromNostrEvent(event) as T;
  } else if (BadgeAward.kinds.contains(eventKind)) {
    return BadgeAward.fromNostrEvent(event) as T;
  } else if (BadgeDefinition.kinds.contains(eventKind)) {
    return BadgeDefinition.fromNostrEvent(event) as T;
  } else if (IdentityClaims.kinds.contains(eventKind)) {
    return IdentityClaims.fromNostrEvent(event) as T;
  } else if (ProfileMetadata.kinds.contains(eventKind)) {
    return ProfileMetadata.fromNostrEvent(event) as T;
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
