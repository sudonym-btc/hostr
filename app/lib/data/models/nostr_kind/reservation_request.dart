import 'dart:convert';
import 'dart:core';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/config/main.dart';

import '../amount.dart';
import 'type_json_content.dart';

class ReservationRequest
    extends JsonContentNostrEvent<ReservationRequestContent> {
  static List<int> kinds = [NOSTR_KIND_RESERVATION_REQUEST];

  ReservationRequest.fromNostrEvent(NostrEvent e)
      : super(
            parsedContent:
                ReservationRequestContent.fromJson(json.decode(e.content!)),
            content: e.content,
            createdAt: e.createdAt,
            id: e.id,
            kind: e.kind,
            pubkey: e.pubkey,
            sig: e.sig,
            tags: e.tags);
}

class ReservationRequestContent extends EventContent {
  final DateTime start;
  final DateTime end;
  final int quantity;
  final Amount amount;

  ReservationRequestContent(
      {required this.start,
      required this.end,
      required this.quantity,
      required this.amount});

  @override
  Map<String, dynamic> toJson() {
    return {
      "start": start.toIso8601String(),
      "end": end.toIso8601String(),
      "quantity": quantity,
      "amount": amount.toJson(),
    };
  }

  static ReservationRequestContent fromJson(Map<String, dynamic> json) {
    return ReservationRequestContent(
      start: DateTime.parse(json["start"]),
      end: DateTime.parse(json["end"]),
      quantity: json["quantity"],
      amount: Amount.fromJson(json["amount"]),
    );
  }
}
