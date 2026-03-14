import 'dart:core';

import 'package:ndk/ndk.dart';

import '../nostr_kinds.dart';
import 'event.dart';
import 'tag_builder.dart';

mixin SeenStatusTagRead {
  EventTags get tagSource;

  String? get counterpartyPubKey => tagSource.getTagValue('p');
  int? get seenUntil => tagSource.getTagInt('seen_until');
  DateTime? get seenUntilAt => seenUntil == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(seenUntil! * 1000, isUtc: true);
}

class SeenStatusTags extends EventTags with SeenStatusTagRead {
  SeenStatusTags(super.tags);

  @override
  EventTags get tagSource => this;
}

class SeenStatus extends Event<SeenStatusTags> with SeenStatusTagRead {
  static const List<int> kinds = [kNostrKindSeenStatus];
  static final EventTagsParser<SeenStatusTags> _tagParser = SeenStatusTags.new;

  @override
  EventTags get tagSource => parsedTags;

  SeenStatus({
    required super.pubKey,
    required super.tags,
    super.createdAt,
    super.id,
    super.sig,
  }) : super(
          kind: kNostrKindSeenStatus,
          tagParser: _tagParser,
          content: '',
        );

  SeenStatus.fromNostrEvent(Nip01Event e)
      : super.fromNostrEvent(e, tagParser: _tagParser);

  factory SeenStatus.create({
    required String pubKey,
    required String counterpartyPubKey,
    required int seenUntil,
    int? createdAt,
    List<List<String>> extraTags = const [],
  }) {
    assert(seenUntil >= 0, 'seenUntil must be a unix timestamp');

    return SeenStatus(
      pubKey: pubKey,
      createdAt: createdAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      tags: SeenStatusTags(
        (TagBuilder()
              ..add('p', counterpartyPubKey)
              ..addInt('seen_until', seenUntil)
              ..addAll(extraTags))
            .build(),
      ),
    );
  }
}
