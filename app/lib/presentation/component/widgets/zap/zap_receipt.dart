import 'package:flutter/material.dart';
import 'package:hostr/logic/services/swap.dart';
import 'package:hostr/presentation/component/providers/main.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

import '../amount/amount_input.dart';

class ZapReceiptWidget extends StatefulWidget {
  final ZapReceipt zap;
  const ZapReceiptWidget({super.key, required this.zap});

  @override
  State<StatefulWidget> createState() => ZapReceiptState();
}

class ZapReceiptState extends State<ZapReceiptWidget> {
  @override
  Widget build(BuildContext context) {
    print('Zap:' + widget.zap.toString());
    if (widget.zap.sender == null) {
      return Chip(
          shape: StadiumBorder(),
          label: Text(formatAmount(Amount(
              currency: Currency.BTC,
              value: (widget.zap.amountSats! * btcSatoshiFactor).toDouble()))),
          avatar: Icon(Icons.flash_on));
    }
    return ProfileProvider(
      pubkey: widget.zap.sender!,
      builder: (context, metadata) {
        if (metadata == null) return Container();
        return Chip(
          shape: StadiumBorder(),
          label: Text(formatAmount(Amount(
              currency: Currency.BTC,
              value: (widget.zap.amountSats! / btcSatoshiFactor).toDouble()))),
          avatar: metadata?.picture != null
              ? CircleAvatar(
                  backgroundImage: NetworkImage(metadata!.picture!),
                )
              : CircleAvatar(
                  backgroundColor: Colors.grey,
                ),
        );
      },
    );
  }
}
