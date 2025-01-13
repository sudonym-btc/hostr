import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/presentation/screens/shared/listing/listing_view.dart';

@RoutePage()
class ListingScreen extends StatelessWidget {
  final String a;
  final DateTimeRange? dateRange;

  // ignore: use_key_in_widget_constructors
  ListingScreen(
      {@pathParam required this.a,
      @queryParam String? dateRangeStart,
      @queryParam String? dateRangeEnd})
      : dateRange = dateRangeStart != null && dateRangeEnd != null
            ? DateTimeRange(
                start: DateTime.parse(dateRangeStart),
                end: DateTime.parse(dateRangeEnd),
              )
            : null;

  @override
  Widget build(BuildContext context) {
    return ListingView(a: a);
  }
}
