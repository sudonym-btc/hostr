import 'dart:core';

import 'package:hostr/config/main.dart';
import 'package:ndk/ndk.dart';

import 'event.dart';

class Review extends Event {
  static const List<int> kinds = [NOSTR_KIND_REVIEW];

  Review.fromNostrEvent(Nip01Event e) : super(e);
}
