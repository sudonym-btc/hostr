import 'package:flutter/material.dart';
import 'package:hostr/export.dart';
import 'package:ndk/ndk.dart';

import 'image_picker.dart';

class EditListingView extends StatelessWidget {
  final String? a;

  // ignore: use_key_in_widget_constructors
  const EditListingView({this.a});

  buildListing(BuildContext context, Listing l) {
    return Scaffold(
        bottomNavigationBar: BottomAppBar(
            shape: CircularNotchedRectangle(),
            child: CustomPadding(
                top: 0,
                bottom: 0,
                child: FilledButton(
                  onPressed: () {
                    // ignore: avoid_print
                    print('Save');
                  },
                  child: Text('Save'),
                ))),
        body: Form(
            child: Column(
          children: [
            Expanded(
                child: CustomPadding(
              child: ImageUpload(),
            )),
            CustomPadding(
                child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: l.parsedContent.title,
                  decoration: const InputDecoration(
                      labelText: 'Title', hintText: 'Title'),
                ),
                const SizedBox(height: 8.0),
                AmenityTagsWidget(amenities: l.parsedContent.amenities),
                const SizedBox(height: 16),
                TextFormField(
                  initialValue: l.parsedContent.description,
                  decoration: const InputDecoration(
                      labelText: 'Description', hintText: 'Description'),
                ),
              ],
            ))
          ],
        )));
  }

  @override
  Widget build(BuildContext context) {
    return a == null
        ? buildListing(
            context,
            Listing.fromNostrEvent(Nip01Event(
                pubKey: '',
                kind: Listing.kinds.first,
                tags: [],
                content: ListingContent(
                        title: '',
                        description: '',
                        price: [
                          Price(
                              amount: Amount(
                                  currency: Currency.BTC, value: 0.00001),
                              frequency: Frequency.daily)
                        ],
                        minStay: Duration(days: 1),
                        checkIn: TimeOfDay(hour: 11, minute: 0),
                        checkOut: TimeOfDay(hour: 11, minute: 0),
                        location: '',
                        quantity: 1,
                        type: ListingType.room,
                        images: [],
                        amenities: Amenities())
                    .toString())))
        : ListingProvider(
            a: a,
            builder: (context, state) {
              if (state.data == null) {
                return Scaffold(
                    body: Center(child: CircularProgressIndicator()));
              }
              return buildListing(context, state.data!);
            });
  }
}
