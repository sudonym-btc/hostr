import 'dart:convert';

import 'package:ndk/ndk.dart';

abstract class Event extends Nip01Event {
  static List<int> kinds = [];

  Event.fromNostrEvent(Nip01Event e)
      : super(
            id: e.id,
            pubKey: e.pubKey,
            kind: e.kind,
            tags: e.tags,
            content: e.content,
            createdAt: e.createdAt,
            validSig: e.validSig,
            sig: e.sig);

  Event({
    required super.pubKey,
    required super.kind,
    required super.tags,
    required super.content,
    required super.sig,
    required super.validSig,
  });

  @override
  String toString() {
    return jsonEncode(Nip01EventModel.fromEntity(this).toJson());
  }

  String get anchor => getFirstTag('a')!;
}
