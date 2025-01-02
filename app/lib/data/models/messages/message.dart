import 'dart:convert';
import 'dart:core';

import '../event.dart';

class MessageType extends Event {
  bool jsonUsed = false;
  Map<String, dynamic> json = {};

  MessageType.fromNostrEvent(super.e) {
    try {
      json = jsonDecode(event.content!);
      jsonUsed = true;
    } catch (e) {
      jsonUsed = false;
    }
  }
}
