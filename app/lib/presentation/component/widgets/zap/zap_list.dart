import 'package:flutter/material.dart';

import '../ui/list.dart';

class ZapListWidget extends ListWidget {
  final String pubkey;
  final String? eventId;

  const ZapListWidget(
      {super.key, required this.pubkey, this.eventId, required super.builder});
  // final String? originalEventId; @todo replaceable events

  @override
  Widget build(BuildContext context) {
    return Container();
    // return ListWidget(
    //     // list: () => ListCubit(getIt<ZapRepository>())
    //     //   ..setFilter(NostrFilter(t: [
    //     //     'p',
    //     //     pubkey,
    //     //   ]))
    //     //   ..list(),
    //     // emptyText: "No zaps yet",
    //     builder: (el) {
    //   return ZapReceipt(
    //     zap: el,
    //   );
    // });
  }
}
