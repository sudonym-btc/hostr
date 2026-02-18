import 'dart:convert';
import 'dart:core';

import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

class EscrowServiceSelectedTags extends EventTags
    with ReferencesListing<EscrowServiceSelectedTags> {
  EscrowServiceSelectedTags(super.tags);
}

class EscrowServiceSelected extends JsonContentNostrEvent<
    EscrowServiceSelectedContent, EscrowServiceSelectedTags> {
  static const List<int> kinds = [kNostrKindEscrowServiceSelected];
  static final EventTagsParser<EscrowServiceSelectedTags> _tagParser =
      EscrowServiceSelectedTags.new;
  static final EventContentParser<EscrowServiceSelectedContent> _contentParser =
      EscrowServiceSelectedContent.fromJson;
  static const requiredTags = [];
  EscrowServiceSelected(
      {required super.pubKey,
      required super.tags,
      required super.content,
      super.createdAt,
      super.id,
      super.sig})
      : super(
            kind: kNostrKindEscrowServiceSelected,
            tagParser: _tagParser,
            contentParser: _contentParser);

  EscrowServiceSelected.fromNostrEvent(Nip01Event e)
      : super.fromNostrEvent(
          e,
          tagParser: _tagParser,
          contentParser: _contentParser,
        );
}

class EscrowServiceSelectedContent extends EventContent {
  final EscrowService service;
  final EscrowTrust sellerTrusts;
  final EscrowMethod sellerMethods;

  EscrowServiceSelectedContent({
    required this.service,
    required this.sellerTrusts,
    required this.sellerMethods,
  });

  @override
  Map<String, dynamic> toJson() {
    return {
      "service": service.toString(),
      "sellerTrusts": sellerTrusts.toString(),
      "sellerMethods": sellerMethods.toString(),
    };
  }

  static EscrowServiceSelectedContent fromJson(Map<String, dynamic> json) {
    return EscrowServiceSelectedContent(
      service: EscrowService.fromNostrEvent(
          Nip01EventModel.fromJson(jsonDecode(json['service']))),
      sellerMethods: EscrowMethod.fromNostrEvent(
          Nip01EventModel.fromJson(jsonDecode(json['sellerMethods']))),
      sellerTrusts: EscrowTrust.fromNostrEvent(
          Nip01EventModel.fromJson(jsonDecode(json['sellerTrusts']))),
    );
  }
}
