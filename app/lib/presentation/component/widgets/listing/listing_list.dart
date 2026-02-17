import 'package:flutter/material.dart';
import 'package:hostr/presentation/component/widgets/ui/list.dart';
import 'package:models/main.dart';
import 'package:sliding_up_panel/sliding_up_panel.dart';

import 'listing_list_item.dart';

class ListingsWidget extends StatelessWidget {
  final PanelController panelController;
  const ListingsWidget({super.key, required this.panelController});

  @override
  Widget build(BuildContext context) {
    return ListWidget<Listing>(
      loadNextOnBottom: true,
      reserveBottomNavigationBarSpace: true,
      builder: (el) {
        return ListingListItemWidget(
          listing: el,
          // dateRange: searchController.state.dateRange,
        );
      },
    );
  }
}
