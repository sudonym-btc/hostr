import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/main.dart';
import 'package:hostr/presentation/component/widgets/listing/listing_carousel.dart';
import 'package:hostr/router.dart';
import 'package:models/main.dart';

import 'price_tag.dart';

class ListingListItemWidget extends StatefulWidget {
  final Listing listing;
  final DateTimeRange? dateRange;
  final bool showPrice;
  final bool showFeedback;
  final bool smallImage;
  final WidgetBuilder? bottom;
  const ListingListItemWidget({
    super.key,
    required this.listing,
    this.dateRange,
    this.showPrice = true,
    this.showFeedback = true,
    this.smallImage = false,
    this.bottom,
  });

  @override
  State createState() => ListingListItemWidgetState();
}

class ListingListItemWidgetState extends State<ListingListItemWidget> {
  ListingListItemWidgetState();

  @override
  initState() {
    super.initState();
    // Preload images
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (!mounted) return; // Check if the widget is still mounted
    //   for (var imageUrl in widget.listing.parsedContent.images) {
    //     precacheImage(NetworkImage(imageUrl), context);
    //   }
    // });
  }

  Widget getImage() {
    return SmallListingCarousel(height: 200, listing: widget.listing);
  }

  Widget getDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.listing.parsedContent.title.toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: kDefaultPadding / 6),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.listing.parsedContent.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: kDefaultPadding / 6),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.max,
              children: [
                if (widget.showPrice) ...[
                  PriceTagWidget(price: widget.listing.parsedContent.price[0]),
                  Text(' / day ', style: Theme.of(context).textTheme.bodySmall),
                ],
                if (widget.showFeedback) ...[
                  const Spacer(),
                  if (widget.showPrice) SizedBox(width: kDefaultFontSize),
                  ReviewsReservationsWidget(listing: widget.listing),
                ],
              ],
            ),
            if (widget.bottom != null) widget.bottom!(context),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        AutoRouter.of(context).push(
          ListingRoute(
            a: widget.listing.anchor!,
            dateRangeStart: widget.dateRange?.start != null
                ? widget.dateRange!.start.toIso8601String()
                : null,
            dateRangeEnd: widget.dateRange?.end != null
                ? widget.dateRange!.end.toIso8601String()
                : null,
          ),
        );
      },
      child: CustomPadding(
        child: widget.smallImage
            ? Row(
                children: [
                  SizedBox(height: 100, width: 100, child: getImage()),
                  SizedBox(width: kDefaultPadding.toDouble()),
                  Expanded(child: getDetails(context)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  getImage(),
                  const SizedBox(height: 8.0),
                  getDetails(context),
                ],
              ),
      ),
    );
  }
}
