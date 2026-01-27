import 'dart:convert';
import 'dart:core';

import 'package:ndk/ndk.dart';

import '../nostr_kinds.dart';
import 'type_json_content.dart';

class Reservation extends JsonContentNostrEvent<ReservationContent> {
  static const List<int> kinds = [NOSTR_KIND_RESERVATION];

  Reservation.fromNostrEvent(Nip01Event e) : super.fromNostrEvent(e) {
    parsedContent = ReservationContent.fromJson(json.decode(content));
  }
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
