import 'dart:convert';

import 'package:dart_nostr/dart_nostr.dart';

abstract class Event<ContentType extends EventContent> extends NostrEvent {
  static List<int> kinds = [];
  final ContentType parsedContent;

  const Event(
      {required this.parsedContent,
      required super.content,
      required super.createdAt,
      required super.id,
      required super.kind,
      required super.pubkey,
      required super.sig,
      required super.tags});

  Iterable<List<dynamic>> getTags(String key) {
    return (tags ?? []).where((tag) => tag[0] == key);
  }
}

class EventContent {
  toJson() {
    throw UnimplementedError();
  }

  @override
  String toString() {
    return json.encode(toJson());
  }
}
