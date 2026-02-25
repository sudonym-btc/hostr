import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/main.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

@RoutePage()
class MyListingsScreen extends StatefulWidget {
  const MyListingsScreen({super.key});

  @override
  State<MyListingsScreen> createState() => _MyListingsScreenState();
}

class _MyListingsScreenState extends State<MyListingsScreen> {
  late final ListCubit<Listing> _listCubit;
  StreamSubscription? _updatesSub;

  @override
  void initState() {
    super.initState();
    _listCubit = ListCubit<Listing>(
      kinds: Listing.kinds,
      nostrService: getIt(),
      filter: Filter(authors: [getIt<Hostr>().auth.activeKeyPair!.publicKey]),
    )..next();

    // Update the list item in-place when a listing is mutated elsewhere.
    _updatesSub = getIt<Hostr>().listings.updates.listen((listing) {
      _listCubit.upsertItem(listing);
    });
  }

  @override
  void dispose() {
    _updatesSub?.cancel();
    _listCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: _listCubit,
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.myListings),
          actions: [
            IconButton(
              icon: Icon(Icons.add),
              onPressed: () {
                AutoRouter.of(context).pushPath('edit-listing/new');
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListWidget<Listing>(
                  builder: (el) => ListingListItemWidget(listing: el),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
