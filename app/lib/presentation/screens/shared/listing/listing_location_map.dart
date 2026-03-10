import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hostr/export.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/search/listing_map.dart';
import 'package:models/main.dart';
import 'package:url_launcher/url_launcher.dart';

/// Standalone location map section shown on the listing detail page.
///
/// Extracts the H3 tag from the listing, renders a non-interactive
/// [ListingMap] and taps through to the native maps app.
class ListingLocationMapSection extends StatelessWidget {
  final Listing listing;

  const ListingLocationMapSection({super.key, required this.listing});

  @override
  Widget build(BuildContext context) {
    final h3Tag = listing.tags
        .where((tag) => tag.isNotEmpty && tag.first == 'g')
        .map((tag) => tag.length > 1 ? tag[1] : '')
        .where((value) => value.isNotEmpty)
        .firstOrNull;
    if (h3Tag == null) return const SizedBox.shrink();

    final priceText = listing.prices.isNotEmpty
        ? formatAmount(listing.prices.first.amount, exact: false)
        : null;

    return CustomPadding.only(
      top: kSpace4,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          final h3 = getIt<H3Engine>();
          final center = h3.polygonCover.centerForTag(h3Tag);
          if (center == null) return;
          openInMaps(
            context,
            center.latitude,
            center.longitude,
            listing.title,
          );
        },
        child: ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: SizedBox(
            height: 180,
            width: double.infinity,
            child: IgnorePointer(
              child: ListingMap(
                listings: [
                  ListingMarkerData(
                    id: listing.id,
                    h3Tag: h3Tag,
                    priceText: priceText,
                  ),
                ],
                singleMarkerZoom: 9,
                interactive: false,
                showArrows: false,
                autoFitBounds: true,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Opens the given coordinates in the platform's maps app.
void openInMaps(
  BuildContext context,
  double lat,
  double lng,
  String title,
) {
  final encodedTitle = Uri.encodeComponent(title);
  final platform = defaultTargetPlatform;

  if (platform == TargetPlatform.iOS || platform == TargetPlatform.macOS) {
    final appleMapsUri = Uri.parse(
      'https://maps.apple.com/?ll=$lat,$lng&q=$encodedTitle',
    );
    final googleMapsUri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=$lat,$lng',
    );
    showModalBottomSheet(
      context: context,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.map),
              title: const Text('Apple Maps'),
              onTap: () {
                Navigator.pop(ctx);
                launchUrl(appleMapsUri, mode: LaunchMode.externalApplication);
              },
            ),
            ListTile(
              leading: const Icon(Icons.map_outlined),
              title: const Text('Google Maps'),
              onTap: () {
                Navigator.pop(ctx);
                launchUrl(
                  googleMapsUri,
                  mode: LaunchMode.externalApplication,
                );
              },
            ),
          ],
        ),
      ),
    );
  } else {
    // Android: geo URI triggers the native app chooser
    launchUrl(
      Uri.parse('geo:$lat,$lng?q=$lat,$lng($encodedTitle)'),
      mode: LaunchMode.externalApplication,
    );
  }
}
