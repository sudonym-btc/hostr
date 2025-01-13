import 'dart:convert';
import 'dart:core';

import 'package:dart_nostr/dart_nostr.dart';
import 'package:hostr/config/main.dart';

import 'type_json_content.dart';

class Escrow extends JsonContentNostrEvent<EscrowContent> {
  static const List<int> kinds = [NOSTR_KIND_ESCROW];

  Escrow.fromNostrEvent(NostrEvent e)
      : super(
            parsedContent: EscrowContent.fromJson(json.decode(e.content!)),
            content: e.content,
            createdAt: e.createdAt,
            id: e.id,
            kind: e.kind,
            pubkey: e.pubkey,
            sig: e.sig,
            tags: e.tags);
}

class EscrowContent extends EventContent {
  final String pubkey;
  final int chainId;
  final Duration maxDuration;
  // final Price pricePercent;
  // final Price priceFlat;
  final EscrowType type;

  EscrowContent(
      {required this.pubkey,
      required this.chainId,
      required this.maxDuration,
      required this.type});

  @override
  Map<String, dynamic> toJson() {
    return {
      "pubkey": pubkey,
      "chainId": chainId,
      "maxDuration": maxDuration.inSeconds,
      // "pricePercent": pricePercent.toJson(),
      // "priceFlat": priceFlat.toJson(),
      "type": type.toString().split('.').last,
    };
  }

  static EscrowContent fromJson(Map<String, dynamic> json) {
    return EscrowContent(
      pubkey: json["pubkey"],
      chainId: json["chainId"],
      maxDuration: Duration(seconds: json["maxDuration"]),
      // pricePercent: Price.fromJson(json["pricePercent"]),
      // priceFlat: Price.fromJson(json["priceFlat"]),
      type: EscrowType.values
          .firstWhere((e) => e.toString() == 'EscrowType.${json["type"]}'),
    );
  }
}

enum EscrowType { ROOTSTOCK }
