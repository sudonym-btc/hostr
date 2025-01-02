import 'package:flutter/material.dart';
import 'package:widgetbook_annotation/widgetbook_annotation.dart' as widgetbook;

// Import the widget from your app
import 'package:hostr/export.dart';

@widgetbook.UseCase(name: 'Default', type: Listings)
Widget listings(BuildContext context) {
  CustomSearchController searchController = CustomSearchController();
  return Listings(
    searchController: searchController,
  );
}
