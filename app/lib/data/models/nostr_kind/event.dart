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
    return Nip01Event(
        pubKey: nip01Event.pubKey,
        kind: nip01Event.kind,
        tags: nip01Event.tags,
        content: content);
  }

  String get content => nip01Event.content;
  String get anchor => nip01Event.getFirstTag('a')!;
}
