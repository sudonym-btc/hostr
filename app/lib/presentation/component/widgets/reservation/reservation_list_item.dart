import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/main.dart';
import 'package:hostr/presentation/component/widgets/listing/listing_carousel.dart';
import 'package:hostr/router.dart';
import 'package:models/main.dart';

class ReservationListItem extends StatelessWidget {
  final Reservation reservation;
  const ReservationListItem({required this.reservation, super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        AutoRouter.of(context).push(ThreadRoute(id: reservation.threadAnchor));
      },
      child: ListingProvider(
        a: reservation.getATagForKind(Listing.kinds[0]),
        builder: (context, state) {
          if (state.active) return CircularProgressIndicator();
          return CustomPadding(
            child: Row(
              children: [
                SizedBox(
                  height: 100,
                  width: 100,
                  child: ListingCarousel(listing: state.data!),
                ),
                SizedBox(width: DEFAULT_PADDING.toDouble()),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        state.data!.parsedContent.title.toString(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      const SizedBox(height: 8.0),
                      Text(
                        formatDateRangeShort(
                          DateTimeRange(
                            start: reservation.parsedContent.start,
                            end: reservation.parsedContent.end,
                          ),
                          Localizations.localeOf(context),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
