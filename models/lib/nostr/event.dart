import 'dart:convert';

import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

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
    super.sig,
    super.validSig,
    super.id,
    super.createdAt,
  });

  @override
  String toString() {
    return jsonEncode(Nip01EventModel.fromEntity(this).toJson());
  }

  T signAs<T extends Event>(
    KeyPair key,
    T Function(Nip01Event signed) fromNostrEvent,
  ) {
    final signed = Nip01Utils.signWithPrivateKey(
      event: this,
      privateKey: key.privateKey!,
    );
    return fromNostrEvent(signed);
  }

  Nip01EventModel get model => Nip01EventModel.fromEntity(this);

  String? get anchor => getDtag() == null ? null : '$kind:$pubKey:${getDtag()}';

  String getDTagForKind(int kind) {
    return Event.getDFromATag(getATagForKind(kind));
  }

  static getDFromATag(String a) {
    return a.split(':')[2];
  }

  String getATagForKind(int kind) {
    return getTags('a').where((el) {
      return int.parse(el.split(':')[0]) == kind;
    }).first;
  }
}
