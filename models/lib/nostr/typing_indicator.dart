import 'dart:core';

import 'package:ndk/ndk.dart';

import '../nostr_kinds.dart';
import 'event.dart';
import 'tag_builder.dart';

mixin TypingIndicatorTagRead {
  EventTags get tagSource;

  String? get room => tagSource.getTagValue('room');
  int? get expiration => tagSource.getTagInt('expiration');
  DateTime? get expirationAt => expiration == null
      ? null
      : DateTime.fromMillisecondsSinceEpoch(expiration! * 1000, isUtc: true);

  bool isExpiredAt(DateTime instant) {
    final expiresAt = expirationAt;
    if (expiresAt == null) return false;
    return !expiresAt.isAfter(instant.toUtc());
  }
}

class TypingIndicatorTags extends EventTags with TypingIndicatorTagRead {
  TypingIndicatorTags(super.tags);

  @override
  EventTags get tagSource => this;
}

class TypingIndicator extends Event<TypingIndicatorTags>
    with TypingIndicatorTagRead {
  static const List<int> kinds = [kNostrKindTypingIndicator];
  static final EventTagsParser<TypingIndicatorTags> _tagParser =
      TypingIndicatorTags.new;

  @override
  EventTags get tagSource => parsedTags;

  TypingIndicator({
    required super.pubKey,
    required super.tags,
    super.createdAt,
    super.id,
    super.sig,
  }) : super(
          kind: kNostrKindTypingIndicator,
          tagParser: _tagParser,
          content: '',
        );

  TypingIndicator.fromNostrEvent(Nip01Event e)
      : super.fromNostrEvent(e, tagParser: _tagParser);

  factory TypingIndicator.create({
    required String pubKey,
    required String room,
    required int expiration,
    int? createdAt,
    List<List<String>> extraTags = const [],
  }) {
    assert(room.isNotEmpty, 'room must not be empty');
    assert(expiration >= 0, 'expiration must be a unix timestamp');

    return TypingIndicator(
      pubKey: pubKey,
      createdAt: createdAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      tags: TypingIndicatorTags(
        (TagBuilder()
              ..add('room', room)
              ..addInt('expiration', expiration)
              ..addAll(extraTags))
            .build(),
      ),
    );
  }
}
