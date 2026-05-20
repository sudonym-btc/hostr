import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/presentation/screens/shared/listing/listing_view.dart';
import 'package:hostr/route/listing_reservation_route.dart';
import 'package:models/main.dart';

@RoutePage()
class ListingScreen extends StatelessWidget {
  final String a;
  final DateTimeRange? dateRange;
  final DenominatedAmount? reserveAmount;
  final bool autoReserve;

  // ignore: use_key_in_widget_constructors
  ListingScreen({
    @pathParam required String a,
    @queryParam String? dateRangeStart,
    @queryParam String? dateRangeEnd,
    @queryParam String? reserveAmountValue,
    @queryParam String? reserveAmountDenomination,
    @queryParam String? reserveAmountDecimals,
    @queryParam String? autoReserve,
  }) : a = a.startsWith('naddr') ? naddrToAnchor(a) : a,
       dateRange = dateRangeStart != null && dateRangeEnd != null
           ? DateTimeRange(
               start: DateTime.parse(dateRangeStart).toUtc(),
               end: DateTime.parse(dateRangeEnd).toUtc(),
             )
           : null,
       reserveAmount = parseReserveAmountQuery(
         value: reserveAmountValue,
         denomination: reserveAmountDenomination,
         decimals: reserveAmountDecimals,
       ),
       autoReserve = parseAutoReserveQuery(autoReserve);

  @override
  Widget build(BuildContext context) {
    return ListingView(
      a: a,
      dateRange: dateRange,
      reserveAmount: reserveAmount,
      autoReserve: autoReserve,
    );
  }
}
