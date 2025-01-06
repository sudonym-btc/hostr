import 'dart:core';

import 'package:dart_nostr/nostr/model/event/event.dart';

import 'event.dart';

class Zap extends Event {
  Zap({
    required event,
  }) : super(event);

  static fromNostrEvent(NostrEvent event) {
    return Zap(event: event);
  }
}
