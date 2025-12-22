import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/export.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/router.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

class ListingView extends StatelessWidget {
  final String a;
  final DateTimeRange? dateRange;

  // ignore: use_key_in_widget_constructors
  ListingView(
      {required this.a,
      @queryParam String? dateRangeStart,
      @queryParam String? dateRangeEnd})
      : dateRange = dateRangeStart != null && dateRangeEnd != null
            ? DateTimeRange(
                start: DateTime.parse(dateRangeStart),
                end: DateTime.parse(dateRangeEnd),
              )
            : null;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<DateRangeCubit>(
        create: (context) => DateRangeCubit()..updateDateRange(dateRange),
        child: ListingProvider(
            a: a,
            builder: (context, state) {
              if (state.data == null) {
                return Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              }
              return Scaffold(
                  bottomNavigationBar: BottomAppBar(
                    child: CustomPadding(
                        top: 0,
                        bottom: 0,
                        child: Reserve(listing: state.data!)),
                  ),
                  body: (state.data == null)
                      ? Center(child: CircularProgressIndicator())
                      : CustomScrollView(slivers: [
                          SliverAppBar(
                              stretch: true,
                              actions: [
                                if (state.data!.nip01Event.pubKey ==
                                    getIt<KeyStorage>()
                                        .getActiveKeyPairSync()
                                        ?.publicKey)
                                  IconButton(
                                    icon: Icon(Icons.edit),
                                    onPressed: () {
                                      context.router
                                          .navigate(EditListingRoute(a: a));
                                    },
                                  ),
                              ],
                              expandedHeight:
                                  MediaQuery.of(context).size.height / 4,
                              flexibleSpace: FlexibleSpaceBar(
                                  background: ImageCarouselWidget(
                                item: state.data!,
                              ))),
                          SliverList(
                              delegate: SliverChildListDelegate(
                            [
                              CustomPadding(
                                  child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    state.data!.parsedContent.title,
                                    style:
                                        Theme.of(context).textTheme.titleLarge,
                                  ),
                                  const SizedBox(height: 2.0),
                                  Row(children: [
                                    Text(
                                        AppLocalizations.of(context)!.hostedBy),
                                    SizedBox(width: 8),
                                    Flexible(
                                        child: ProfileChipWidget(
                                            id: state.data!.nip01Event.pubKey))
                                  ]),
                                  const SizedBox(height: 8.0),
                                  ReviewsReservationsWidget(
                                    a: state.data!.anchor,
                                  ),
                                  const SizedBox(
                                    height: 8,
                                  ),
                                  AmenityTagsWidget(
                                      amenities:
                                          state.data!.parsedContent.amenities),
                                  const SizedBox(height: 16),
                                  Text(state.data!.parsedContent.description,
                                      style: Theme.of(context)
                                          .textTheme
                                          .bodyMedium),
                                  Container(
                                      constraints: BoxConstraints(
                                        maxHeight:
                                            300.0, // Set your desired max height here
                                      ),
                                      child: BlocProvider<ListCubit<Review>>(
                                          create: (context) =>
                                              ListCubit<Review>(
                                                  kinds: Review.kinds,
                                                  nostrService: getIt(),
                                                  filter: Filter(aTags: [
                                                    state.data!.anchor
                                                  ]))
                                                ..next(),
                                          child:
                                              ListWidget<Review>(builder: (el) {
                                            return ReviewListItem(
                                              review: el,
                                              // dateRange: searchController.state.dateRange,
                                            );
                                          })))
                                ],
                              ))
                            ],
                          ))
                        ]));
            }));
  }
}
