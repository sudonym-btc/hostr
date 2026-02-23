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
              ListenableBuilder(
                listenable: controller.submitListenable,
                builder: (context, _) {
                  return FilledButton(
                    onPressed: controller.canSubmit
                        ? () async {
                            await controller.save();
                          }
                        : null,
                    child: controller.isSaving
                        ? const SizedBox(
                            width: 16,
                            height: 16,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : Text(AppLocalizations.of(context)!.save),
                  );
                },
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
                        Gap.vertical.lg(),
                        FormLabel(label: 'Address'),
                        LocationField(
                          controller: controller.locationController,
                          hintText: '123 City Road, London',
                          validator: (value) =>
                              controller.locationController.validateText(
                                value,
                                emptyMessage: 'Address is required',
                              ),
                          // null => request broad + address-level results (house numbers included)
                          featureTypes: null,
                          h3Mode: LocationFieldH3Mode.addressHierarchy,
                          debounceDuration: const Duration(milliseconds: 400),
                          minQueryLength: 3,
                        ),
                        Gap.vertical.lg(),
                        FormLabel(label: 'Price'),
                        PriceInput(controller: controller),
                        BarterInput(controller: controller),
                        Gap.vertical.lg(),
                        FormLabel(label: 'Amenities'),
                        Gap.vertical.md(),
                        AmenitiesInput(controller: controller),
                        Gap.vertical.lg(),
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
