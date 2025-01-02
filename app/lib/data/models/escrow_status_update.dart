import 'dart:convert';
import 'dart:core';

import 'package:dart_nostr/nostr/model/event/event.dart';

import 'event.dart';

class EscrowStatusUpdate extends Event {
  final String noteId;
  final String buyerPublicKey;
  final String sellerPublicKey;
  final String arbiterPublicKey;
  final double amount;
  final double forwarded;
  final double reversed;

  EscrowStatusUpdate(super.event,
      {required this.noteId,
      required this.forwarded,
      required this.reversed,
      required this.buyerPublicKey,
      required this.sellerPublicKey,
      required this.arbiterPublicKey,
      required this.amount});

  static fromNostrEvent(NostrEvent event) {
    Map json = jsonDecode(event.content!);

    return EscrowStatusUpdate(
      event,
      noteId: json["noteId"],
      buyerPublicKey: json["buyerPublicKey"],
      sellerPublicKey: json["sellerPublicKey"],
      arbiterPublicKey: json["arbiterPublicKey"],
      amount: double.parse(json["amount"].toString()),
      forwarded: double.parse(json["forwarded"].toString()),
      reversed: double.parse(json["reversed"].toString()),
    );
  }
}
