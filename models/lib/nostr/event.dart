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

  /// Parse an amount tag encoded as `"decimalValue:tokenTagId"`.
  ///
  /// Format:
  /// - `"0.005:BTC"` → BTC Lightning (2 segments)
  /// - `"50.00:30:0xdAC17..."` → on-chain token (3 segments: value:chainId:address)
  ///
  /// [resolveDecimals] provides the decimal precision for on-chain tokens.
  /// If omitted, defaults to 18 for native (address(0)) and 6 for ERC-20.
  TokenAmount? getTagAmount(
    String key, {
    int Function(int chainId, String address)? resolveDecimals,
  }) {
    final v = getTagValue(key);
    if (v == null) return null;
    return _parseTokenAmountTag(v, resolveDecimals: resolveDecimals);
  }

  /// Parse price tags encoded as:
  /// - `["price", "decimalAmount:BTC:frequency"]` (3 segments – BTC denomination)
  /// - `["price", "decimalAmount:denomination:frequency"]` (3 segments – any denomination)
  ///
  /// Legacy 4-segment format `["price", "decimalAmount:chainId:address:frequency"]`
  /// is also supported for backward compatibility, mapping to denomination "BTC"
  /// for native tokens and the token's tagId otherwise.
  List<Price> getTagPrices({
    int Function(int chainId, String address)? resolveDecimals,
  }) {
    return tags
        .where((t) => t.isNotEmpty && t[0] == 'price')
        .map((t) {
          final raw = t[1];
          final parts = raw.split(':');

          // 3 segments: "amount:denomination:frequency"
          if (parts.length == 3) {
            final freq = Frequency.values.where((f) => f.name == parts[2]);
            if (freq.isEmpty) return null;
            final denomination = parts[1];
            // BTC denomination uses 8 decimals (satoshis) by default.
            // Other denominations are not yet defined; default to 8.
            final decimals = denomination == 'BTC' ? 8 : 8;
            return Price(
              amount: DenominatedAmount.fromDecimal(
                parts[0],
                denomination,
                decimals,
              ),
              frequency: freq.first,
            );
          }

          // Legacy 4 segments: "amount:chainId:address:frequency"
          if (parts.length == 4) {
            final chainId = int.tryParse(parts[1]);
            if (chainId == null) return null;
            final address = parts[2];
            final freq = Frequency.values.where((f) => f.name == parts[3]);
            if (freq.isEmpty) return null;
            final decimals = resolveDecimals != null
                ? resolveDecimals(chainId, address)
                : _defaultDecimals(address);
            // Map legacy on-chain token format to a denomination.
            final isNative = address.toLowerCase() ==
                '0x0000000000000000000000000000000000000000';
            final denomination = isNative ? 'BTC' : '$chainId:$address';
            return Price(
              amount: DenominatedAmount.fromDecimal(
                parts[0],
                denomination,
                decimals,
              ),
              frequency: freq.first,
            );
          }

          return null;
        })
        .whereType<Price>()
        .toList();
  }

  // ── Amenity read helpers ────────────────────────────────────────────

  /// Parse cancellation policy tags encoded as
  /// `["cancellationPolicy", "secondsBeforeStart", "refundFraction"]`.
  List<CancellationPolicy> getTagCancellationPolicies() {
    return tags
        .where((t) => t.length >= 3 && t[0] == 'cancellationPolicy')
        .map((t) {
          final secondsBeforeStart = int.tryParse(t[1]);
          final refundFraction = double.tryParse(t[2]);
          if (secondsBeforeStart == null || refundFraction == null) {
            return null;
          }
          return CancellationPolicy(
            durationBeforeStart: Duration(seconds: secondsBeforeStart),
            refundFraction: refundFraction,
          );
        })
        .whereType<CancellationPolicy>()
        .toList();
  }

  // ── Amenity read helpers ────────────────────────────────────────────

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

// ── Private tag parsing helpers ───────────────────────────────────────

/// Parse a token-amount string: `"value:BTC"` or `"value:chainId:address"`.
TokenAmount? _parseTokenAmountTag(
  String raw, {
  int Function(int chainId, String address)? resolveDecimals,
}) {
  final parts = raw.split(':');

  // 2 segments: "value:BTC"
  if (parts.length == 2 && parts[1] == 'BTC') {
    return TokenAmount.fromDecimal(parts[0], Token.btcLightning);
  }

  // 3 segments: "value:chainId:address"
  if (parts.length == 3) {
    final chainId = int.tryParse(parts[1]);
    if (chainId == null) return null;
    final address = parts[2];
    final decimals = resolveDecimals != null
        ? resolveDecimals(chainId, address)
        : _defaultDecimals(address);
    final token = Token(chainId: chainId, address: address, decimals: decimals);
    return TokenAmount.fromDecimal(parts[0], token);
  }

  return null;
}

/// Sensible default decimals when no registry is available.
int _defaultDecimals(String address) {
  const zeroAddress = '0x0000000000000000000000000000000000000000';
  return address.toLowerCase() == zeroAddress ? 18 : 6;
}
