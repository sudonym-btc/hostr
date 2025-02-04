import 'dart:convert';
import 'dart:core';

import 'package:hostr/config/main.dart';

import 'type_json_content.dart';

class Escrow extends JsonContentNostrEvent<EscrowContent> {
  static const List<int> kinds = [NOSTR_KIND_ESCROW];

  Escrow.fromNostrEvent(super.e) {
    parsedContent = EscrowContent.fromJson(json.decode(nip01Event.content));
  }
}

class EscrowContent extends EventContent {
  final String pubkey;
  final String contractAddress;
  final int chainId;
  final Duration maxDuration;
  // final Price pricePercent;
  // final Price priceFlat;
  final EscrowType type;

  EscrowContent(
      {required this.pubkey,
      required this.contractAddress,
      required this.chainId,
      required this.maxDuration,
      required this.type});

  @override
  Map<String, dynamic> toJson() {
    return {
      "pubkey": pubkey,
      "contractAddress": contractAddress,
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
      contractAddress: json["contractAddress"],
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
