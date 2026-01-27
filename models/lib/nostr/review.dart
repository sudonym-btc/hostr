import 'dart:core';

import 'package:ndk/domain_layer/entities/nip_01_event.dart';

import '../nostr_kinds.dart';
import 'event.dart';

class Review extends Event {
  static const List<int> kinds = [NOSTR_KIND_REVIEW];

  Review.fromNostrEvent(Nip01Event e) : super.fromNostrEvent(e);
}
