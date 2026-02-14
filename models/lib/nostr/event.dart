import 'dart:convert';

import 'package:models/main.dart';
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
}

getDTagFromAnchor(String anchor) {
  return anchor.split(':')[2];
}

getPubKeyFromAnchor(String anchor) {
  return anchor.split(':')[1];
}

bool hasRequiredTags(
  List<List<String>> tags,
  List<List<String>> required,
) {
  final requiredKeys = required.map((t) => t.first).toSet();
  final presentKeys = tags.map((t) => t.first).toSet();
  return requiredKeys.every(presentKeys.contains);
}

mixin ReferencesListing<T extends ReferencesListing<T>> on Event {
  String get listingAnchor {
    return getTags(kListingRefTag).first;
  }

  T setListingAnchor(String? anchor) {
    if (anchor != null) {
      tags.add([kListingRefTag, anchor]);
    }
    return this as T;
  }
}

mixin ReferencesReservation<T extends ReferencesReservation<T>> on Event {
  String get reservationAnchor {
    return getTags(kReservationRefTag).first;
  }

  T setReservationAnchor(String? anchor) {
    if (anchor != null) {
      tags.add([kReservationRefTag, anchor]);
    }
    return this as T;
  }
}

mixin ReferencesThread<T extends ReferencesThread<T>> on Event {
  String get threadAnchor {
    return getTags(kThreadRefTag).first;
  }

  T setThreadAnchor(String? anchor) {
    if (anchor != null) {
      tags.add([kThreadRefTag, anchor]);
    }
    return this as T;
  }
}
