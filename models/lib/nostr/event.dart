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

  Event.fromNostrEvent(
    Nip01Event e, {
    EventTagsParser<TagsType>? tagParser,
    List<List<String>> requiredTags = const [],
  })  : tagParser = tagParser ?? ((tags) => EventTags(tags) as TagsType),
        parsedTags = (tagParser ?? ((tags) => EventTags(tags) as TagsType))(
          requireRequiredTags(e, requiredTags).tags,
        ),
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
    required String pubKey,
    required int kind,
    required TagsType tags,
    required this.tagParser,
    required String content,
    String? sig,
    bool? validSig,
    String? id,
    int? createdAt,
  })  : parsedTags = tags,
        super(
          pubKey: pubKey,
          kind: kind,
          content: content,
          sig: sig,
          validSig: validSig,
          id: id,
          createdAt: createdAt ?? 0,
          tags: tags.tags,
        );

  @override
  String toString() {
    return jsonEncode(Nip01EventModel.fromEntity(this).toJson());
  }

  T signAs<T extends Event>(
    KeyPair key,
    T Function(Nip01Event signed) fromNostrEvent,
  ) {
    final id = Nip01Utils.calculateId(this);
    final sig = signSchnorr(privateKey: key.privateKey!, message: id);
    return fromNostrEvent(copyWith(id: id, sig: sig, validSig: true));
  }

  bool valid() {
    if (sig == null) return false;
    if (!Nip01Utils.isIdValid(this)) return false;
    return verifySchnorrSignatureSync(
      publicKey: pubKey,
      message: id,
      signature: sig!,
    );
  }

  Nip01EventModel get model => Nip01EventModel.fromEntity(this);

  String? get anchor => getDtag() == null ? null : '$kind:$pubKey:${getDtag()}';

  /// Encode this event as an `naddr` bech32 string (NIP-19).
  /// Only valid for addressable/replaceable events (kinds 30000-39999).
  /// Returns null if the event has no d-tag.
  String? naddr({List<String>? relays}) {
    final dTag = getDtag();
    if (dTag == null) return null;
    return Nip19.encodeNaddr(
      kind: kind,
      pubkey: pubKey,
      identifier: dTag,
      relays: relays,
    );
  }

  /// Encode this event as a `nostr:naddr1...` URI (NIP-21).
  /// Returns null if the event has no d-tag.
  String? nostrUri({List<String>? relays}) {
    final encoded = naddr(relays: relays);
    return encoded != null ? 'nostr:$encoded' : null;
  }
}

getKindFromAnchor(String anchor) {
  return int.parse(anchor.split(':')[0]);
}

getDTagFromAnchor(String anchor) {
  return anchor.split(':')[2];
}

getPubKeyFromAnchor(String anchor) {
  return anchor.split(':')[1];
}

/// Converts an anchor string (kind:pubkey:d-tag) to an naddr bech32 string.
/// Optionally includes relay hints for better discoverability.
String anchorToNaddr(String anchor, {List<String>? relays}) {
  final parts = anchor.split(':');
  return Nip19.encodeNaddr(
    kind: int.parse(parts[0]),
    pubkey: parts[1],
    identifier: parts[2],
    relays: relays,
  );
}

/// Converts an naddr bech32 string back to an anchor string (kind:pubkey:d-tag).
String naddrToAnchor(String naddrStr) {
  final naddr = Nip19.decodeNaddr(naddrStr);
  return '${naddr.kind}:${naddr.pubkey}:${naddr.identifier}';
}

bool hasRequiredTags(
  List<List<String>> tags,
  List<List<String>> required,
) {
  return required.where((t) => t.isNotEmpty).every((requiredTag) {
    return tags.any((tag) {
      if (tag.length < 2 || tag.length < requiredTag.length) return false;
      for (var i = 0; i < requiredTag.length; i++) {
        if (requiredTag[i].isNotEmpty && tag[i] != requiredTag[i]) {
          return false;
        }
      }
      return true;
    });
  });
}

Nip01Event requireRequiredTags(
  Nip01Event event,
  List<List<String>> requiredTags,
) {
  for (final required in requiredTags) {
    if (required.isEmpty) continue;
    final key = required.first;
    if (!hasRequiredTags(event.tags, [required])) {
      throw FormatException(
        'Malformed Nostr event kind=${event.kind} id=${event.id}: '
        'missing required tag "$key"',
      );
    }
  }
  return event;
}

class EventTags {
  final List<List<String>> tags;

  EventTags(this.tags);

  List<String> getTags(String key) {
    return tags
        .where((t) => t.length >= 2 && t.first == key)
        .map((t) => t[1])
        .toList();
  }

  /// Returns the value (2nd element) of the first tag matching [key]
  /// whose marker (4th element, index 3) equals [marker], or `null`.
  ///
  /// This follows the NIP-01 convention where position 3 is a relay hint
  /// and position 4 (index 3) carries an application-defined marker.
  String? getTagValueByMarker(String key, String marker) {
    for (final t in tags) {
      if (t.length >= 4 && t[0] == key && t[3] == marker) {
        return t[1];
      }
    }
    return null;
  }

  // ── Typed read helpers ──────────────────────────────────────────────

  /// First value for [key], or null if absent.
  String? getTagValue(String key) {
    final matches = getTags(key);
    return matches.isNotEmpty ? matches.first : null;
  }

  /// Parse a boolean tag (`"true"` / `"false"`).
  bool getTagBool(String key, {bool defaultValue = false}) {
    final v = getTagValue(key);
    if (v == null) return defaultValue;
    return v.toLowerCase() == 'true';
  }

