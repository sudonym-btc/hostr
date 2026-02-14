import 'dart:convert';

import 'package:ndk/domain_layer/entities/nip_01_event.dart';
import 'package:ndk/ndk.dart';

import 'event.dart';
import 'serializable.dart';

abstract class JsonContentNostrEvent<ContentType extends EventContent>
    extends Event {
  late ContentType parsedContent;

  JsonContentNostrEvent(
      {required super.pubKey,
      required super.kind,
      required ContentType content,
      required super.tags,
      super.sig,
      super.id,
      super.createdAt})
      : parsedContent = content,
        super(content: content.toString());

  JsonContentNostrEvent.fromNostrEvent(Nip01Event e) : super.fromNostrEvent(e);
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
