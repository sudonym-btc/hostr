import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/export.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/providers/nostr/listing_dependencies.provider.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/component/widgets/listing/listing_carousel.dart';
import 'package:hostr/presentation/component/widgets/listing/preload_listing_images.dart';
import 'package:hostr/presentation/layout/app_layout.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';

import 'block_dates.dart';
import 'blocked_reservations.dart';
import 'listing_error_view.dart';
import 'listing_location_map.dart';
import 'reviews.dart' as listing_sections;

class ListingView extends StatefulWidget {
  final String a;
  final DateTimeRange? dateRange;

  // ignore: use_key_in_widget_constructors
  const ListingView({required this.a, this.dateRange});

  @override
  State<ListingView> createState() => _ListingViewState();
}

class _ListingViewState extends State<ListingView> {
  @override
  Widget build(BuildContext context) {
    return BlocProvider<DateRangeCubit>(
      create: (context) => DateRangeCubit()..updateDateRange(widget.dateRange),
      child: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    return ListingProvider(
      a: widget.a,
      builder: (context, state) {
        if (state is EntityCubitStateError<Listing>) {
          return ListingErrorView(error: state.error);
        }

        if (state.data == null) {
          return AppPaneLayout(
            panes: [
              AppPane(
                usePanel: false,
                child: Center(child: AppLoadingIndicator.large()),
              ),
            ],
          );
        }

        return ListingDependenciesProvider(
          listing: state.data!,
          child: _ListingViewContent(dateRange: widget.dateRange),
        );
      },
    );
  }
}

class _ListingViewContent extends StatelessWidget {
  final DateTimeRange? dateRange;

  const _ListingViewContent({required this.dateRange});

  @override
  Widget build(BuildContext context) {
    final dependencies = ListingDependenciesProvider.of(context);
    final listing = dependencies.listing;
    final activeKeyPair = getIt<Hostr>().auth.activeKeyPair;
    final isOwner =
        activeKeyPair != null && listing.pubKey == activeKeyPair.publicKey;

    final reviewsListWidget = listing_sections.ListingReviewsList(
      reviewsStream: dependencies.verifiedReviews,
      itemsStream: dependencies.reviewItems,
    );

    final reserveBottomBar = isOwner
        ? null
        : Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SafeArea(
                top: false,
                child: CustomPadding.only(
                  top: kSpace3,
                  bottom: kSpace3,
                  left: kSpace6,
                  right: kSpace6,
                  child: Reserve(
                    listing: listing,
                    reservationPairItemsStream:
                        dependencies.reservationPairItems,
                  ),
                ),
              ),
            ],
          );

    return SafeArea(
      top: false,
      child: ListingViewBody(
        listing: listing,
        selectedDateRange: dateRange,
        isOwner: isOwner,
        hostedByText: AppLocalizations.of(context)!.hostedBy,
        hostWidget: ProfileChipWidget(id: listing.pubKey),
        reviewsSummaryWidget: ReviewsReservationsWidget(
          reservationCount: dependencies.reservationCount,
          averageReviewRating: dependencies.averageReviewRating,
          reviewCount: dependencies.reviewCount,
        ),
        reviewsListWidget: reviewsListWidget,
        reserveBottomBar: reserveBottomBar,
        verifiedPairsStream: dependencies.verifiedReservationPairs,
        hostKeyPair: activeKeyPair,
        onCancelBlockedReservation: (reservation) async {
          await getIt<Hostr>().reservations.cancel(
            reservation,
            getIt<Hostr>().auth.getActiveKey(),
          );
        },
        onBlockDates: () {
          showAppModal(
            context,
            builder: (_) => BlockDatesWidget(listingAnchor: listing.anchor!),
          );
        },
      ),
    );
  }
}

class ListingViewBody extends StatelessWidget {
  static const _wideCarouselAspectRatio = 16 / 9;

