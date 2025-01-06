import 'dart:convert';
import 'dart:core';

import 'package:dart_nostr/nostr/model/event/event.dart';

import 'message.dart';

class MessageType0 extends MessageType {
  int type = 0;
  late dynamic contact;
  late DateTime start;
  late DateTime end;

  @override
  MessageType0.fromNostrEvent(NostrEvent e) : super.fromNostrEvent(e) {
    Map json = jsonDecode(event.content!);
    end = DateTime.parse(json["end"]);
    start = DateTime.parse(json["start"]);
    contact = json["contact"];
    event = e;
  }
}
