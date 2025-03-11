import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/component/main.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

@RoutePage()
class MyListingsScreen extends StatelessWidget {
  const MyListingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
        future: getIt<KeyStorage>().getActiveKeyPair(),
        builder: (context, snapshot) {
          if (snapshot.data == null) return Container();
          return MultiBlocProvider(
              providers: [
                BlocProvider(
                    create: (context) => ListCubit<Listing>(
                        kinds: Listing.kinds,
                        filter: Filter(authors: [snapshot.data!.publicKey]))
                      ..next()),
              ],
              child: Scaffold(
                  appBar: AppBar(
                    title: Text('My Listings'),
                    actions: [
                      IconButton(
                          icon: Icon(Icons.add),
                          onPressed: () {
                            AutoRouter.of(context)
                                .pushNamed('edit-listing/234');
                          })
                    ],
                  ),
                  body: SafeArea(
                      child: Column(children: [
                    Expanded(
                        child: ListWidget<Listing>(
                            builder: (el) => ListingListItemWidget(
                                  listing: el,
                                  bottom: (BuildContext context) =>
                                      BlocProvider<ListCubit<Reservation>>(
                                    create: (context) => ListCubit<Reservation>(
                                        kinds: Reservation.kinds,
                                        filter: Filter(
                                            authors: [snapshot.data!.publicKey],
                                            aTags: [el.id]))
                                      ..next(),
                                    child: Container(child: Text('hi')),
                                  ),
                                )))
                  ]))));
        });
  }
}
