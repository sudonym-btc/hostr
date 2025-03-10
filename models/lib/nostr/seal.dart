import 'dart:convert';
import 'dart:core';

import 'package:models/nostr_parser.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import '../nostr_kinds.dart';
import 'event.dart';
import 'type_parent.dart';

class Seal<T extends Event> extends ParentTypeNostrEvent {
  static const List<int> kinds = [NOSTR_KIND_SEAL];
  Seal.fromNostrEvent(Nip01Event e, KeyPair key)
      : super(
          e,
          child: parser(Nip01Event.fromJson(jsonDecode(e.content)), key),
        );
}
