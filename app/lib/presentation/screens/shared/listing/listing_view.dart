import 'package:auto_route/auto_route.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/export.dart';
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
    return ListingProvider(
        a: a,
        builder: (context, state) {
          if (state.data == null) {
            return Scaffold(body: Center(child: CircularProgressIndicator()));
          }
          return Scaffold(
              bottomNavigationBar: BottomAppBar(
                shape: CircularNotchedRectangle(),
                child: CustomPadding(
                    top: 0,
                    bottom: 0,
                    child: Reserve(listing: state.data!, dateRange: dateRange)),
              ),
              body: (state.data == null)
                  ? Center(child: CircularProgressIndicator())
                  : CustomScrollView(slivers: [
                      SliverAppBar(
                          stretch: true,
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
                                style: Theme.of(context).textTheme.titleLarge,
                              ),
                              const SizedBox(height: 2.0),
                              Row(children: [
                                Text('hosted by'),
                                SizedBox(width: 8),
                                ProfileChipWidget(
                                    id: state.data!.nip01Event.pubKey)
                              ]),
                              const SizedBox(height: 8.0),
                              ReviewsReservationsWidget(
                                a: a,
                              ),
                              const SizedBox(
                                height: 8,
                              ),
                              AmenityTagsWidget(
                                  amenities:
                                      state.data!.parsedContent.amenities),
                              const SizedBox(height: 16),
                              Text(state.data!.parsedContent.description,
                                  style:
                                      Theme.of(context).textTheme.bodyMedium),
                              Container(
                                  constraints: BoxConstraints(
                                    maxHeight:
                                        300.0, // Set your desired max height here
                                  ),
                                  child: BlocProvider<ListCubit<Review>>(
                                      create: (context) => ListCubit<Review>(
                                          kinds: Review.kinds,
                                          filter: Filter(eTags: [
                                            state.data!.nip01Event.id
                                          ]))
                                        ..next(),
                                      child: ListWidget<Review>(builder: (el) {
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
        });
  }
}
