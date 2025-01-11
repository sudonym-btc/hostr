import 'dart:convert';
import 'dart:core';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/config/main.dart';

import '../event.dart';

class Reservation extends Event<ReservationContent> {
  static List<int> kinds = [NOSTR_KIND_RESERVATION];

  Reservation.fromNostrEvent(NostrEvent e)
      : super(
            parsedContent: ReservationContent.fromJson(json.decode(e.content!)),
            content: e.content,
            createdAt: e.createdAt,
            id: e.id,
            kind: e.kind,
            pubkey: e.pubkey,
            sig: e.sig,
            tags: e.tags);
}

class ReservationContent extends EventContent {
  final DateTime start;
  final DateTime end;

  ReservationContent({required this.start, required this.end});

  @override
  Map<String, dynamic> toJson() {
    return {
      "start": start.toIso8601String(),
      "end": end.toIso8601String(),
    };
  }

  static ReservationContent fromJson(Map<String, dynamic> json) {
    return ReservationContent(
      start: DateTime.parse(json["start"]),
      end: DateTime.parse(json["end"]),
    );
  }
}
