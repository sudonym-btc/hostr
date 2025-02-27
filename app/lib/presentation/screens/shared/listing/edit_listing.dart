import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/presentation/screens/shared/listing/edit_listing_view.dart';

@RoutePage()
class EditListingScreen extends StatelessWidget {
  final String? a;

  // ignore: use_key_in_widget_constructors
  const EditListingScreen({
    @pathParam this.a,
  });

  @override
  Widget build(BuildContext context) {
    return EditListingView(a: a);
  }
}
