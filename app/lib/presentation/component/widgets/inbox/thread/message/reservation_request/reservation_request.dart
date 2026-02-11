import 'package:flutter/material.dart';
import 'package:hostr/export.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/inbox/thread/message/message.dart';
import 'package:hostr/presentation/component/widgets/listing/price.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

import 'guest_view.dart';
import 'host_view.dart';

class ThreadReservationRequestWidget extends ThreadMessageWidget {
  final Listing listing;
  final List<Reservation> reservations;

  ReservationRequest get reservationRequest => item.child as ReservationRequest;

  ThreadReservationRequestGuestHostComponents get viewComponents =>
      listing.pubKey != getIt<Hostr>().auth.activeKeyPair!.publicKey
      ? ThreadReservationRequestGuestViewWidget(
          counterparty: counterparty,
          item: item,
          listing: listing,
          reservations: reservations,
        )
      : ThreadReservationRequestHostViewWidget(
          counterparty: counterparty,
          item: item,
          listing: listing,
          reservations: reservations,
        );
  const ThreadReservationRequestWidget({
    super.key,
    required super.counterparty,
    required super.item,
    required this.listing,
    required this.reservations,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: isSentByMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Column(
        children: [
          ListingListItemWidget(
            listing: listing,
            showPrice: false,
            showFeedback: false,
            smallImage: true,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CustomPadding(
                right: 0,
                top: 0,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      formatDateRangeShort(
                        DateTimeRange(
                          start: reservationRequest.parsedContent.start,
                          end: reservationRequest.parsedContent.end,
                        ),
                        Localizations.localeOf(context),
                      ),
                      style: Theme.of(context).textTheme.bodyMedium!,
                    ),
                    PriceText(
                      formatAmount(reservationRequest.parsedContent.amount),
                    ),
                    viewComponents.statusText(context),
                  ],
                ),
              ),
              CustomPadding(
                top: 0,
                child: viewComponents.actionButton(context),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
