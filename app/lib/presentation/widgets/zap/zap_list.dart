import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter/material.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';

import '../list.dart';
import 'zap_receipt.dart';

class ZapList extends StatelessWidget {
  final String pubkey;
  final String? eventId;
  // final String? originalEventId; @todo replaceable events
  const ZapList({super.key, required this.pubkey, this.eventId});

  @override
  Widget build(BuildContext context) {
    return ListWidget<Zap>(
        list: () => ListCubit(getIt<ZapRepository>())
          ..setFilter(NostrFilter(t: [
            'p',
            pubkey,
          ]))
          ..list(),
        emptyText: "No zaps yet",
        builder: (el) {
          return ZapReceipt(
            zap: el,
          );
        });
  }
}
