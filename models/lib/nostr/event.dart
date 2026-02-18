import 'dart:convert';

import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

typedef EventTagsParser<TagsType extends EventTags> = TagsType Function(
    List<List<String>> tags);

abstract class Event<TagsType extends EventTags> extends Nip01Event {
  static List<int> kinds = [];
  late TagsType parsedTags;
  final EventTagsParser<TagsType> tagParser;

  Event.fromNostrEvent(Nip01Event e, {EventTagsParser<TagsType>? tagParser})
      : tagParser = tagParser ?? ((tags) => EventTags(tags) as TagsType),
        parsedTags =
            (tagParser ?? ((tags) => EventTags(tags) as TagsType))(e.tags),
        super(
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
    required TagsType tags,
    required this.tagParser,
    required super.content,
    super.sig,
    super.validSig,
    super.id,
    super.createdAt,
  })  : parsedTags = tags,
        super(tags: tags.tags);

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

class EventTags {
  final List<List<String>> tags;

  EventTags(this.tags);

  List<String> getTags(String key) {
    return tags.where((t) => t.first == key).map((t) => t[1]).toList();
  }
}

mixin ReferencesListing<T extends ReferencesListing<T>> on EventTags {
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

mixin ReferencesReservation<T extends ReferencesReservation<T>> on EventTags {
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

mixin ReferencesThread<T extends ReferencesThread<T>> on EventTags {
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

mixin CommitmentTag<T extends CommitmentTag<T>> on EventTags {
  String get commitmentHash {
    return getTags(kCommitmentHashTag).first;
  }

  T setCommitmentHash(String? hash) {
    if (hash != null) {
      tags.add([kCommitmentHashTag, hash]);
    }
    return this as T;
  }
}
