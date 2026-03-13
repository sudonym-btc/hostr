import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/export.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/flow/modal_bottom_sheet.dart';
import 'package:hostr/presentation/component/widgets/listing/listing_carousel.dart';
import 'package:hostr/presentation/component/widgets/listing/preload_listing_images.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

import 'block_dates.dart';
import 'listing_error_view.dart';
import 'listing_location_map.dart';

class ListingView extends StatefulWidget {
  final String a;
  final DateTimeRange? dateRange;

  // ignore: use_key_in_widget_constructors
  const ListingView({required this.a, this.dateRange});

  @override
  State<ListingView> createState() => _ListingViewState();
}

class _ListingViewState extends State<ListingView> {
  StreamWithStatus<Reservation>? _listingReservationsStream;
  StreamWithStatus<Validation<Review>>? _verifiedReviews;
  StreamWithStatus<List<Validation<ReservationPair>>>? _verifiedPairs;
  String? _reviewsAnchor;

  @override
  initState() {
    _listingReservationsStream = getIt<Hostr>().reservations.subscribe(
      name: 'ListingView-reservations',
      Filter(
        tags: {
          kListingRefTag: [widget.a],
        },
      ),
    );
    super.initState();
  }

  void _ensureVerifiedReviews(String anchor) {
    if (_reviewsAnchor == anchor) return;
    _verifiedReviews?.close();
    _reviewsAnchor = anchor;
    _verifiedReviews = getIt<Hostr>().reviews.subscribeVerified(
      filter: Filter(
        tags: {
          kListingRefTag: [anchor],
        },
      ),
    );
  }

  void _ensureVerifiedPairs(Listing listing) {
    if (_verifiedPairs != null) return;
    _verifiedPairs = getIt<Hostr>().reservationPairs.subscribeVerified(
      listingAnchor: listing.anchor!,
    );
  }

