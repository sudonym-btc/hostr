import 'dart:convert';
import 'dart:core';

import 'package:hostr/config/main.dart';

import '../amount.dart';
import 'type_json_content.dart';

class ReservationRequest
    extends JsonContentNostrEvent<ReservationRequestContent> {
  static const List<int> kinds = [NOSTR_KIND_RESERVATION_REQUEST];

  ReservationRequest.fromNostrEvent(super.e) {
    parsedContent =
        ReservationRequestContent.fromJson(json.decode(nip01Event.content));
  }
}

class ReservationRequestContent extends EventContent {
  final DateTime start;
  final DateTime end;
  final int quantity;
  final Amount amount;
  final String commitmentHash;
  final String commitmentHashPreimageEnc;

  ReservationRequestContent(
      {required this.start,
      required this.end,
      required this.quantity,
      required this.amount,
      required this.commitmentHash,
      required this.commitmentHashPreimageEnc});

  @override
  Map<String, dynamic> toJson() {
    return {
      "start": start.toIso8601String(),
      "end": end.toIso8601String(),
      "quantity": quantity,
      "amount": amount.toJson(),
      "commitmentHash": commitmentHash,
      "commitmentHashPreimageEnc": commitmentHashPreimageEnc,
    };
  }

  static ReservationRequestContent fromJson(Map<String, dynamic> json) {
    return ReservationRequestContent(
      start: DateTime.parse(json["start"]),
      end: DateTime.parse(json["end"]),
      quantity: json["quantity"],
      amount: Amount.fromJson(json["amount"]),
      commitmentHash: json["commitmentHash"],
      commitmentHashPreimageEnc: json["commitmentHashPreimageEnc"],
    );
  }
}
