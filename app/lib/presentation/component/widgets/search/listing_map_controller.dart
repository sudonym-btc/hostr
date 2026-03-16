import 'package:flutter/foundation.dart';

/// Data object describing a single marker to place on a `ListingMap`.
///
/// `id` is used for marker identity and selection.
/// `h3Tag` is resolved to lat/lng via `H3Engine`.
/// `priceText` is rendered on the pill label.
/// `enabled` controls disabled marker styling.
@immutable
class ListingMarkerData {
  final String id;
  final String h3Tag;
  final String? priceText;
  final bool enabled;

  const ListingMarkerData({
    required this.id,
    required this.h3Tag,
    this.priceText,
    this.enabled = true,
  });

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        other is ListingMarkerData &&
            other.id == id &&
            other.h3Tag == h3Tag &&
            other.priceText == priceText &&
            other.enabled == enabled;
  }

  @override
  int get hashCode => Object.hash(id, h3Tag, priceText, enabled);
}

enum ListingMapViewportMode { idle, focusAll, selected }

/// Public controller for `ListingMap` state and imperative commands.
class ListingMapController extends ChangeNotifier {
  ListingMapController({
    Iterable<ListingMarkerData> initialListings = const [],
  }) {
    _listings.addAll(initialListings);
    if (_listings.isNotEmpty) {
      _viewportMode = ListingMapViewportMode.focusAll;
      _markersRevision = 1;
      _viewportRevision = 1;
    }
  }

  final List<ListingMarkerData> _listings = [];

  String? _selectedListingId;
  ListingMapViewportMode _viewportMode = ListingMapViewportMode.idle;
  int _markersRevision = 0;
  int _viewportRevision = 0;

  List<ListingMarkerData> get listings => List.unmodifiable(_listings);

  String? get selectedListingId => _selectedListingId;

  ListingMapViewportMode get viewportMode => _viewportMode;

  int get markersRevision => _markersRevision;

  int get viewportRevision => _viewportRevision;

  bool contains(String listingId) {
    return _listings.any((listing) => listing.id == listingId);
  }

  void setListings(Iterable<ListingMarkerData> listings) {
    final nextListings = listings.toList(growable: false);
    if (listEquals(_listings, nextListings)) return;

    _listings
      ..clear()
      ..addAll(nextListings);
    _markersRevision++;

    var shouldNotify = true;
    final hasSelection = _selectedListingId != null;
    final selectionStillExists =
        _selectedListingId != null && contains(_selectedListingId!);

    if (!selectionStillExists) {
      _selectedListingId = null;
      final nextMode = _listings.isEmpty
          ? ListingMapViewportMode.idle
          : ListingMapViewportMode.focusAll;
      if (_viewportMode != nextMode) {
        _viewportMode = nextMode;
      }
      _viewportRevision++;
    } else if (!hasSelection) {
      final nextMode = _listings.isEmpty
          ? ListingMapViewportMode.idle
          : ListingMapViewportMode.focusAll;
      if (_viewportMode != nextMode) {
        _viewportMode = nextMode;
        _viewportRevision++;
      }
    }

    if (shouldNotify) {
      notifyListeners();
    }
  }

  void select(String listingId) {
    if (!contains(listingId)) return;
    if (_selectedListingId == listingId &&
        _viewportMode == ListingMapViewportMode.selected) {
      return;
    }

    _selectedListingId = listingId;
    _viewportMode = ListingMapViewportMode.selected;
    _viewportRevision++;
    notifyListeners();
  }

  void deselect() {
    if (_selectedListingId == null &&
        _viewportMode == ListingMapViewportMode.idle) {
      return;
    }

    _selectedListingId = null;
    _viewportMode = ListingMapViewportMode.idle;
    _viewportRevision++;
    notifyListeners();
  }

  void focusAll() {
    final nextMode = _listings.isEmpty
        ? ListingMapViewportMode.idle
        : ListingMapViewportMode.focusAll;
    if (_selectedListingId == null && _viewportMode == nextMode) {
      return;
    }

    _selectedListingId = null;
    _viewportMode = nextMode;
    _viewportRevision++;
    notifyListeners();
  }

  void addListing(ListingMarkerData listing) {
    final existingIndex = _listings.indexWhere((item) => item.id == listing.id);
    if (existingIndex >= 0) {
      if (_listings[existingIndex] == listing) return;
      _listings[existingIndex] = listing;
    } else {
      _listings.add(listing);
    }

    _markersRevision++;
    if (_selectedListingId == null) {
      _viewportMode = ListingMapViewportMode.focusAll;
      _viewportRevision++;
    }
    notifyListeners();
  }

  void removeListing(String listingId) {
    final existingIndex = _listings.indexWhere((item) => item.id == listingId);
    if (existingIndex < 0) return;

    _listings.removeAt(existingIndex);
    _markersRevision++;

    if (_selectedListingId == listingId) {
      _selectedListingId = null;
      _viewportMode = _listings.isEmpty
          ? ListingMapViewportMode.idle
          : ListingMapViewportMode.focusAll;
      _viewportRevision++;
    } else if (_selectedListingId == null) {
      _viewportMode = _listings.isEmpty
          ? ListingMapViewportMode.idle
          : ListingMapViewportMode.focusAll;
      _viewportRevision++;
    }

    notifyListeners();
  }
}
