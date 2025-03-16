import 'package:flutter/material.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/zap/zap_receipt.dart';
import 'package:ndk/ndk.dart';

class ZapListWidget extends StatelessWidget {
  final String pubkey;
  final String? eventId;
  final Widget Function(ZapReceipt) builder;

  const ZapListWidget(
      {required this.pubkey, this.eventId, required this.builder});
  // final String? originalEventId; @todo replaceable events

  @override
  Widget build(BuildContext context) {
    return StreamBuilder(
        stream: getIt<Ndk>()
            .zaps
            .fetchZappedReceipts(pubKey: pubkey, eventId: eventId),
        builder: (context, snapshot) {
          print("Zaps snapshot: $snapshot");
          if (snapshot.hasData) {
            return ZapReceiptWidget(zap: snapshot.data!);
          } else {
            if (snapshot.hasError) {
              print("Zaps error: ${snapshot.error}");
            } else if (snapshot.connectionState == ConnectionState.done) {
              print("Zaps done");
              return Container();
            }
            return CircularProgressIndicator();
          }
        });
  }
}
