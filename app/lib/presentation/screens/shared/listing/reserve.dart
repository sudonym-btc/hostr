import 'package:flutter/material.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';

class Reserve extends StatelessWidget {
  final Listing listing;
  final DateTimeRange? dateRange;
  const Reserve({super.key, required this.listing, this.dateRange});

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      dateRange != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("\$${listing.cost(dateRange!)} total"),
                Text(
                    '${formatDate(dateRange!.start)} - ${formatDate(dateRange!.end)}')
              ],
            )
          : Text('Select dates'),
      FilledButton(
          onPressed: () {
            // var m = MessageType0.fromPartialData(
            //     start: searchController.state.filters
            //         .firstWhere((element) => element.key == 'start')
            //         .value,
            //     end: searchController.state.filters
            //         .firstWhere((element) => element.key == 'end')
            //         .value,
            //     hostPubKey: listing.nostrEvent.pubkey,
            //     listingId: listing.nostrEvent.id);
            // getIt<MessageRepository>().create(m);
          },
          child: Text('Reserve'))
    ]);
  }
}
