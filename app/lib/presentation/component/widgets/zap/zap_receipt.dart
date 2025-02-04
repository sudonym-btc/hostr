import 'package:flutter/material.dart';
import 'package:ndk/ndk.dart';

class ZapReceiptWidget extends StatefulWidget {
  final ZapReceipt zap;
  const ZapReceiptWidget({super.key, required this.zap});

  @override
  State<StatefulWidget> createState() => ZapReceiptState();
}

class ZapReceiptState extends State<ZapReceiptWidget> {
  @override
  Widget build(BuildContext context) {
    // var event = json.decode(
    //     widget.zap.event.tags!.firstWhere((t) => t[0] == 'description')[1]);

    // var bolt11 = widget.zap.event.tags!.firstWhere((t) => t[0] == 'bolt11')[1];
    // // @todo: move to zap parser
    // Bolt11PaymentRequest paymentRequest = Bolt11PaymentRequest(bolt11);

    return Chip(label: Text('Zap Receipt x'), avatar: Icon(Icons.flash_on));
  }
}
