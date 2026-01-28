import 'package:flutter/material.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/payments/constants.dart';
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
    if (widget.zap.sender == null) {
      return Chip(
        shape: StadiumBorder(),
        label: Text(
          formatAmount(
            Amount(
              currency: Currency.BTC,
              value: (widget.zap.amountSats! * btcSatoshiFactor).toDouble(),
            ),
          ),
        ),
        avatar: Icon(Icons.flash_on),
      );
    }
    return ProfileProvider(
      pubkey: widget.zap.sender!,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.active) {
          return Container();
        }
        return Chip(
          shape: StadiumBorder(),
          label: Text(
            formatAmount(
              Amount(
                currency: Currency.BTC,
                value: (widget.zap.amountSats! / btcSatoshiFactor).toDouble(),
              ),
            ),
          ),
          avatar: snapshot.data?.picture != null
              ? CircleAvatar(
                  backgroundImage: NetworkImage(snapshot.data!.picture!),
                )
              : CircleAvatar(backgroundColor: Colors.grey),
        );
      },
    );
  }
}
