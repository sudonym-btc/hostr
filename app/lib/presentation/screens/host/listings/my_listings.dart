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
class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ListCubit<Listing>(
            kinds: Listing.kinds,
            nostrService: getIt(),
            filter: Filter(
              authors: [getIt<Hostr>().auth.activeKeyPair!.publicKey],
            ),
          )..next(),
        ),
      ],
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
