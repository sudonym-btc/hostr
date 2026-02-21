import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/main.dart';
import 'package:hostr/presentation/component/widgets/listing/listing_carousel.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
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

  StreamWithStatus<Reservation>? _reservationsStream;
  StreamSubscription<List<Reservation>>? _reservationsSubscription;
  AvailabilityCubit? _availabilityCubit;
  DateRangeCubit? _localDateRangeCubit;
  List<Reservation> _latestReservations = const [];

  @override
  initState() {
    super.initState();
    _reservationsStream = getIt<Hostr>().reservations.subscribe(
      Filter(
        tags: {
          kListingRefTag: [widget.listing.anchor!],
        },
      ),
    );
    _reservationsSubscription = _reservationsStream!.list.listen((items) {
      _latestReservations = items;
      _availabilityCubit?.updateReservations(items);
    });
    // Preload images
    // WidgetsBinding.instance.addPostFrameCallback((_) {
    //   if (!mounted) return; // Check if the widget is still mounted
    //   for (var imageUrl in widget.listing.parsedContent.images) {
    //     precacheImage(NetworkImage(imageUrl), context);
    //   }
    // });
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_availabilityCubit != null) return;

    DateRangeCubit? dateRangeCubit;
    try {
      dateRangeCubit = BlocProvider.of<DateRangeCubit>(context);
    } catch (_) {
      dateRangeCubit = null;
    }

    _localDateRangeCubit ??= DateRangeCubit();
    _availabilityCubit = AvailabilityCubit(
      dateRangeCubit: dateRangeCubit ?? _localDateRangeCubit!,
      reservations: _latestReservations,
    );
  }

  @override
  void dispose() {
    _reservationsSubscription?.cancel();
    _reservationsStream?.close();
    _availabilityCubit?.close();
    _localDateRangeCubit?.close();
    super.dispose();
  }

  Widget _buildAvailabilityText(BuildContext context) {
    final cubit = _availabilityCubit;
    if (cubit == null) {
      return const SizedBox.shrink();
    }

    return BlocBuilder<AvailabilityCubit, AvailabilityCubitState>(
      bloc: cubit,
      builder: (context, state) {
        final hasSelectedRange = cubit.dateRangeCubit.state.dateRange != null;
        if (!hasSelectedRange) {
          return const SizedBox.shrink();
        }

        if (state is AvailabilityLoading) {
          return Text(
            'Availability: Loading',
            style: Theme.of(context).textTheme.bodySmall,
          );
        }

        if (state is AvailabilityAvailable) {
          return Text(
            'Availability: Available',
            style: Theme.of(context).textTheme.bodySmall,
          );
        }

        if (state is AvailabilityUnavailable) {
          return Text(
            'Availability: Unavailable',
            style: Theme.of(context).textTheme.bodySmall,
          );
        }

        return const SizedBox.shrink();
      },
    );
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
            if (_availabilityCubit?.dateRangeCubit.state.dateRange != null)
              _buildAvailabilityText(context),
            if (_availabilityCubit?.dateRangeCubit.state.dateRange != null)
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
