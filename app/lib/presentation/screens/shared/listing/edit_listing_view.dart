import 'package:flutter/material.dart' hide TimeOfDay;
import 'package:hostr/export.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/presentation/component/widgets/ui/form_label.dart';
import 'package:hostr/presentation/forms/search/location_input.dart';
import 'package:hostr/presentation/layout/app_layout.dart' as app_layout;
import 'package:hostr/presentation/screens/shared/listing/edit_listing.controller.dart';
import 'package:hostr/presentation/screens/shared/listing/edit_listing_inputs.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

class EditListingView extends StatefulWidget {
  final String? a;

  const EditListingView({super.key, this.a});

  @override
  State<StatefulWidget> createState() => EditListingViewState();
}

class EditListingViewState extends State<EditListingView> {
  final EditListingController controller = EditListingController();
  Listing? _newListing;

  Widget wrapPage(Widget child) {
    final layout = app_layout.AppLayoutSpec.of(context);
    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: SizedBox.expand(
        child: layout.showsSidebarNavigation
            ? app_layout.AppSinglePanePage(
                maxWidth: app_layout.kAppWideContentMaxWidth,
                child: child,
              )
            : app_layout.AppConstrainedBody(
                padding: EdgeInsets.zero,
                child: child,
              ),
      ),
    );
  }

  @override
  void initState() {
    super.initState();
    if (widget.a == null) {
      _newListing = Listing.create(
        pubKey: getIt<Hostr>().auth.getActiveKey().publicKey,
        dTag: DateTime.now().millisecondsSinceEpoch.toRadixString(36),
        title: '',
        description: '',
        price: [
          Price(
            amount: Amount(currency: Currency.BTC, value: BigInt.from(100000)),
            frequency: Frequency.daily,
          ),
        ],
        location: '',
        type: ListingType.room,
        active: true,
        images: [],
        amenities: Amenities(),
      );
      controller.setState(_newListing!);
    }
  }

  Scaffold buildListing(BuildContext context, Listing l) {
    if (controller.l == null ||
        (l.getDtag() != null && controller.l?.getDtag() != l.getDtag())) {
      controller.setState(l);
    }

    return Scaffold(
      bottomNavigationBar: SaveBottomBar(
        controller: controller,
        onSave: () async {
          final saved = await controller.save();
          if (saved && context.mounted) {
            Navigator.of(context).pop();
          }
        },
      ),
      body: Form(
        key: controller.formKey,
        child: CustomScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          slivers: [
            SliverAppBar(
              stretch: true,
              expandedHeight: MediaQuery.of(context).size.height / 4,
              flexibleSpace: FlexibleSpaceBar(
                background: ImagesInput(
                  controller: controller,
                  pubkey: l.pubKey,
                ),
              ),
            ),
            SliverList(
              delegate: SliverChildListDelegate([
                CustomPadding(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      FormLabel(label: 'Title'),
                      TitleInput(controller: controller),
                      Gap.vertical.md(),
                      FormLabel(label: 'Address'),
                      LocationInput(
                        controller: controller.locationController,
                        hintText: '123 City Road, London',
                        validator: (value) =>
                            controller.locationController.validateText(
                              value,
                              emptyMessage: 'Address is required',
                            ),
                      ),
                      Gap.vertical.md(),
                      FormLabel(label: 'Price'),
                      PriceInput(controller: controller),
                      BarterInput(controller: controller),
                      HelpText(
                        'Allowing barter allows users to submit reservation requests below your listed price, which you can then accept or decline.',
                      ),
                      Gap.vertical.md(),
                      FormLabel(label: 'Amenities'),
                      Gap.vertical.md(),
                      AmenitiesInput(controller: controller),
                      Gap.vertical.md(),
                      FormLabel(label: 'Description'),
                      DescriptionInput(controller: controller),
                      if (widget.a != null) ...[
                        Gap.vertical.md(),
                        ActiveInput(controller: controller),
                        Gap.vertical.lg(),
                      ],
                    ],
                  ),
                ),
              ]),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.a == null) {
      return UnsavedChangesGuard(
        isDirty: () => controller.isDirty,
        child: wrapPage(buildListing(context, _newListing!)),
      );
    }
    return ListingProvider(
      a: widget.a,
      onDone: (l) {
        if (controller.l == null || controller.l?.id != l.id) {
          controller.setState(l);
        }
      },
      builder: (context, state) {
        if (state.data == null) {
          return wrapPage(
            const Scaffold(body: Center(child: AppLoadingIndicator.large())),
          );
        }
        return UnsavedChangesGuard(
          isDirty: () => controller.isDirty,
          child: wrapPage(buildListing(context, state.data!)),
        );
      },
    );
  }
}
