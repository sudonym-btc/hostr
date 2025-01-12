import 'dart:convert';

import 'event.dart';
import 'serializable.dart';

abstract class JsonContentNostrEvent<ContentType extends Serializable>
    extends Event {
  final ContentType parsedContent;

  const JsonContentNostrEvent(
      {required this.parsedContent,
      required super.content,
      required super.createdAt,
      required super.id,
      required super.kind,
      required super.pubkey,
      required super.sig,
      required super.tags});
}

class EventContent extends Serializable {
  toJson() {
    throw UnimplementedError();
  }

  static fromJson(Map<String, dynamic> json) {
    throw UnimplementedError();
  }

  @override
  String toString() {
    return json.encode(toJson());
  }
}
