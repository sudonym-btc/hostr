import 'package:auto_route/auto_route.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:dart_nostr/dart_nostr.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/main.dart';
import 'package:hostr/presentation/widgets/main.dart';

@RoutePage()
class ListingScreen extends StatelessWidget {
  final String id;
  final DateTimeRange? dateRange;

  ListingScreen(
      {@pathParam required this.id,
      @queryParam String? dateRangeStart,
      @queryParam String? dateRangeEnd})
      : dateRange = dateRangeStart != null && dateRangeEnd != null
            ? DateTimeRange(
                start: DateTime.parse(dateRangeStart),
                end: DateTime.parse(dateRangeEnd),
              )
            : null {
    print("ListingScreen: $dateRangeStart $dateRangeEnd");
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<EntityCubit<Listing, ListingRepository>>(
        create: (context) => EntityCubit(getIt<ListingRepository>())
          ..setFilter(NostrFilter())
          ..get(),
        child: BlocBuilder<EntityCubit<Listing, ListingRepository>,
            EntityCubitState>(builder: (context, state) {
          return Scaffold(
              bottomNavigationBar: state.data != null
                  ? BottomAppBar(
                      child: Reserve(
                        listing: state.data,
                        dateRange: dateRange,
                      ),
                    )
                  : null,
              appBar: AppBar(),
              body: SafeArea(
                  child: (state.data == null)
                      ? Center(child: CircularProgressIndicator())
                      : SingleChildScrollView(
                          child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CarouselSlider(
                              options: CarouselOptions(
                                  viewportFraction: 1, padEnds: false),
                              items: state.data.images.map<Widget>((i) {
                                return Builder(
                                  builder: (BuildContext context) {
                                    return Image.network(i);
                                  },
                                );
                              }).toList(),
                            ),
                            Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      state.data.type + ' hosted by ',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge,
                                    ),
                                    const SizedBox(height: 8.0),
                                    AmenityTags(
                                        amenities: state.data.amenities),
                                    const SizedBox(height: 8.0),
                                    Text(state.data.description,
                                        style: Theme.of(context)
                                            .textTheme
                                            .bodyMedium),
                                  ],
                                ))
                          ],
                        ))));
        }));
  }
}

class Reserve extends StatelessWidget {
  final Listing listing;
  final DateTimeRange? dateRange;
  const Reserve({super.key, required this.listing, this.dateRange});

  @override
  Widget build(BuildContext context) {
    print(dateRange);
    if (dateRange == null) {
      return Container();
    }

    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      dateRange != null
          ? Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    "\$${listing.amountPerDay * (dateRange!.start.difference(dateRange!.end).inDays + 1)} total"),
                Text(
                    '${formatDate(dateRange!.start)} - ${formatDate(dateRange!.end)}')
              ],
            )
          : Text('Select dates'),
      ElevatedButton(
          onPressed: () {
            // var m = MessageType0.fromPartialData(
            //     start: searchController.state.filters
            //         .firstWhere((element) => element.key == 'start')
            //         .value,
            //     end: searchController.state.filters
            //         .firstWhere((element) => element.key == 'end')
            //         .value,
            //     hostPubKey: listing.nostrEvent.pubkey,
            //     listingId: listing.nostrEvent.id);
            // getIt<MessageRepository>().create(m);
          },
          child: Text('Reserve'))
    ]);
  }
}
