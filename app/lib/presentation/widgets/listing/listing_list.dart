import 'package:flutter/material.dart';
import 'package:hostr/presentation/widgets/ui/list.dart';

import 'listing_list_item.dart';

class Listings extends StatelessWidget {
  const Listings({super.key});

  @override
  Widget build(BuildContext context) {
    return ListWidget(builder: (el) {
      return ListingListItem(
        listing: el,
        // dateRange: searchController.state.dateRange,
      );
    });
  }
}
