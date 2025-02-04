import 'dart:convert';

import 'event.dart';
import 'serializable.dart';

abstract class JsonContentNostrEvent<ContentType extends EventContent>
    extends Event {
  late ContentType parsedContent;

  JsonContentNostrEvent(super.nip01Event);

  @override
  String get content => parsedContent.toString();
}

class EventContent extends Serializable {
  @override
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
