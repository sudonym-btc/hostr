import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/data/sources/blossom_image_variant.dart';
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
    return SmallListingCarousel(
      height: 200,
      listing: listing,
      variantHint: BlossomImageVariantHint.listingPreview,
    );
  }

  Widget _buildDetails(BuildContext context) {
    final price = listing.prices.isEmpty ? null : listing.prices[0];
    final hasPrice = showPrice && price != null;
    final showSummaryRow = hasPrice || showFeedback;

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
            if (listing.negotiable) ...[
              const ListingNegotiableTag(),
              const SizedBox(height: kSpace1),
            ],
            if (showSummaryRow)
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.max,
                children: [
                  if (hasPrice)
                    Expanded(child: ListingPriceMetadataWidget(price: price))
                  else if (showFeedback)
                    const Spacer(),
                  if (showFeedback) ...[
                    if (hasPrice) Gap.horizontal.md(),
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

class ListingNegotiableTag extends StatelessWidget {
  const ListingNegotiableTag({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textStyle =
        Theme.of(context).textTheme.labelSmall ??
        DefaultTextStyle.of(context).style;

    return DecoratedBox(
      decoration: BoxDecoration(
        color: colorScheme.secondaryContainer.withValues(alpha: 0.64),
        borderRadius: BorderRadius.circular(5),
        border: Border.all(
          color: colorScheme.secondary.withValues(alpha: 0.24),
          width: 0.5,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
        child: Text(
          AppLocalizations.of(context)!.negotiable,
          key: const ValueKey('listing_negotiable_tag'),
          style: textStyle.copyWith(
            color: colorScheme.onSecondaryContainer,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
            height: 1,
            letterSpacing: 0,
          ),
        ),
      ),
    );
  }
}

class ListingPriceMetadataWidget extends StatelessWidget {
  final Price price;

  const ListingPriceMetadataWidget({super.key, required this.price});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        PriceTagWidget(price: price),
        Text(
          AppLocalizations.of(context)!.perDayLabel,
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
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

  StreamSubscription<List<Validation<OrderGroup>>>? _verifiedPairsSubscription;
  late final ListingDependencies _listingDependencies;
  AvailabilityCubit? _availabilityCubit;
  DateRangeCubit? _localDateRangeCubit;
  List<OrderGroup> _latestAvailabilityGroups = const [];

  @override
  void initState() {
    super.initState();
    assert(
      widget.listing.anchor != null,
      'ListingListItemWidget requires a listing with a non-null anchor',
    );
    _listingDependencies = ListingDependencies.forListing(widget.listing);

    _verifiedPairsSubscription = _listingDependencies.reservationGroupItems
        .listen((items) {
          final availabilityGroups = items
              .whereType<Valid<OrderGroup>>()
              .map((validated) => validated.event)
              .toList();

          _latestAvailabilityGroups = availabilityGroups;
          _availabilityCubit?.updateReservationGroups(availabilityGroups);
        });
  }

  @override
  void didUpdateWidget(covariant ListingListItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.listing.id == widget.listing.id) return;

    final oldAnchor = oldWidget.listing.anchor;
    final nextAnchor = widget.listing.anchor;
    if (oldAnchor == nextAnchor) {
      _listingDependencies.listing = widget.listing;
    }
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
      reservationGroups: _latestAvailabilityGroups,
    );
  }

  @override
  void dispose() {
    unawaited(_verifiedPairsSubscription?.cancel());
    unawaited(_listingDependencies.close());
    unawaited(_availabilityCubit?.close());
    unawaited(_localDateRangeCubit?.close());
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
        variantHint: BlossomImageVariantHint.listingPreview,
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
          onTap: widget.listing.naddr() != null
              ? () {
                  DateTimeRange? dr = widget.dateRange;
                  if (dr == null) {
                    try {
                      dr = context.read<DateRangeCubit>().state.dateRange;
                    } catch (_) {}
                  }
                  AutoRouter.of(context).push(
                    ListingRoute(
                      a: widget.listing.naddr()!,
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
