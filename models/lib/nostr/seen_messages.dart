import 'dart:core';

import 'package:ndk/ndk.dart';

import '../nostr_kinds.dart';
import 'event.dart';
import 'tag_builder.dart';

mixin SeenMessagesTagRead {
  EventTags get tagSource;

  String? get counterpartyPubKey => tagSource.getTagValue('p');
}

class SeenMessagesTags extends EventTags with SeenMessagesTagRead {
  SeenMessagesTags(super.tags);

  @override
  EventTags get tagSource => this;
}

class SeenMessages extends Event<SeenMessagesTags> with SeenMessagesTagRead {
  static const List<int> kinds = [kNostrKindSeenMessages];
  static final EventTagsParser<SeenMessagesTags> _tagParser =
      SeenMessagesTags.new;

  @override
  EventTags get tagSource => parsedTags;

  String get bloomFilter => content;
  String? get conversationId => getDtag();

  SeenMessages({
    required super.pubKey,
    required super.tags,
    required super.content,
    super.createdAt,
    super.id,
    super.sig,
  }) : super(
          kind: kNostrKindSeenMessages,
          tagParser: _tagParser,
        );

  SeenMessages.fromNostrEvent(Nip01Event e)
      : super.fromNostrEvent(e, tagParser: _tagParser);

  factory SeenMessages.create({
    required String pubKey,
    required String dTag,
    required String bloomFilter,
    String? counterpartyPubKey,
    int? createdAt,
    List<List<String>> extraTags = const [],
  }) {
    assert(dTag.isNotEmpty, 'dTag must not be empty');

    return SeenMessages(
      pubKey: pubKey,
      content: bloomFilter,
      createdAt: createdAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      tags: SeenMessagesTags(
        (TagBuilder()
              ..add('d', dTag)
              ..addOptional('p', counterpartyPubKey)
              ..addAll(extraTags))
            .build(),
      ),
    );
  }
}
