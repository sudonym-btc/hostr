import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/widgets/ui/list.dart';

import 'listing_list_item.dart';

class ListingsWidget extends StatelessWidget {
  const ListingsWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return ListWidget(builder: (el) {
      return ListingListItemWidget(
        listing: el,
        // dateRange: searchController.state.dateRange,
      );
    });
  }
}
