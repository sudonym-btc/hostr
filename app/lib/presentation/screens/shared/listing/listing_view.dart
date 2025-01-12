import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/presentation/component/providers/nostr/listing.provider.dart';
import 'package:hostr/presentation/component/widgets/main.dart';
import 'package:hostr/presentation/screens/shared/listing/image_carousel.dart';

import 'reviews_reservations.dart';

class ListingView extends StatelessWidget {
  final String a;
  final DateTimeRange? dateRange;

  // ignore: use_key_in_widget_constructors
  ListingView(
      {@pathParam required this.a,
      @queryParam String? dateRangeStart,
      @queryParam String? dateRangeEnd})
      : dateRange = dateRangeStart != null && dateRangeEnd != null
            ? DateTimeRange(
                start: DateTime.parse(dateRangeStart),
                end: DateTime.parse(dateRangeEnd),
              )
            : null;

  @override
  Widget build(BuildContext context) {
    return ListingProvider(builder: (context, state) {
      if (state.data == null) {
        return Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      return Scaffold(
          bottomNavigationBar: BottomAppBar(
            shape: CircularNotchedRectangle(),
            child: CustomPadding(
                top: 0,
                bottom: 0,
                child: Reserve(listing: state.data!, dateRange: dateRange)),
          ),
          body: (state.data == null)
              ? Center(child: CircularProgressIndicator())
              : CustomScrollView(slivers: [
                  SliverAppBar(
                      stretch: true,
                      expandedHeight: MediaQuery.of(context).size.height / 4,
                      flexibleSpace: FlexibleSpaceBar(
                          background: ImageCarousel(
                        item: state.data!,
                      ))),
                  SliverList(
                      delegate: SliverChildListDelegate(
                    [
                      CustomPadding(
                          child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            state.data!.parsedContent.title,
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                          const SizedBox(height: 2.0),
                          Row(children: [
                            Text('hosted by'),
                            SizedBox(width: 8),
                            ProfileChip(id: state.data!.pubkey)
                          ]),
                          const SizedBox(height: 8.0),
                          ReviewsReservations(
                            a: a,
                          ),
                          const SizedBox(
                            height: 8,
                          ),
                          AmenityTags(
                              amenities: state.data!.parsedContent.amenities),
                          const SizedBox(height: 16),
                          Text(state.data!.parsedContent.description,
                              style: Theme.of(context).textTheme.bodyMedium),
                        ],
                      ))
                    ],
                  ))
                ]));
    });
  }
}

class Reserve extends StatelessWidget {
  final Listing listing;
  final DateTimeRange? dateRange;
  const Reserve({super.key, required this.listing, this.dateRange});

  @override
  Widget build(BuildContext context) {
    // if (dateRange == null) {
    //   return Container();
    // }

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
