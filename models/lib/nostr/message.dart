import 'dart:convert';
import 'dart:core';

import 'package:models/nostr/reservation_request.dart';
import 'package:ndk/ndk.dart';

import '../nostr_kinds.dart';
import '../nostr_parser.dart';
import 'event.dart';
import 'type_parent.dart';

class Message<T extends Event> extends ParentTypeNostrEvent {
  static const List<int> kinds = [NOSTR_KIND_DM];

  Message(
      {required super.pubKey,
      required super.tags,
      super.child,
      super.content,
      super.createdAt,
      super.id,
      super.sig})
      : super(
          kind: NOSTR_KIND_DM,
        );

  String? get reservationRequestAnchor {
    return getATagForKind(ReservationRequest.kinds[0]);
  }

  set reservationRequestAnchor(String? anchor) {
    if (anchor == null) return;
    tags.add(['a', anchor]);
  }

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
      // Only sometimes is the message content meant to be of JSON type
      // print(e);
      // print('error parsing message child event');
      child = null;
    }
    return Message.fromNostrEvent(e, child);
  }
}
