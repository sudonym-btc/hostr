import 'package:ndk/ndk.dart';

import 'nostr/main.dart';

/// Receives a raw Nostr event and converts it into a model.
/// Returns null if parsing fails, allowing callers to skip malformed events
/// instead of crashing the stream.
T? safeParser<T extends Nip01Event>(Nip01Event event) {
  try {
    return parser<T>(event);
  } catch (e) {
    print('Skipping malformed event ${event.id} (kind ${event.kind}): $e');
    return null;
  }
}

/// Receives a raw Nostr event and converts it into a model
T parser<T extends Nip01Event>(Nip01Event event) {
  int eventKind = event.kind;

  // print('eventKind: $eventKind, ${T.toString()} should be returned, $event ');
  try {
    if (Reservation.kinds.contains(eventKind)) {
      return Reservation.fromNostrEvent(event) as T;
    } else if (Message.kinds.contains(eventKind)) {
      return Message.safeFromNostrEvent(event) as T;
    } else if (EscrowServiceSelected.kinds.contains(eventKind)) {
      return EscrowServiceSelected.fromNostrEvent(event) as T;
    } else if (EscrowService.kinds.contains(eventKind)) {
      return EscrowService.fromNostrEvent(event) as T;
    } else if (EscrowTrust.kinds.contains(eventKind)) {
      return EscrowTrust.fromNostrEvent(event) as T;
    } else if (EscrowMethod.kinds.contains(eventKind)) {
      return EscrowMethod.fromNostrEvent(event) as T;
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
    } else if (ProfileMetadata.kinds.contains(eventKind)) {
      return ProfileMetadata.fromNostrEvent(event) as T;
    }
  } catch (e) {
    print(event);
    print('Error parsing event kind $eventKind: $e');
    rethrow;
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

/// Like [parserWithGiftWrap] but returns null instead of throwing on
/// malformed events, allowing callers to filter nulls and keep the stream
/// alive.
Future<T?> safeParserWithGiftWrap<T extends Nip01Event>(
    Nip01Event event, Ndk ndk) async {
  try {
    return await parserWithGiftWrap<T>(event, ndk);
  } catch (e) {
    print('Skipping malformed event ${event.id} (kind ${event.kind}): $e');
    return null;
  }
}
