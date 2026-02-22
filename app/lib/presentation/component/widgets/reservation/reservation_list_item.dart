import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/config/main.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/presentation/component/main.dart';
import 'package:hostr/presentation/component/widgets/listing/listing_carousel.dart';
import 'package:hostr/presentation/component/widgets/listing/preload_listing_images.dart';
import 'package:hostr/router.dart';
import 'package:models/main.dart';

/// Displays a group of reservations that share the same commitment hash.
///
/// Shows the listing image carousel, title, reservation date range, and status.
/// Tapping navigates to the inbox thread for this reservation.
class ReservationListItem extends StatelessWidget {
  /// All reservations sharing the same commitment hash.
  final List<Reservation> reservations;

  const ReservationListItem({super.key, required this.reservations});

  @override
  Widget build(BuildContext context) {
    assert(reservations.isNotEmpty);

    final reservation = reservations.first;
    final listingAnchor = reservation.parsedTags.listingAnchor;
    final threadAnchor = reservation.getTags(kThreadRefTag).firstOrNull;

    return ListingProvider(
      a: listingAnchor,
      builder: (context, state) {
        final listing = state.data;
        final title = listing?.parsedContent.title.toString() ?? '…';
        final subtitle =
            '${formatDate(reservation.parsedContent.start)} – ${formatDate(reservation.parsedContent.end)}';

        return InkWell(
          onTap: threadAnchor != null
              ? () => AutoRouter.of(
                  context,
                ).push(ThreadRoute(anchor: threadAnchor))
              : null,
          child: CustomPadding(
            child: Row(
              children: [
                if (listing != null)
                  PreloadListingImages(
                    listing: listing,
                    child: SizedBox(
                      height: 100,
                      width: 100,
                      child: SmallListingCarousel(listing: listing),
                    ),
                  ),
                SizedBox(width: kDefaultPadding.toDouble()),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      if (listing != null) ...[
                        const SizedBox(height: 8),
                        _buildStatusChip(context, listing),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusChip(BuildContext context, Listing listing) {
    final status = Reservation.getReservationStatus(
      reservations: reservations,
      listing: listing,
    );

    final (String label, Color? color) = switch (status) {
      ReservationStatus.confirmed => ('Confirmed', Colors.green),
      ReservationStatus.cancelled => ('Cancelled', Colors.red),
      ReservationStatus.completed => ('Completed', Colors.grey),
      ReservationStatus.valid => ('Pending', Colors.orange),
      ReservationStatus.invalid => ('Invalid', Colors.red),
    };

    return Chip(
      label: Text(label, style: TextStyle(fontSize: 12)),
      backgroundColor: color?.withValues(alpha: 0.15),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