  /// Parse an integer tag.
  int? getTagInt(String key) {
    final v = getTagValue(key);
    return v != null ? int.tryParse(v) : null;
  }

  /// Parse a denominated-amount tag encoded as
  /// `[key, amount, denomination, decimals]`.
  ///
  /// Returns `null` if no matching tag exists or if parsing fails.
  DenominatedAmount? getTagDenominatedAmount(String key) {
    final tag = tags.where((t) => t.length >= 4 && t[0] == key).firstOrNull;
    if (tag == null) return null;
    return DenominatedAmount.fromDecimal(
        tag[1], tag[2], int.tryParse(tag[3]) ?? 8);
  }

  /// Parse an enum tag by matching [T.name].
  T? getTagEnum<T extends Enum>(String key, List<T> values) {
    final v = getTagValue(key);
    if (v == null) return null;
    for (final e in values) {
      if (e.name == v) return e;
    }
    return null;
  }

  /// Parse an ISO-8601 datetime tag.
  DateTime? getTagDateTime(String key) {
    final v = getTagValue(key);
    return v != null ? DateTime.tryParse(v) : null;
  }

  /// Parse NIP-99 price tags:
  /// - Recurring: `["price", "amount", "currency", "frequency"]` (4 elements)
  /// - One-time:  `["price", "amount", "currency"]` (3 elements)
  List<Price> getTagPrices() {
    return tags
        .where((t) => t.length >= 3 && t[0] == 'price')
        .map((t) {
          final amount = t[1];
          final denomination = t[2];
          final freq = t.length >= 4 ? FrequencyNip99.fromNip99(t[3]) : null;
          final decimals = DenominatedAmount.decimalsFor(denomination);
          return Price(
            amount: DenominatedAmount.fromDecimal(
              amount,
              denomination,
              decimals,
            ),
            frequency: freq,
          );
        })
        .whereType<Price>()
        .toList();
  }

  // ── Cancellation policy helpers ──────────────────────────────────

  /// Parse field-labeled cancellation policy tags.
  List<CancellationPolicy> getTagCancellationPolicies() {
    return tags
        .where((t) => t.length >= 5 && t[0] == 'cancellationPolicy')
        .map((t) {
          final fields = <String, String>{};
          for (var i = 1; i + 1 < t.length; i += 2) {
            fields[t[i]] = t[i + 1];
          }
          final secondsBeforeStart = int.tryParse(
            fields['secondsBeforeStart'] ?? '',
          );
          final secondsAfterOrder = int.tryParse(
            fields['secondsAfterOrder'] ?? '',
          );
          final refundFraction = double.tryParse(
            fields['refundFraction'] ?? '',
          );
          if (refundFraction == null ||
              refundFraction < 0 ||
              refundFraction > 1 ||
              (secondsBeforeStart == null && secondsAfterOrder == null) ||
              (secondsBeforeStart != null && secondsBeforeStart < 0) ||
              (secondsAfterOrder != null && secondsAfterOrder < 0)) {
            return null;
          }
          return CancellationPolicy(
            durationBeforeStart: secondsBeforeStart == null
                ? null
                : Duration(seconds: secondsBeforeStart),
            durationAfterOrder: secondsAfterOrder == null
                ? null
                : Duration(seconds: secondsAfterOrder),
            refundFraction: refundFraction,
          );
        })
        .whereType<CancellationPolicy>()
        .toList();
  }

  // ── Specification read helpers ──────────────────────────────────────

  /// Whether an amenity tag exists for [name].
  bool hasAmenity(String name) {
    return tags.any((t) => t.length >= 2 && t[0] == 'amenity' && t[1] == name);
  }

  /// Read a numeric amenity value, defaulting to [defaultValue].
  int getAmenityInt(String name, {int defaultValue = 0}) {
    final tag = tags.cast<List<String>?>().firstWhere(
          (t) => t!.length >= 3 && t[0] == 'amenity' && t[1] == name,
          orElse: () => null,
        );
    return tag != null && tag.length >= 3
        ? int.tryParse(tag[2]) ?? defaultValue
        : defaultValue;
  }

  /// Whether a spec tag exists for [name] (checks both 'spec' and legacy 'amenity').
  bool hasSpec(String name) {
    return tags.any((t) =>
        t.length >= 2 && (t[0] == 'spec' || t[0] == 'amenity') && t[1] == name);
  }

  /// Read a valued spec, defaulting to [defaultValue] (checks both 'spec' and legacy 'amenity').
  int getSpecInt(String name, {int defaultValue = 0}) {
    final tag = tags.cast<List<String>?>().firstWhere(
          (t) =>
              t!.length >= 3 &&
              (t[0] == 'spec' || t[0] == 'amenity') &&
              t[1] == name,
          orElse: () => null,
        );
    return tag != null && tag.length >= 3
        ? int.tryParse(tag[2]) ?? defaultValue
        : defaultValue;
  }
}

mixin ReferencesListing<T extends ReferencesListing<T>> on EventTags {
  String? get listingAnchorOrNull => getTagValue(kListingRefTag);

  String get listingAnchor {
    final anchor = listingAnchorOrNull;
    if (anchor == null) {
      throw StateError('Missing listing reference tag "$kListingRefTag"');
    }
    return anchor;
  }

  T setListingAnchor(String? anchor) {
    if (anchor != null) {
      tags.add([kListingRefTag, anchor]);
    }
    return this as T;
  }
}

mixin ReferencesOrder<T extends ReferencesOrder<T>> on EventTags {
  String get orderAnchor {
    return getTags(kOrderRefTag).first;
  }

  T setOrderAnchor(String? anchor) {
    if (anchor != null) {
      tags.add([kOrderRefTag, anchor]);
    }
    return this as T;
  }
}
