import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/main.dart';
import 'package:hostr/presentation/component/widgets/listing/listing_carousel.dart';
import 'package:hostr/router.dart';
import 'package:models/main.dart';

class ReservationListItem extends StatelessWidget {
  final List<Reservation> reservations;
  const ReservationListItem({required this.reservations, super.key});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        AutoRouter.of(
          context,
        ).push(ThreadRoute(anchor: reservations.first.threadAnchor));
      },
      child: ListingProvider(
        a: reservations.first.listingAnchor,
        builder: (context, state) {
          if (state.active) return CircularProgressIndicator();
          return CustomPadding(
            child: Row(
              children: [
                SmallListingCarousel(
                  width: 100,
                  height: 100,
                  listing: state.data!,
                ),
                SizedBox(width: kDefaultPadding.toDouble()),
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
                      const SizedBox(height: 4.0),
                      Text(
                        formatDateRangeShort(
                          DateTimeRange(
                            start: reservations.first.parsedContent.start,
                            end: reservations.first.parsedContent.end,
                          ),
                          Localizations.localeOf(context),
                        ),
                      ),
                      const CustomPadding(top: 0.2, bottom: 0),
                      FilledButton.tonal(
                        onPressed: null,
                        child: Text('Paid'),
                        style: FilledButton.styleFrom(
                          visualDensity: VisualDensity.compact,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                      ),
                      const CustomPadding(top: 0.2, bottom: 0),

                      Row(
                        children: [
                          FilledButton.tonal(
                            onPressed: () {},
                            child: Text('Refund'),
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                          const CustomPadding(
                            right: 0.2,
                            left: 0,
                            top: 0,
                            bottom: 0,
                          ),
                          FilledButton.tonal(
                            onPressed: () {},
                            child: Text('Escrow'),
                            style: FilledButton.styleFrom(
                              visualDensity: VisualDensity.compact,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
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

// class ReservationListActionMatrix {
//   final Reservation? sellerReservation;
//   final Reservation? buyerReservation;
//   final PaymentState

//   canRefund() {

//   }

//   canContactEscrow() {

//   }
// }
