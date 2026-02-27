import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/presentation/component/main.dart';
import 'package:hostr/presentation/component/widgets/listing/listing_carousel.dart';
import 'package:hostr/presentation/component/widgets/listing/preload_listing_images.dart';
import 'package:hostr/router.dart';
import 'package:models/main.dart';

/// Displays a single reservation pair (one trade between guest and host).
///
/// Shows the listing image carousel, title, reservation date range, and status.
/// Tapping navigates to the inbox thread for this reservation.
class ReservationListItem extends StatelessWidget {
  /// The seller/buyer pair for this trade.
  final ReservationPairStatus reservationPair;

  const ReservationListItem({super.key, required this.reservationPair});

  @override
  Widget build(BuildContext context) {
    final representative =
        reservationPair.buyerReservation ?? reservationPair.sellerReservation;
    final listingAnchor = representative?.parsedTags.listingAnchor ?? '';
    final threadAnchor = representative?.getTags(kThreadRefTag).firstOrNull;

    final start = reservationPair.start;
    final end = reservationPair.end;
    final subtitle = (start != null && end != null)
        ? '${formatDate(start)} – ${formatDate(end)}'
        : '…';

    return ListingProvider(
      a: listingAnchor,
      builder: (context, state) {
        final listing = state.data;
        final title = listing?.parsedContent.title.toString() ?? '…';

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
                Gap.horizontal.lg(),
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
                      Gap.vertical.xs(),
                      Text(
                        subtitle,
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                      Gap.vertical.sm(),
                      _buildStatusChip(context),
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

  Widget _buildStatusChip(BuildContext context) {
    final (String label, Color? color) = switch (reservationPair) {
      _ when reservationPair.cancelled => ('Cancelled', Colors.red),
      _ when reservationPair.isCompleted => ('Completed', Colors.grey),
      _ when reservationPair.isActive => ('Confirmed', Colors.green),
      _ => ('Pending', Colors.orange),
    };

    return Chip(
      label: Text(label, style: Theme.of(context).textTheme.bodySmall),
      backgroundColor: color?.withValues(alpha: 0.15),
      side: BorderSide.none,
      visualDensity: VisualDensity.compact,
    );
  }
}