  final Listing listing;
  final DateTimeRange? selectedDateRange;
  final bool isOwner;
  final String hostedByText;
  final Widget hostWidget;
  final Widget reviewsSummaryWidget;
  final Widget reviewsListWidget;
  final Widget? reserveBottomBar;
  final StreamWithStatus<List<Validation<ReservationPair>>> verifiedPairsStream;
  final KeyPair? hostKeyPair;
  final ValueChanged<Reservation> onCancelBlockedReservation;
  final VoidCallback onBlockDates;

  const ListingViewBody({
    super.key,
    required this.listing,
    required this.selectedDateRange,
    required this.isOwner,
    required this.hostedByText,
    required this.hostWidget,
    required this.reviewsSummaryWidget,
    required this.reviewsListWidget,
    this.reserveBottomBar,
    required this.verifiedPairsStream,
    required this.hostKeyPair,
    required this.onCancelBlockedReservation,
    required this.onBlockDates,
  });

  Widget _buildHeroCarousel() {
    return PreloadListingImages(
      listing: listing,
      child: ListingCarousel(listing: listing),
    );
  }

  SliverAppBar _buildPrimarySliverAppBar(BuildContext context) {
    final layout = AppLayoutSpec.of(context);
    final wideExpandedHeight = kAppPanelLargeWidth / _wideCarouselAspectRatio;
    final compactExpandedHeight = MediaQuery.sizeOf(context).height / 4;

    return SliverAppBar(
      stretch: true,
      pinned: true,
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.transparent,
      iconTheme: const IconThemeData(color: Colors.white),
      actionsIconTheme: const IconThemeData(color: Colors.white),
      actions: [
        if (isOwner)
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              context.router.navigate(
                EditListingRoute(a: listing.anchor ?? listing.id),
              );
            },
          ),
      ],
      expandedHeight: layout.isExpanded
          ? wideExpandedHeight
          : compactExpandedHeight,
      flexibleSpace: FlexibleSpaceBar(background: _buildHeroCarousel()),
    );
  }

  Widget _buildPrimaryContent(BuildContext context) {
    return Padding(
      padding: kAppPanelPadding,
      child: _buildDetailsContent(context),
    );
  }

  Widget _buildDetailsContent(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          listing.title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Gap.vertical.xs(),
        Row(
          children: [
            Text(
              hostedByText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Gap.horizontal.xs(),
            Flexible(child: hostWidget),
          ],
        ),
        Gap.vertical.sm(),
        reviewsSummaryWidget,
        Gap.vertical.sm(),
        AmenityTagsWidget(amenities: listing.amenities),
        Gap.vertical.md(),
        Text(
          listing.description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        ListingLocationMapSection(listing: listing),
        if (isOwner) ...[
          Gap.vertical.lg(),
          BlockedReservations(
            reservationPairItemsStream: ListingDependenciesProvider.of(
              context,
            ).reservationPairItems,
            hostKeyPair: hostKeyPair,
            onCancelBlockedReservation: onCancelBlockedReservation,
            onBlockDates: onBlockDates,
          ),
        ],
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return AppPageGutter(
      maxWidth: kAppWideContentMaxWidth,
      padding: EdgeInsets.zero,
      child: AppPaneLayout(
        panes: [
          AppPane(
            flex: 2,
            panelTone: AppPanelTone.primary,
            sliverAppBarBuilder: _buildPrimarySliverAppBar,
            bottomBar: reserveBottomBar,
            child: _buildPrimaryContent(context),
          ),
          AppPane(
            flex: 1,
            panelTone: AppPanelTone.secondary,
            child: _ScrollWhenBounded(
              child: CustomPadding.horizontal.md(
                child: listing_sections.ListingReviewsSection(
                  reviewsListWidget: reviewsListWidget,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScrollWhenBounded extends StatelessWidget {
  final Widget child;

  const _ScrollWhenBounded({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.hasBoundedHeight) {
          return SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: SizedBox(width: double.infinity, child: child),
            ),
          );
        }
        return child;
      },
    );
  }
}
