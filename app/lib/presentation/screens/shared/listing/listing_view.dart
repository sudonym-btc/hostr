import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/export.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/listing/listing_carousel.dart';
import 'package:hostr/presentation/component/widgets/listing/preload_listing_images.dart';
import 'package:hostr/router.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

import 'block_dates.dart';

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
  ValidatedStreamWithStatus<Review>? _verifiedReviews;
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

  @override
  void dispose() {
    _verifiedReviews?.close();
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
            return Scaffold(
              appBar: AppBar(),
              body: Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.error_outline,
                        size: 48,
                        color: Theme.of(context).colorScheme.error,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${state.error}',
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 24),
                      FilledButton.icon(
                        onPressed: () =>
                            context.read<EntityCubit<Listing>>().get(),
                        icon: const Icon(Icons.refresh),
                        label: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }

          if (state.data == null) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          }

          final activeKeyPair = getIt<Hostr>().auth.activeKeyPair;
          final isOwner =
              activeKeyPair != null &&
              state.data!.pubKey == activeKeyPair.publicKey;

          _ensureVerifiedReviews(state.data!.anchor!);

          final reviewsListWidget = StreamBuilder<List<Validation<Review>>>(
            stream: _verifiedReviews!.list,
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return snapshot.connectionState == ConnectionState.waiting
                    ? const Center(child: CircularProgressIndicator.adaptive())
                    : const SizedBox.shrink();
              }
              return Column(
                children: [
                  for (final item in items) ...[
                    SizedBox(height: kDefaultPadding.toDouble()),
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
              bottomNavigationBar: BottomAppBar(
                child: CustomPadding(
                  top: 0,
                  bottom: 0,
                  child: Reserve(listing: state.data!),
                ),
              ),
              body: StreamBuilder<List<Reservation>>(
                stream: _listingReservationsStream!.list,
                builder: (context, reservationsSnapshot) {
                  final blockedReservations = activeKeyPair != null
                      ? reservationsSnapshot.data
                                ?.where((r) => r.isBlockedDate(activeKeyPair))
                                .toList() ??
                            const <Reservation>[]
                      : const <Reservation>[];

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
                                listing: state.data!,
                              ),
                              reviewsListWidget: reviewsListWidget,
                              blockedReservations: blockedReservations,
                              onCancelBlockedReservation: (reservation) async {
                                await getIt<Hostr>().reservations.cancel(
                                  reservation,
                                );
                              },
                              onBlockDates: () {
                                showModalBottomSheet(
                                  context: context,
                                  builder: (context) {
                                    return BlockDatesWidget(
                                      listingAnchor: state.data!.anchor!,
                                    );
                                  },
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
    required this.onCancelBlockedReservation,
    required this.onBlockDates,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          listing.parsedContent.title,
          style: Theme.of(context).textTheme.titleLarge,
        ),
        const SizedBox(height: 2.0),
        Row(
          children: [
            Text(hostedByText),
            SizedBox(width: 8),
            Flexible(child: hostWidget),
          ],
        ),
        const SizedBox(height: 8.0),
        reviewsSummaryWidget,
        const SizedBox(height: 8),
        AmenityTagsWidget(amenities: listing.parsedContent.amenities),
        const SizedBox(height: 16),
        Text(
          listing.parsedContent.description,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        // ── Location map ──────────────────────────────────────────────
        Builder(
          builder: (context) {
            final h3Tag = listing.tags
                .where((tag) => tag.isNotEmpty && tag.first == 'g')
                .map((tag) => tag.length > 1 ? tag[1] : '')
                .where((value) => value.isNotEmpty)
                .firstOrNull;
            if (h3Tag == null) return const SizedBox.shrink();

            final priceText = listing.parsedContent.price.isNotEmpty
                ? formatAmount(
                    listing.parsedContent.price.first.amount,
                    exact: false,
                  )
                : null;

            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  height: 180,
                  width: double.infinity,
                  child: ListingMap(
                    listings: [
                      ListingMarkerData(
                        id: listing.id,
                        h3Tag: h3Tag,
                        priceText: priceText,
                      ),
                    ],
                    interactive: false,
                    showArrows: false,
                    fitBoundsPadding: 40,
                  ),
                ),
              ),
            );
          },
        ),
        if (isOwner) ...[
          const SizedBox(height: 16),
          Text('Blocked Dates', style: Theme.of(context).textTheme.titleMedium),
          if (blockedReservations.isEmpty)
            Text('No blocked dates.')
          else
            ListView.builder(
              itemCount: blockedReservations.length,
              itemBuilder: (context, index) {
                final reservation = blockedReservations[index];
                return ListTile(
                  title: Text(
                    formatDateRangeShort(
                      DateTimeRange(
                        start: reservation.parsedContent.start,
                        end: reservation.parsedContent.end,
                      ),
                      Localizations.localeOf(context),
                    ),
                  ),
                  trailing: IconButton(
                    icon: Icon(Icons.cancel),
                    onPressed: () => onCancelBlockedReservation(reservation),
                  ),
                );
              },
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
            ),
          FilledButton(onPressed: onBlockDates, child: Text('Block Dates')),
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
