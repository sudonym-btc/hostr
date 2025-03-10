import 'dart:convert';
import 'dart:core';

import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import '../nostr_kinds.dart';
import '../nostr_parser.dart';
import 'event.dart';
import 'type_parent.dart';

class Message<T extends Event> extends ParentTypeNostrEvent {
  static const List<int> kinds = [NOSTR_KIND_DM];

  Message.fromNostrEvent(super.e, T? child, KeyPair key)
      : super(
          child: child,
        );

  factory Message.safeFromNostrEvent(Nip01Event e, KeyPair key) {
    var child;
    try {
      child = parser(Nip01Event.fromJson(jsonDecode(e.content)), key);
    } catch (e) {
      print(e);
      // child = null;
    }
    return Message.fromNostrEvent(e, child, key);
  }
}
