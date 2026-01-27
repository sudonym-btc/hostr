import 'dart:convert';

import 'package:ndk/domain_layer/entities/nip_01_event.dart';

import 'event.dart';
import 'serializable.dart';

abstract class JsonContentNostrEvent<ContentType extends EventContent>
    extends Event {
  late ContentType parsedContent;

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
