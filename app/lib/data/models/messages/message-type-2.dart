import 'dart:convert';
import 'dart:core';

import 'package:dart_nostr/dart_nostr.dart';

import 'message.dart';

class MessageType2 extends MessageType {
  int type = 2;
  late String status;

  @override
  MessageType2.fromNostrEvent(NostrEvent e) : super.fromNostrEvent(e) {
    Map json = jsonDecode(event.content!);
    event = e;
    status = json["status"];
  }
}
