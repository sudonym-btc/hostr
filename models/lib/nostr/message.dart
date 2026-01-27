import 'dart:convert';
import 'dart:core';

import 'package:ndk/ndk.dart';

import '../nostr_kinds.dart';
import '../nostr_parser.dart';
import 'event.dart';
import 'type_parent.dart';

class Message<T extends Event> extends ParentTypeNostrEvent {
  static const List<int> kinds = [NOSTR_KIND_DM];

  Message.fromNostrEvent(Nip01Event e, T? child)
      : super.fromNostrEvent(
          e,
          child: child,
        );

  factory Message.safeFromNostrEvent(Nip01Event e) {
    var child;
    try {
      child = parser(Nip01EventModel.fromJson(jsonDecode(e.content)));
    } catch (e) {
      print(e);
      // child = null;
    }
    return Message.fromNostrEvent(e, child);
  }
}
