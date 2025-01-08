import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';

@RoutePage()
class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(title: Text('My Listings')),
        body: SafeArea(
            child: Column(children: [
          // Expanded(
          //     child: ListWidget(
          //         list: () => ListCubit(getIt<ListingRepository>()),
          //         builder: (el) => ListingListItem(
          //               listing: el,
          //             )))
        ])));
  }
}
