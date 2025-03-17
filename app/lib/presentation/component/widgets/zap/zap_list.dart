import 'package:flutter/material.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/zap/zap_receipt.dart';
import 'package:ndk/ndk.dart';

class ZapListWidget extends StatefulWidget {
  final String pubkey;
  final String? eventId;
  final Widget Function(ZapReceipt) builder;

  const ZapListWidget(
      {required this.pubkey, this.eventId, required this.builder});
  // final String? originalEventId; @todo replaceable events

  @override
  _ZapListWidgetState createState() => _ZapListWidgetState();
}

class _ZapListWidgetState extends State<ZapListWidget> {
  late final Stream<ZapReceipt> zapStream;

  @override
  void initState() {
    super.initState();
    zapStream = getIt<Ndk>()
        .zaps
        .fetchZappedReceipts(pubKey: widget.pubkey, eventId: widget.eventId);
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: zapStream,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            return ZapReceiptWidget(zap: snapshot.data!);
          } else {
            if (snapshot.hasError) {
              print("Zaps error: ${snapshot.error}");
            } else if (snapshot.connectionState == ConnectionState.done) {
              return Container();
            }
            return CircularProgressIndicator();
          }
        });
  }
}
