import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/main.dart';
import 'package:hostr/presentation/component/providers/nostr/listing_dependencies.provider.dart';
import 'package:hostr/presentation/component/widgets/listing/listing_carousel.dart';
import 'package:hostr/presentation/component/widgets/listing/preload_listing_images.dart';
import 'package:hostr/router.dart';
import 'package:models/main.dart';

import 'price_tag.dart';

class ListingListItemView extends StatelessWidget {
  final ListingDependencies dependencies;
  final bool showPrice;
  final bool showFeedback;
  final bool smallImage;
  final WidgetBuilder? bottom;
  final bool showAvailability;
  final Widget? availabilityWidget;
  final VoidCallback? onTap;

  const ListingListItemView({
    super.key,
    required this.dependencies,
    required this.showPrice,
    required this.showFeedback,
    required this.smallImage,
    this.bottom,
    required this.showAvailability,
    this.availabilityWidget,
    this.onTap,
  });

  Listing get listing => dependencies.listing;

  Widget _buildImage() {
    return SmallListingCarousel(height: 200, listing: listing);
  }

  Widget _buildDetails(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          listing.title.toString(),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Gap.vertical.xxs(),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              listing.description,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Gap.vertical.xs(),
            if (showAvailability && availabilityWidget != null)
              availabilityWidget!,
            if (showAvailability && availabilityWidget != null)
              Gap.vertical.xs(),
            Row(
              crossAxisAlignment: CrossAxisAlignment.baseline,
              mainAxisSize: MainAxisSize.max,
              textBaseline: TextBaseline.alphabetic,
              children: [
                if (showPrice) ...[
                  PriceTagWidget(price: listing.prices[0]),
                  Text(
                    AppLocalizations.of(context)!.perDayLabel,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
                if (showFeedback) ...[
                  const Spacer(),
                  if (showPrice) Gap.horizontal.md(),
                  ReviewsReservationsWidget(
                    reservationCount: dependencies.reservationCount,
                    averageReviewRating: dependencies.averageReviewRating,
                    reviewCount: dependencies.reviewCount,
                  ),
                ],
              ],
            ),
            if (bottom != null) bottom!(context),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: CustomPadding(
        child: smallImage
            ? Row(
                children: [
                  SizedBox(height: 100, width: 100, child: _buildImage()),
                  Gap.horizontal.lg(),
                  Expanded(child: _buildDetails(context)),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildImage(),
                  Gap.vertical.xs(),
                  _buildDetails(context),
                ],
              ),
      ),
    );
  }
}

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

  StreamSubscription<List<Validation<ReservationPair>>>?
  _verifiedPairsSubscription;
  late final ListingDependencies _listingDependencies;
  AvailabilityCubit? _availabilityCubit;
  DateRangeCubit? _localDateRangeCubit;
  List<ReservationPair> _latestAvailabilityPairs = const [];

  @override
  void initState() {
    super.initState();
    assert(
      widget.listing.anchor != null,
      'ListingListItemWidget requires a listing with a non-null anchor',
    );
    _listingDependencies = ListingDependencies.forListing(widget.listing);

    _verifiedPairsSubscription = _listingDependencies.reservationPairItems
        .listen((items) {
          final availabilityPairs = items
              .whereType<Valid<ReservationPair>>()
              .map((validated) => validated.event)
              .toList();

          _latestAvailabilityPairs = availabilityPairs;
          _availabilityCubit?.updateReservationPairs(availabilityPairs);
        });
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
      reservationPairs: _latestAvailabilityPairs,
    );
  }

  @override
  void dispose() {
    _verifiedPairsSubscription?.cancel();
    _listingDependencies.close();
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
            'Available',
            style: Theme.of(context).textTheme.bodySmall,
          );
        }

        if (state is AvailabilityUnavailable) {
          return Text(
            'Unavailable',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Theme.of(context).colorScheme.error,
            ),
          );
        }

        return const SizedBox.shrink();
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final showAvailability =
        _availabilityCubit?.dateRangeCubit.state.dateRange != null;

    return ListingDependenciesProvider(
      dependencies: _listingDependencies,
      child: PreloadListingImages(
        listing: widget.listing,
        child: ListingListItemView(
          dependencies: _listingDependencies,
          showPrice: widget.showPrice,
          showFeedback: widget.showFeedback,
          smallImage: widget.smallImage,
          bottom: widget.bottom,
          showAvailability: showAvailability,
          availabilityWidget: showAvailability
              ? _buildAvailabilityText(context)
              : null,
          onTap: widget.listing.anchor != null
              ? () {
                  DateTimeRange? dr = widget.dateRange;
                  if (dr == null) {
                    try {
                      dr = context.read<DateRangeCubit>().state.dateRange;
                    } catch (_) {}
                  }
                  AutoRouter.of(context).push(
                    ListingRoute(
                      a: widget.listing.anchor!,
                      dateRangeStart: dr?.start.toUtc().toIso8601String(),
                      dateRangeEnd: dr?.end.toUtc().toIso8601String(),
                    ),
                  );
                }
              : null,
        ),
      ),
    );
  }
}
