import 'dart:convert';
import 'dart:core';

import 'message.dart';

class MessageType1 extends MessageType {
  int type = 1;
  late List<PaymentOptions> paymentOptions;

  @override
  MessageType1.fromNostrEvent(super.e) : super.fromNostrEvent() {
    Map json = jsonDecode(event.content!);
    type = json["type"];
    paymentOptions = json["paymentOptions"]
        .map((e) => PaymentOptions(e["type"], e["link"]))
        .toList();
  }
}

class PaymentOptions {
  String type;
  String link;
  PaymentOptions(this.type, this.link);
}
