import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/main.dart';
import 'package:ndk/ndk.dart';

@RoutePage()
class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
        providers: [
          BlocProvider(
              create: (context) => ListCubit<Listing>(
                  kinds: Listing.kinds, filter: Filter(pTags: ['mykey']))
                ..next()),
        ],
        child: Scaffold(
            appBar: AppBar(title: Text('My Listings')),
            body: SafeArea(
                child: Column(children: [
              Expanded(
                  child: ListWidget(
                      builder: (el) => ListingListItemWidget(
                            listing: el,
                          )))
            ]))));
  }
}
