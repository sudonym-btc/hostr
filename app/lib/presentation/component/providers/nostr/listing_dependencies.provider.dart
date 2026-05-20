import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';
import 'package:rxdart/rxdart.dart';

class ListingDependencies {
  Listing listing;
  final StreamWithStatus<Validation<Review>> verifiedReviews;
  final StreamWithStatus<Validation<ReservationGroup>> verifiedOrderGroups;
  StreamWithStatus<List<Validation<Review>>>? _reviewItemsSource;
  StreamWithStatus<List<Validation<ReservationGroup>>>?
  _reservationGroupItemsSource;

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
      verifiedOrderGroups: getIt<Hostr>().orderGroups.queryVerified(
        listingAnchor: anchor,
      ),
    );
  }

  ListingDependencies({
    required this.listing,
    required this.verifiedReviews,
    required this.verifiedOrderGroups,
  });

  StreamWithStatus<List<Validation<Review>>> get _reviewItems =>
      _reviewItemsSource ??= verifiedReviews.accumulateByKey((r) => r.event.id);

  StreamWithStatus<List<Validation<ReservationGroup>>>
  get _reservationGroupItems => _reservationGroupItemsSource ??=
      verifiedOrderGroups.accumulateByKey((g) => g.event.groupId);

  late final Stream<List<Validation<Review>>> reviewItems = _reviewItems
      .replayStream
      .shareReplay(maxSize: 1);

  late final Stream<List<Validation<ReservationGroup>>> reservationGroupItems =
      _reservationGroupItems.replayStream.shareReplay(maxSize: 1);

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

  late final Stream<int> reservationCount = reservationGroupItems
      .map((items) => items.whereType<Valid<ReservationGroup>>().length)
      .shareReplay(maxSize: 1);

  Future<void> close() async {
    await _reviewItemsSource?.close();
    _reviewItemsSource = null;
    await _reservationGroupItemsSource?.close();
    _reservationGroupItemsSource = null;
    await verifiedReviews.close();
    await verifiedOrderGroups.close();
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
    } else if (widget.listing != null &&
        widget.listing!.id != _dependencies.listing.id) {
      _dependencies.listing = widget.listing!;
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
    unawaited(_dependencies.close());
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
