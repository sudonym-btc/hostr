import 'dart:convert';
import 'dart:core';

import 'package:ndk/ndk.dart';

import '../nostr_kinds.dart';
import '../nostr_parser.dart';
import 'event.dart';
import 'type_parent.dart';

class Message<T extends Event> extends ParentTypeNostrEvent
    with ReferencesThread<Message<T>> {
  static const List<int> kinds = [kNostrKindDM];
  static const requiredTags = [
    [kThreadRefTag],
  ];

  Message(
      {required super.pubKey,
      required super.tags,
      super.child,
      super.content,
      super.createdAt,
      super.id,
      super.sig})
      : super(
          kind: kNostrKindDM,
        );

  Message.fromNostrEvent(Nip01Event e, T? child)
      : assert(hasRequiredTags(e.tags, Message.requiredTags)),
        super.fromNostrEvent(
          e,
          child: child,
        );

  factory Message.safeFromNostrEvent(Nip01Event e) {
    var child;
    try {
      child = parser(Nip01EventModel.fromJson(jsonDecode(e.content)));
    } catch (e) {
      // Only sometimes is the message content meant to be of JSON type
      // print(e);
      // print('error parsing message child event');
      child = null;
    }
    return Message.fromNostrEvent(e, child);
  }
}
