import 'package:auto_route/auto_route.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/router.dart';

class ListingListItem extends StatelessWidget {
  final Listing listing;
  final DateTimeRange? dateRange;
  const ListingListItem({super.key, required this.listing, this.dateRange});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: ListTile(
        onTap: () => AutoRouter.of(context).root.push(ListingRoute(
              id: listing.id!,
              dateRangeStart: dateRange?.start != null
                  ? dateRange!.start.toIso8601String()
                  : null,
              dateRangeEnd: dateRange?.end != null
                  ? dateRange!.end.toIso8601String()
                  : null,
            )),
        leading: SizedBox(
            width: 120,
            child: CarouselSlider(
              options: CarouselOptions(viewportFraction: 1, padEnds: false),
              items: listing.parsedContent.images.map((i) {
                return Builder(
                  builder: (BuildContext context) {
                    return Image.network(i);
                  },
                );
              }).toList(),
            )),
        title: Text(listing.parsedContent.type.toString()),
        subtitle: Text(
          listing.parsedContent.description,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        trailing: Icon(Icons.more_vert),
      ),
    );
  }
}
