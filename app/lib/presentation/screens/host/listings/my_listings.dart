import 'dart:async';

import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/main.dart';
import 'package:hostr/presentation/screens/shared/listing/edit_listing_inputs.dart';
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
  bool _placeholderPrecached = false;

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
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_placeholderPrecached) {
      _placeholderPrecached = true;
      precacheImage(NetworkImage(ImagesInput.placeholderUrl), context);
    }
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
            IconButton.filledTonal(
              icon: Icon(Icons.add),
              onPressed: () {
                AutoRouter.of(context).pushPath('edit-listing/new');
              },
            ),
          ],
        ),
        body: SafeArea(
          child: Expanded(
            child: ListWidget<Listing>(
              emptyBuilder: () => CustomPadding(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.max,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ready to list your place?',
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Gap.vertical.xs(),
                    Text(
                      'Create a listing to start welcoming guests to your property today!',
                    ),
                    Gap.vertical.lg(),
                    FilledButton(
                      onPressed: () {
                        AutoRouter.of(context).pushPath('edit-listing/new');
                      },
                      child: Text('Create a listing'),
                    ),
                  ],
                ),
              ),

              builder: (el) => ListingListItemWidget(listing: el),
            ),
          ),
        ),
      ),
    );
  }
}
