import 'dart:convert';

import 'package:bolt11_decoder/bolt11_decoder.dart';
import 'package:flutter/material.dart';
import 'package:hostr/data/main.dart';

class ZapReceipt extends StatefulWidget {
  final Zap zap;
  const ZapReceipt({super.key, required this.zap});

  @override
  State<StatefulWidget> createState() => ZapReceiptState();
}

class ZapReceiptState extends State<ZapReceipt> {
  @override
  Widget build(BuildContext context) {
    var event = json.decode(
        widget.zap.event.tags!.firstWhere((t) => t[0] == 'description')[1]);

    var bolt11 = widget.zap.event.tags!.firstWhere((t) => t[0] == 'bolt11')[1];
    // @todo: move to zap parser
    Bolt11PaymentRequest paymentRequest = Bolt11PaymentRequest(bolt11);

    return Chip(
        label: Text('Zap Receipt ${paymentRequest.amount}'),
        avatar: Icon(Icons.flash_on));
  }
}
