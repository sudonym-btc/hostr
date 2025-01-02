import 'package:flutter/material.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/widgets/list.dart';

import 'listing_list_item.dart';

class Listings extends StatelessWidget {
  final CustomSearchController searchController;
  const Listings({super.key, required this.searchController});

  @override
  Widget build(BuildContext context) {
    return ListWidget(
        list: () => searchController.listCubit,
        builder: (el) {
          return ListingListItem(
            listing: el,
            dateRange: searchController.state.dateRange,
          );
        });
  }
}
