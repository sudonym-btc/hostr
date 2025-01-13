import 'package:auto_route/auto_route.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/main.dart';
import 'package:hostr/router.dart';

import 'price_tag.dart';

class ListingListItemWidget extends StatelessWidget {
  final Listing listing;
  final DateTimeRange? dateRange;
  const ListingListItemWidget(
      {super.key, required this.listing, this.dateRange});

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () => AutoRouter.of(context).root.push(ListingRoute(
              a: listing.getTag('a').first.first,
              dateRangeStart: dateRange?.start != null
                  ? dateRange!.start.toIso8601String()
                  : null,
              dateRangeEnd: dateRange?.end != null
                  ? dateRange!.end.toIso8601String()
                  : null,
            )),
        child: CustomPadding(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            CarouselSlider(
              options: CarouselOptions(viewportFraction: 1, padEnds: false),
              items: listing.parsedContent.images.map((i) {
                return Builder(
                  builder: (BuildContext context) {
                    return ClipRRect(
                        borderRadius: BorderRadius.circular(8.0),
                        child: Image.network(
                          i,
                          width: MediaQuery.of(context).size.width,
                          height: MediaQuery.of(context)
                              .size
                              .height, // Match the height of the SizedBox
                          fit: BoxFit.cover,
                          alignment: Alignment.topLeft,
                        ));
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 8.0),

            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(listing.parsedContent.title.toString(),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8.0),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      listing.parsedContent.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Row(
                      children: [
                        PriceTagWidget(price: listing.parsedContent.price[0]),
                        BlocProvider(
                            create: (context) => FilterCubit()
                              ..updateFilter(NostrFilter(a: [listing.id!])),
                            child: Row(
                              children: [
                                BlocProvider(
                                  create: (context) =>
                                      CountCubit(kinds: Review.kinds),
                                  child:
                                      BlocBuilder<CountCubit, CountCubitState>(
                                    builder: (context, state) {
                                      return Text(" · ${state.count} reviews");
                                    },
                                  ),
                                ),
                                BlocProvider(
                                  create: (context) =>
                                      CountCubit(kinds: Reservation.kinds),
                                  child:
                                      BlocBuilder<CountCubit, CountCubitState>(
                                    builder: (context, state) {
                                      return Text(" · ${state.count} stays");
                                    },
                                  ),
                                ),
                              ],
                            )),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            // trailing: Icon(Icons.more_vert),
          ]),
        ));
  }
}
