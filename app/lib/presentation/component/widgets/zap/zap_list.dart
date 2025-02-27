import 'package:flutter/material.dart';
import 'package:hostr/main.dart';

import '../ui/list.dart';

class ZapListWidget extends ListWidget {
  final String pubkey;
  final String? eventId;

  const ZapListWidget(
      {super.key, required this.pubkey, this.eventId, required super.builder});
  // final String? originalEventId; @todo replaceable events

  @override
  Widget build(BuildContext context) {
    // return BlocProvider<ListCubit<Review>>(
    //     create: (context) => ListCubit<ZapRequest>(
    //         kinds: Review.kinds, filter: Filter(aTags: [state.data!.anchor]))
    //       ..next(),
    //     child: ListWidget<Review>(builder: (el) {
    //       return ReviewListItem(
    //         review: el,
    //         // dateRange: searchController.state.dateRange,
    //       );
    //     }));
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
