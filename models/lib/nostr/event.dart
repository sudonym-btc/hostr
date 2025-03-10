import 'dart:convert';

import 'package:ndk/ndk.dart';

abstract class Event {
  static List<int> kinds = [];
  Nip01Event nip01Event;

  Event(this.nip01Event);
  Event.fromNostrEvent({required this.nip01Event});
  Nip01Event toNostrEvent() {
    if (nip01Event.sig == '') {
      return Nip01Event(
          pubKey: nip01Event.pubKey,
          kind: nip01Event.kind,
          tags: nip01Event.tags,
          content: nip01Event.content);
    }
    return Nip01Event.fromJson({
      "id": nip01Event.id,
      "pubkey": nip01Event.pubKey,
      "kind": nip01Event.kind,
      "tags": nip01Event.tags,
      "content": content,
      "created_at": nip01Event.createdAt,
      "sig": nip01Event.sig
    });
  }

  Map<String, dynamic> toJson() {
    return toNostrEvent().toJson();
  }

  @override
  String toString() {
    return jsonEncode(toJson());
  }

  String get content => nip01Event.content;
  String get anchor => nip01Event.getFirstTag('a')!;
}
