import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/widgets/ui/list.dart';
import 'package:models/main.dart';

import 'listing_list_item.dart';

class ListingsWidget extends StatelessWidget {
  final ScrollController? scrollController;

  const ListingsWidget({super.key, this.scrollController});

  @override
  Widget build(BuildContext context) {
    return ListWidget<Listing>(
      loadNextOnBottom: true,
      reserveBottomNavigationBarSpace: true,
      scrollController: scrollController,
      builder: (el) {
        return ListingListItemWidget(
          listing: el,
          // dateRange: searchController.state.dateRange,
        );
      },
    );
  }
}
