import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:hostr/presentation/screens/shared/listing/edit_listing_view.dart';
import 'package:models/main.dart';

@RoutePage()
class EditListingScreen extends StatelessWidget {
  final String? a;

  // ignore: use_key_in_widget_constructors
  EditListingScreen({@pathParam String? a})
    : a = a != null && a.startsWith('naddr') ? naddrToAnchor(a) : a;

  @override
  Widget build(BuildContext context) {
    return EditListingView(a: a);
  }
}
