import 'dart:core';

import 'package:models/nostr/event.dart';
import 'package:ndk/ndk.dart';

import '../nostr_kinds.dart';
import 'type_json_content.dart';

class EscrowService
    extends JsonContentNostrEvent<EscrowServiceContent, EventTags> {
  static const List<int> kinds = [kNostrKindEscrowService];
  static final EventTagsParser<EventTags> _tagParser = EventTags.new;
  static final EventContentParser<EscrowServiceContent> _contentParser =
      EscrowServiceContent.fromJson;

  static const List<List<String>> requiredTags = [];

  EscrowService(
      {required super.pubKey,
      required super.tags,
      required super.content,
      super.createdAt,
      super.id,
      super.sig})
      : super(
            kind: kNostrKindEscrowService,
            tagParser: _tagParser,
            contentParser: _contentParser);

  EscrowService.fromNostrEvent(Nip01Event e)
      : super.fromNostrEvent(
          e,
          tagParser: _tagParser,
          contentParser: _contentParser,
        );
}

class EscrowServiceContent extends EventContent {
  final String pubkey;
  final String evmAddress;
  final String contractAddress;
  final String contractBytecodeHash;
  final int chainId;
  final Duration maxDuration;
  final EscrowType type;

  EscrowServiceContent(
      {required this.pubkey,
      required this.evmAddress,
      required this.contractAddress,
      required this.contractBytecodeHash,
      required this.chainId,
      required this.maxDuration,
      required this.type});

  @override
  Map<String, dynamic> toJson() {
    return {
      "pubkey": pubkey,
      "evmAddress": evmAddress,
      "contractAddress": contractAddress,
      "contractBytecodeHash": contractBytecodeHash,
      "chainId": chainId,
      "maxDuration": maxDuration.inSeconds,
      "type": type.toString().split('.').last,
    };
  }

  static EscrowServiceContent fromJson(Map<String, dynamic> json) {
    return EscrowServiceContent(
      pubkey: json["pubkey"],
      evmAddress: json["evmAddress"],
      contractAddress: json["contractAddress"],
      contractBytecodeHash: json["contractBytecodeHash"],
      chainId: json["chainId"],
      maxDuration: Duration(seconds: json["maxDuration"]),
      type: EscrowType.values
          .firstWhere((e) => e.toString() == 'EscrowType.${json["type"]}'),
    );
  }
}

enum EscrowType { EVM }

enum ChainIds {
  Rootstock(30),
  RootstockRegtest(33);

  final int value;
  const ChainIds(this.value);
}
