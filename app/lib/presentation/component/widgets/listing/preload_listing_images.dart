import 'package:flutter/widgets.dart';
import 'package:hostr/data/sources/image_preloader.dart';
import 'package:hostr/injection.dart';
import 'package:models/main.dart';

/// A widget that eagerly preloads all images for a [Listing] into Flutter's
/// image cache as soon as it is inserted into the tree.
///
/// This handles both Blossom SHA-256 hashes (resolving the server list first)
/// and regular network URLs transparently.
///
/// Wrap listing lists or individual listing views with this widget so that
/// images are warm by the time the user scrolls to them.
///
/// ```dart
/// PreloadListingImages(
///   listing: listing,
///   child: ListingListItemView(...),
/// )
/// ```
class PreloadListingImages extends StatefulWidget {
  /// The listing whose images should be preloaded.
  final Listing listing;

  /// The child widget to render (pass-through).
  final Widget child;

  const PreloadListingImages({
    super.key,
    required this.listing,
    required this.child,
  });

  @override
  State<PreloadListingImages> createState() => _PreloadListingImagesState();
}

class _PreloadListingImagesState extends State<PreloadListingImages> {
  @override
  void initState() {
    super.initState();
    _preload();
  }

  @override
  void didUpdateWidget(PreloadListingImages oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.listing.anchor != widget.listing.anchor) {
      _preload();
    }
  }

  void _preload() {
    final images = widget.listing.parsedContent.images;
    if (images.isEmpty) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      getIt<ImagePreloader>().precacheForContext(
        images,
        pubkey: widget.listing.pubKey,
        context: context,
      );
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}

/// A widget that preloads images for an entire list of [Listing]s.
///
/// Useful at the top of a search results or "my listings" screen to begin
/// resolving Blossom hashes and warming images for all visible listings.
///
/// ```dart
/// PreloadListingsImages(
///   listings: listings,
///   child: ListView.builder(...),
/// )
/// ```
class PreloadListingsImages extends StatefulWidget {
  /// All listings whose images should be preloaded.
  final List<Listing> listings;

  /// The child widget to render (pass-through).
  final Widget child;

  const PreloadListingsImages({
    super.key,
    required this.listings,
    required this.child,
  });

  @override
  State<PreloadListingsImages> createState() => _PreloadListingsImagesState();
}

class _PreloadListingsImagesState extends State<PreloadListingsImages> {
  @override
  void initState() {
    super.initState();
    _preload();
  }

  @override
  void didUpdateWidget(PreloadListingsImages oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Re-preload when the list reference changes.
    if (oldWidget.listings != widget.listings) {
      _preload();
    }
  }

  void _preload() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final preloader = getIt<ImagePreloader>();
      for (final listing in widget.listings) {
        final images = listing.parsedContent.images;
        if (images.isNotEmpty) {
          preloader.precacheForContext(
            images,
            pubkey: listing.pubKey,
            context: context,
          );
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
