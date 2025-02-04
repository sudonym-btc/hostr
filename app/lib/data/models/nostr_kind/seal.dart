import 'dart:convert';
import 'dart:core';

import 'package:hostr/config/main.dart';
import 'package:hostr/data/models/nostr_kind/event.dart';
import 'package:hostr/data/sources/nostr/nostr/nostr.service.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import 'type_parent.dart';

class Seal<T extends Event> extends ParentTypeNostrEvent {
  static const List<int> kinds = [NOSTR_KIND_SEAL];
  Seal.fromNostrEvent(Nip01Event e, KeyPair key, Uri? nwc)
      : super(
          e,
          child: parser(Nip01Event.fromJson(jsonDecode(e.content)), key, nwc),
        );

  @override
  Nip01Event toNostrEvent() {
    // TODO: implement toNostrEvent
    throw UnimplementedError();
  }
}
