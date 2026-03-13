import 'dart:core';

import 'package:ndk/ndk.dart';

import '../nostr_kinds.dart';
import 'event.dart';
import 'tag_builder.dart';

class ReceivedHeartbeatTags extends EventTags {
  ReceivedHeartbeatTags(super.tags);
}

class ReceivedHeartbeat extends Event<ReceivedHeartbeatTags> {
  static const List<int> kinds = [kNostrKindReceivedHeartbeat];
  static final EventTagsParser<ReceivedHeartbeatTags> _tagParser =
      ReceivedHeartbeatTags.new;

  DateTime get receivedAt =>
      DateTime.fromMillisecondsSinceEpoch(createdAt * 1000, isUtc: true);

  ReceivedHeartbeat({
    required super.pubKey,
    required super.tags,
    super.createdAt,
    super.id,
    super.sig,
  }) : super(
          kind: kNostrKindReceivedHeartbeat,
          tagParser: _tagParser,
          content: '',
        );

  ReceivedHeartbeat.fromNostrEvent(Nip01Event e)
      : super.fromNostrEvent(e, tagParser: _tagParser);

  factory ReceivedHeartbeat.create({
    required String pubKey,
    int? createdAt,
    List<List<String>> extraTags = const [],
  }) {
    return ReceivedHeartbeat(
      pubKey: pubKey,
      createdAt: createdAt ?? DateTime.now().millisecondsSinceEpoch ~/ 1000,
      tags: ReceivedHeartbeatTags((TagBuilder()..addAll(extraTags)).build()),
    );
  }
}