  @override
  void dispose() {
    _verifiedReviews?.close();
    _verifiedPairs?.close();
    _listingReservationsStream?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DateRangeCubit>(
      create: (context) => DateRangeCubit()..updateDateRange(widget.dateRange),
      child: ListingProvider(
        a: widget.a,
        builder: (context, state) {
          if (state is EntityCubitStateError<Listing>) {
            return ListingErrorView(error: state.error);
          }

          if (state.data == null) {
            return Scaffold(body: Center(child: AppLoadingIndicator.large()));
          }

          final activeKeyPair = getIt<Hostr>().auth.activeKeyPair;
          final isOwner =
              activeKeyPair != null &&
              state.data!.pubKey == activeKeyPair.publicKey;

          _ensureVerifiedReviews(state.data!.anchor!);
          _ensureVerifiedPairs(state.data!);

          final reviewsListWidget = StreamBuilder<List<Validation<Review>>>(
            stream: _verifiedReviews!.itemsStream,
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return snapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: AppLoadingIndicator.large())
                    : const SizedBox.shrink();
              }
              return Column(
                children: [
                  for (final item in items) ...[
                    Gap.vertical.lg(),
                    if (item is Invalid<Review>)
                      _InvalidReviewWrapper(
                        reason: item.reason,
                        child: ReviewListItem(review: item.event),
                      )
                    else
                      ReviewListItem(review: item.event),
                  ],
                ],
              );
            },
          );

          return RepositoryProvider<StreamWithStatus<Reservation>?>.value(
            value: _listingReservationsStream,
            child: Scaffold(
              bottomNavigationBar: isOwner
                  ? null
                  : BottomAppBar(
                      child: CustomPadding.horizontal.lg(
                        child: StreamBuilder<List<Validation<ReservationPair>>>(
                          stream: _verifiedPairs!.latestItemsStream,
                          builder: (context, snapshot) {
                            final reservationPairs =
                                (snapshot.data ??
                                        const <Validation<ReservationPair>>[])
                                    .whereType<Valid<ReservationPair>>()
                                    .map((e) => e.event)
                                    .toList();

                            return Reserve(
                              listing: state.data!,
                              reservationPairs: reservationPairs,
                            );
                          },
                        ),
                      ),
                    ),
              body: StreamBuilder<List<Reservation>>(
                stream: _listingReservationsStream!.itemsStream,
                builder: (context, reservationsSnapshot) {
                  final allReservations =
                      reservationsSnapshot.data ?? const <Reservation>[];

                  final blockedReservations = activeKeyPair != null
                      ? allReservations
                            .where(
                              (r) =>
                                  r.isBlockedDate(activeKeyPair) &&
                                  r.cancelled != true,
                            )
                            .toList()
                      : const <Reservation>[];

                  final reservationPairs = state.data != null
                      ? Reservations.toReservationPairs(
                          reservations: allReservations,
                        )
                      : const <String, ReservationPair>{};

                  return CustomScrollView(
                    slivers: [
                      SliverAppBar(
                        stretch: true,
                        iconTheme: IconThemeData(
                          color: Colors.white,
                          shadows: [
                            Shadow(
                              blurRadius: kDefaultPadding.toDouble(),
                              color: Colors.black,
                            ),
                            Shadow(
                              blurRadius: kDefaultPadding.toDouble() * 2,
                              color: Colors.black,
                            ),
                          ],
                        ),
                        actions: [
                          if (isOwner)
                            IconButton(
                              icon: Icon(Icons.edit),
                              onPressed: () {
                                context.router.navigate(
                                  EditListingRoute(a: widget.a),
                                );
                              },
                            ),
                        ],
                        expandedHeight: MediaQuery.of(context).size.height / 4,
                        flexibleSpace: FlexibleSpaceBar(
                          background: PreloadListingImages(
                            listing: state.data!,
                            child: ListingCarousel(listing: state.data!),
                          ),
                        ),
                      ),
                      SliverList(
                        delegate: SliverChildListDelegate([
                          CustomPadding(
                            child: ListingViewBody(
                              listing: state.data!,
                              selectedDateRange: widget.dateRange,
                              isOwner: isOwner,
                              hostedByText: AppLocalizations.of(
                                context,
                              )!.hostedBy,
                              hostWidget: ProfileChipWidget(
                                id: state.data!.pubKey,
                              ),
                              reviewsSummaryWidget: ReviewsReservationsWidget(
                                reservationCount: _verifiedPairs!
                                    .latestItemsStream
                                    .map(
                                      (items) => items
                                          .whereType<Valid<ReservationPair>>()
                                          .length,
                                    ),
                                averageReviewRating: _verifiedReviews!
                                    .itemsStream
                                    .map((items) {
                                      final reviews = items
                                          .whereType<Valid<Review>>()
                                          .map((validation) => validation.event)
                                          .toList();
                                      if (reviews.isEmpty) {
                                        return 0.0;
                                      }

                                      final total = reviews.fold<double>(
                                        0,
                                        (sum, review) => sum + review.rating,
                                      );
                                      return total / reviews.length;
                                    }),
                                reviewCount: _verifiedReviews!.itemsStream.map(
                                  (items) =>
                                      items.whereType<Valid<Review>>().length,
                                ),
                              ),
                              reviewsListWidget: reviewsListWidget,
                              blockedReservations: blockedReservations,
                              reservationPairs: reservationPairs,
                              onCancelBlockedReservation: (reservation) async {
                                await getIt<Hostr>().reservations.cancel(
                                  reservation,
                                  getIt<Hostr>().auth.getActiveKey(),
                                );
                              },
                              onBlockDates: () {
                                showAppModal(
                                  context,
                                  child: BlockDatesWidget(
                                    listingAnchor: state.data!.anchor!,
                                  ),
                                );
                              },
                            ),
                          ),
                        ]),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}

class ListingViewBody extends StatelessWidget {
  final Listing listing;
  final DateTimeRange? selectedDateRange;
  final bool isOwner;
  final String hostedByText;
  final Widget hostWidget;
  final Widget reviewsSummaryWidget;
  final Widget reviewsListWidget;
  final List<Reservation> blockedReservations;
  final Map<String, ReservationPair> reservationPairs;
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
    required this.blockedReservations,
    required this.reservationPairs,
    required this.onCancelBlockedReservation,
    required this.onBlockDates,
  });

  Widget _buildBlockedReservationTile(
    BuildContext context,
    Reservation reservation,
    VoidCallback onCancel,
  ) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 0),
      title: Text(
        formatDateRangeShort(
          DateTimeRange(start: reservation.start, end: reservation.end),
          Localizations.localeOf(context),
        ),
      ),
      trailing: IconButton(icon: const Icon(Icons.cancel), onPressed: onCancel),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          listing.title,
          style: Theme.of(
            context,
          ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
        ),
        Gap.vertical.custom(kSpace1 / 2),
        Row(
          children: [
            Text(
              hostedByText,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            Gap.horizontal.sm(),
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
          Section(
            horizontalPadding: false,
            action: OutlinedButton(
              onPressed: onBlockDates,
              child: Text(AppLocalizations.of(context)!.blockDates),
            ),
            body: blockedReservations.isEmpty
                ? Text(
                    AppLocalizations.of(context)!.noBlockedDates,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(vertical: 0),
                    itemCount: blockedReservations.length,
                    itemBuilder: (context, index) =>
                        _buildBlockedReservationTile(
                          context,
                          blockedReservations[index],
                          () => onCancelBlockedReservation(
                            blockedReservations[index],
                          ),
                        ),
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                  ),
            title: AppLocalizations.of(context)!.blockedDates,
          ),
        ],
        reviewsListWidget,
      ],
    );
  }
}

class _InvalidReviewWrapper extends StatelessWidget {
  final String reason;
  final Widget child;

  const _InvalidReviewWrapper({required this.reason, required this.child});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Stack(
      children: [
        Opacity(opacity: 0.5, child: child),
        Positioned(
          top: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: colors.errorContainer,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              reason,
              style: Theme.of(
                context,
              ).textTheme.labelSmall?.copyWith(color: colors.onErrorContainer),
            ),
          ),
        ),
      ],
    );
  }
}
