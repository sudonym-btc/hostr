import 'dart:convert';
import 'dart:core';

import 'package:ndk/ndk.dart';

import '../nostr_kinds.dart';
import 'type_json_content.dart';

class Escrow extends JsonContentNostrEvent<EscrowContent> {
  static const List<int> kinds = [NOSTR_KIND_ESCROW];

  Escrow.fromNostrEvent(Nip01Event e) : super.fromNostrEvent(e) {
    parsedContent = EscrowContent.fromJson(json.decode(content));
  }
}

class EscrowContent extends EventContent {
  final String pubkey;
  final String contractAddress;
  final int chainId;
  final Duration maxDuration;
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
      "type": type.toString().split('.').last,
    };
  }

  static EscrowContent fromJson(Map<String, dynamic> json) {
    return EscrowContent(
      pubkey: json["pubkey"],
      contractAddress: json["contractAddress"],
      chainId: json["chainId"],
      maxDuration: Duration(seconds: json["maxDuration"]),
      type: EscrowType.values
          .firstWhere((e) => e.toString() == 'EscrowType.${json["type"]}'),
    );
  }
}

enum EscrowType { EVM }

enum ChainIds {
  Rootstock(30);

  final int value;
  const ChainIds(this.value);
}
