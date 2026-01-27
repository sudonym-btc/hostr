import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/export.dart';
import 'package:hostr/presentation/screens/shared/listing/edit_listing.controller.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

import 'image_picker.dart';

class EditListingView extends StatefulWidget {
  final String? a;

  const EditListingView({super.key, this.a});

  @override
  State<StatefulWidget> createState() => EditListingViewState();
}

class EditListingViewState extends State<EditListingView> {
  bool loading = false;
  final EditListingController controller = EditListingController();

  buildListing(BuildContext context, Listing l) {
    return Scaffold(
      appBar: AppBar(),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        child: CustomPadding(
          top: 0,
          bottom: 0,
          child: FilledButton(
            onPressed: loading == false
                ? () async {
                    setState(() {
                      loading = true;
                    });
                    await controller.save();
                    setState(() {
                      loading = false;
                    });
                  }
                : null,
            child: Text(AppLocalizations.of(context)!.save),
          ),
        ),
      ),
      body: Form(
        child: Column(
          children: [
            Expanded(
              child: CustomPadding(
                child: ImageUpload(
                  controller: controller.imageController,
                  pubkey: l.pubKey,
                ),
              ),
            ),
            CustomPadding(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  TextFormField(
                    controller: controller.titleController,
                    decoration: const InputDecoration(
                      labelText: 'Title',
                      hintText: 'Title',
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  AmenityTagsWidget(amenities: l.parsedContent.amenities),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: controller.descriptionController,
                    decoration: const InputDecoration(
                      labelText: 'Description',
                      hintText: 'Description',
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return widget.a == null
        ? buildListing(
            context,
            Listing.fromNostrEvent(
              Nip01Event(
                pubKey: '',
                kind: Listing.kinds.first,
                tags: [],
                content: ListingContent(
                  title: '',
                  description: '',
                  price: [
                    Price(
                      amount: Amount(currency: Currency.BTC, value: 0.00001),
                      frequency: Frequency.daily,
                    ),
                  ],
                  minStay: Duration(days: 1),
                  checkIn: TimeOfDay(hour: 11, minute: 0),
                  checkOut: TimeOfDay(hour: 11, minute: 0),
                  location: '',
                  quantity: 1,
                  type: ListingType.room,
                  images: [],
                  amenities: Amenities(),
                ).toString(),
              ),
            ),
          )
        : ListingProvider(
            a: widget.a,
            onDone: (l) => controller.setState(l),
            builder: (context, state) {
              if (state.data == null) {
                return Scaffold(
                  body: Center(child: CircularProgressIndicator()),
                );
              }
              return buildListing(context, state.data!);
            },
          );
  }
}
