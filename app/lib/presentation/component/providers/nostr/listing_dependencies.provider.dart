import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:rxdart/rxdart.dart';

class ListingDependencies {
  final Listing listing;
  final StreamWithStatus<Validation<Review>> verifiedReviews;
  final StreamWithStatus<List<Validation<ReservationPair>>>
  verifiedReservationPairs;

  factory ListingDependencies.forListing(Listing listing) {
    final anchor = listing.anchor;
    assert(
      anchor != null,
      'ListingDependencies.forListing requires a listing with a non-null anchor',
    );

    return ListingDependencies(
      listing: listing,
      verifiedReviews: getIt<Hostr>().reviews.queryVerified(
        filter: Filter(
          tags: {
            kListingRefTag: [anchor!],
          },
        ),
      ),
      verifiedReservationPairs: getIt<Hostr>().reservationPairs.queryVerified(
        listingAnchor: anchor,
      ),
    );
  }

  ListingDependencies({
    required this.listing,
    required this.verifiedReviews,
    required this.verifiedReservationPairs,
  });

  late final Stream<List<Validation<Review>>> reviewItems = verifiedReviews
      .itemsStream
      .shareReplay(maxSize: 1);

  late final Stream<List<Validation<ReservationPair>>> reservationPairItems =
      verifiedReservationPairs.latestItemsStream.shareReplay(maxSize: 1);

  late final Stream<int> reviewCount = reviewItems
      .map((items) => items.whereType<Valid<Review>>().length)
      .shareReplay(maxSize: 1);

  late final Stream<double> averageReviewRating = reviewItems
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
      })
      .shareReplay(maxSize: 1);

  late final Stream<int> reservationCount = reservationPairItems
      .map((items) => items.whereType<Valid<ReservationPair>>().length)
      .shareReplay(maxSize: 1);

  void close() {
    verifiedReviews.close();
    verifiedReservationPairs.close();
  }
}

class ListingDependenciesProvider extends StatefulWidget {
  final ListingDependencies? dependencies;
  final Listing? listing;
  final Widget child;

  const ListingDependenciesProvider({
    super.key,
    this.dependencies,
    this.listing,
    required this.child,
  }) : assert(
         dependencies != null || listing != null,
         'Either dependencies or listing must be provided',
       );

  static ListingDependencies of(BuildContext context) {
    return RepositoryProvider.of<ListingDependencies>(context);
  }

  static ListingDependencies? maybeOf(BuildContext context) {
    try {
      return of(context);
    } catch (_) {
      return null;
    }
  }

  @override
  State<ListingDependenciesProvider> createState() =>
      _ListingDependenciesProviderState();
}

class _ListingDependenciesProviderState
    extends State<ListingDependenciesProvider> {
  late ListingDependencies _dependencies;
  late bool _ownsDependencies;

  @override
  void initState() {
    super.initState();
    _initializeDependencies();
  }

  @override
  void didUpdateWidget(covariant ListingDependenciesProvider oldWidget) {
    super.didUpdateWidget(oldWidget);
    final shouldReinitialize =
        oldWidget.dependencies != widget.dependencies ||
        oldWidget.listing?.anchor != widget.listing?.anchor;
    if (shouldReinitialize) {
      _disposeOwnedDependencies();
      _initializeDependencies();
    }
  }

  void _initializeDependencies() {
    final provided = widget.dependencies;
    if (provided != null) {
      _dependencies = provided;
      _ownsDependencies = false;
      return;
    }

    final listing = widget.listing!;
    _dependencies = ListingDependencies.forListing(listing);
    _ownsDependencies = true;
  }

  void _disposeOwnedDependencies() {
    if (!_ownsDependencies) return;
    _dependencies.close();
  }

  @override
  void dispose() {
    _disposeOwnedDependencies();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider<ListingDependencies>.value(
      value: _dependencies,
      child: widget.child,
    );
  }
}
