import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:hostr/_localization/app_localizations.dart';
import 'package:hostr/export.dart';
import 'package:hostr/presentation/component/widgets/ui/form_label.dart';
import 'package:hostr/presentation/screens/shared/listing/edit_listing.controller.dart';
import 'package:hostr/presentation/screens/shared/listing/edit_listing_inputs.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

class EditListingView extends StatefulWidget {
  final String? a;

  const EditListingView({super.key, this.a});

  @override
  State<StatefulWidget> createState() => EditListingViewState();
}

class EditListingViewState extends State<EditListingView> {
  bool loading = false;
  final EditListingController controller = EditListingController();

  Scaffold buildListing(BuildContext context, Listing l) {
    if (controller.l == null ||
        (l.getDtag() != null && controller.l?.getDtag() != l.getDtag())) {
      controller.setState(l);
    }

    return Scaffold(
      appBar: AppBar(),
      bottomNavigationBar: BottomAppBar(
        shape: CircularNotchedRectangle(),
        child: CustomPadding(
          top: 0,
          bottom: 0,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              FilledButton(
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
            ],
          ),
        ),
      ),
      body: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => FocusScope.of(context).unfocus(),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Form(
              key: controller.formKey,
              child: Column(
                children: [
                  CustomPadding(
                    top: 1,
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: ImagesInput(
                      controller: controller,
                      pubkey: l.pubKey,
                    ),
                  ),
                  CustomPadding(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FormLabel(label: 'Title'),
                        TitleInput(controller: controller),
                        SizedBox(height: kDefaultPadding.toDouble()),
                        FormLabel(label: 'Address'),
                        LocationInput(controller: controller),
                        SizedBox(height: kDefaultPadding.toDouble()),
                        FormLabel(label: 'Price'),
                        PriceInput(controller: controller),
                        PriceInput(controller: controller),
                        SizedBox(height: kDefaultPadding.toDouble()),
                        FormLabel(label: 'Amenities'),
                        AmenitiesInput(controller: controller),
                        SizedBox(height: kDefaultPadding.toDouble() / 2),
                        AmenitiesInput(controller: controller),
                        SizedBox(height: kDefaultPadding.toDouble()),
                        FormLabel(label: 'Description'),
                        DescriptionInput(controller: controller),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
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
                      amount: Amount(
                        currency: Currency.BTC,
                        value: BigInt.from(100000),
                      ),
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
                  requiresEscrow: false,
                ).toString(),
              ),
            ),
          )
        : ListingProvider(
            a: widget.a,
            onDone: (l) {
              if (controller.l == null || controller.l?.id != l.id) {
                controller.setState(l);
              }
            },
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
