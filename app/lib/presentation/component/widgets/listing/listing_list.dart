import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/widgets/ui/list.dart';
import 'package:models/main.dart';

import 'listing_list_item.dart';

class ListingsWidget extends StatelessWidget {
  final ScrollController? scrollController;

  /// When a new id is emitted the list scrolls the matching item into view.
  final ValueNotifier<String?>? scrollToId;

  const ListingsWidget({super.key, this.scrollController, this.scrollToId});

  @override
  Widget build(BuildContext context) {
    return ListWidget<Listing>(
      loadNextOnBottom: true,
      reserveBottomNavigationBarSpace: true,
      scrollController: scrollController,
      scrollToId: scrollToId,
      builder: (el) {
        return ListingListItemWidget(
          listing: el,
          // dateRange: searchController.state.dateRange,
        );
      },
    );
  }
}
