import 'dart:convert';

import 'package:dart_nostr/dart_nostr.dart';

abstract class Event extends NostrEvent {
  static List<int> kinds = [];

  const Event(
      {required super.content,
      required super.createdAt,
      required super.id,
      required super.kind,
      required super.pubkey,
      required super.sig,
      required super.tags});

  Iterable<List<dynamic>> getTags(String key) {
    return (tags ?? []).where((tag) => tag[0] == key).map((tag) => [tag[1]]);
  }

  /// Overrides Equatable's to string
  /// TODO check if this causes issues
  @override
  toString() {
    return jsonEncode(toMap());
  }
}
