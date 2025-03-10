import 'dart:core';

import '../nostr_kinds.dart';
import 'event.dart';

class Review extends Event {
  static const List<int> kinds = [NOSTR_KIND_REVIEW];

  Review.fromNostrEvent(super.e);
}
