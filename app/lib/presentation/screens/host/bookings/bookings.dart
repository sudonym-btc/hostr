import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/main.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

@RoutePage()
class BookingsScreen extends StatelessWidget {
  const BookingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(
          create: (context) => ListCubit<Listing>(
            kinds: Listing.kinds,
            nostrService: getIt(),
            filter: Filter(pTags: ['mykey']),
          )..next(),
        ),
      ],
      child: Scaffold(
        appBar: AppBar(
          title: Text(AppLocalizations.of(context)!.upcomingReservations),
        ),
        body: SafeArea(
          child: Column(
            children: [
              Expanded(
                child: ListWidget(
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
