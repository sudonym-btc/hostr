import 'package:auto_route/auto_route.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/main.dart';
import 'package:hostr/router.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

import 'price_tag.dart';

class ListingListItemWidget extends StatefulWidget {
  final Listing listing;
  final DateTimeRange? dateRange;
  final bool showPrice;
  final bool showFeedback;
  final bool smallImage;
  final WidgetBuilder? bottom;
  const ListingListItemWidget(
      {super.key,
      required this.listing,
      this.dateRange,
      this.showPrice = true,
      this.showFeedback = true,
      this.smallImage = false,
      this.bottom});

  @override
  State createState() => ListingListItemWidgetState();
}

class ListingListItemWidgetState extends State<ListingListItemWidget> {
  ListingListItemWidgetState();

  @override
  initState() {
    super.initState();
    // Preload images
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return; // Check if the widget is still mounted
      for (var imageUrl in widget.listing.parsedContent.images) {
        precacheImage(NetworkImage(imageUrl), context);
      }
    });
  }

  Widget getImage() {
    return CarouselSlider(
      options: CarouselOptions(viewportFraction: 1, padEnds: false),
      items: widget.listing.parsedContent.images.map((i) {
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
    );
  }

  Widget getDetails(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(widget.listing.parsedContent.title.toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(context).textTheme.titleLarge),
      const SizedBox(height: 8.0),
      Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            widget.listing.parsedContent.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          Row(
            children: [
              if (widget.showPrice)
                PriceTagWidget(price: widget.listing.parsedContent.price[0]),
              if (widget.showFeedback)
                BlocProvider(
                    create: (context) => FilterCubit()
                      ..updateFilter(Filter(aTags: [widget.listing.anchor])),
                    child: Row(
                      children: [
                        BlocProvider(
                          create: (context) => CountCubit(
                              kinds: Review.kinds,
                              filterCubit: context.read<FilterCubit>())
                            ..count(),
                          child: BlocBuilder<CountCubit, CountCubitState>(
                            builder: (context, state) {
                              if (state is CountCubitStateLoading) {
                                return CircularProgressIndicator();
                              }
                              return Text(" · ${state.count} reviews");
                            },
                          ),
                        ),
                        BlocProvider(
                          create: (context) => CountCubit(
                              kinds: Reservation.kinds,
                              filterCubit: context.read<FilterCubit>())
                            ..count(),
                          child: BlocBuilder<CountCubit, CountCubitState>(
                            builder: (context, state) {
                              if (state is CountCubitStateLoading) {
                                return CircularProgressIndicator();
                              }
                              return Text(" · ${state.count} stays");
                            },
                          ),
                        ),
                      ],
                    )),
            ],
          ),
          if (widget.bottom != null) widget.bottom!(context),
        ],
      ),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
        onTap: () {
          AutoRouter.of(context).push(ListingRoute(
            a: widget.listing.anchor,
            dateRangeStart: widget.dateRange?.start != null
                ? widget.dateRange!.start.toIso8601String()
                : null,
            dateRangeEnd: widget.dateRange?.end != null
                ? widget.dateRange!.end.toIso8601String()
                : null,
          ));
        },
        child: CustomPadding(
          child: widget.smallImage
              ? Row(children: [
                  SizedBox(height: 100, width: 100, child: getImage()),
                  SizedBox(width: DEFAULT_PADDING.toDouble()),
                  Expanded(child: getDetails(context)),
                ])
              : Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  getImage(),
                  const SizedBox(height: 8.0),
                  getDetails(context),
                ]),
        ));
  }
}
