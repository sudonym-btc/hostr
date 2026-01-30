import 'dart:convert';
import 'dart:core';

import 'package:ndk/ndk.dart';

import '../amount.dart';
import '../nostr_kinds.dart';
import 'type_json_content.dart';

class ReservationRequest
    extends JsonContentNostrEvent<ReservationRequestContent> {
  static const List<int> kinds = [NOSTR_KIND_RESERVATION_REQUEST];

  ReservationRequest.fromNostrEvent(Nip01Event e) : super.fromNostrEvent(e) {
    parsedContent = ReservationRequestContent.fromJson(json.decode(content));
  }
}

class ReservationRequestContent extends EventContent {
  final DateTime start;
  final DateTime end;
  final int quantity;
  final Amount amount;
  final String salt;

  ReservationRequestContent(
      {required this.start,
      required this.end,
      required this.quantity,
      required this.amount,
      required this.salt});

  @override
  Map<String, dynamic> toJson() {
    return {
      "start": start.toIso8601String(),
      "end": end.toIso8601String(),
      "quantity": quantity,
      "amount": amount.toJson(),
      "salt": salt,
    };
  }

  static ReservationRequestContent fromJson(Map<String, dynamic> json) {
    return ReservationRequestContent(
      start: DateTime.parse(json["start"]),
      end: DateTime.parse(json["end"]),
      quantity: json["quantity"],
      amount: Amount.fromJson(json["amount"]),
      salt: json["salt"],
    );
  }
}
