import 'dart:convert';
import 'dart:core';

import 'package:dart_nostr/nostr/model/event/event.dart';

import 'event.dart';

class Booking extends Event {
  DateTime start;
  DateTime end;

  Booking({
    required event,
    required this.start,
    required this.end,
  }) : super(event);

  static fromNostrEvent(NostrEvent event) {
    Map json = jsonDecode(event.content!);

    return Booking(
        event: event,
        start: DateTime.parse(json["start"]),
        end: DateTime.parse(json["end"]));
  }
}
