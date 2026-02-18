import 'dart:convert';

import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/ndk.dart';

import 'event.dart';
import 'serializable.dart';

typedef EventContentParser<ContentType extends EventContent> = ContentType
    Function(Map<String, dynamic> content);

abstract class JsonContentNostrEvent<ContentType extends EventContent,
    TagsType extends EventTags> extends Event<TagsType> {
  late ContentType parsedContent;
  final EventContentParser<ContentType> contentParser;

  JsonContentNostrEvent(
      {required super.pubKey,
      required super.kind,
      required ContentType content,
      required super.tagParser,
      required this.contentParser,
      required super.tags,
      super.sig,
      super.id,
      super.createdAt})
      : parsedContent = content,
        super(content: content.toString());

  JsonContentNostrEvent.fromNostrEvent(Nip01Event e,
      {required EventTagsParser<TagsType> tagParser,
      required this.contentParser})
      : parsedContent =
            contentParser(json.decode(e.content) as Map<String, dynamic>),
        super.fromNostrEvent(e, tagParser: tagParser);
}

class EventContent extends Serializable {
  @override
  toJson() {
    throw UnimplementedError();
  }

  static fromJson(Map<String, dynamic> json) {
    throw UnimplementedError();
  }

  @override
  String toString() {
    return json.encode(toJson());
  }
}
