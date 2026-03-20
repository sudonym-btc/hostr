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

  static const _carouselAspectRatio = 16 / 9;

  SliverAppBar _buildHeroSliverAppBar(
    BuildContext context,
    Listing listing,
    double paneWidth,
  ) {
    return SliverAppBar(
      stretch: true,
      expandedHeight: paneWidth / _carouselAspectRatio,
      flexibleSpace: FlexibleSpaceBar(
        background: AspectRatio(
          aspectRatio: _carouselAspectRatio,
          child: ImagesInput(controller: controller, pubkey: listing.pubKey),
        ),
      ),
    );
  }

  Widget _buildFormContent(BuildContext context) {
    return CustomPadding(
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
            validator: (value) => controller.locationController.validateText(
              value,
              emptyMessage: 'Address is required',
            ),
          ),
          Gap.vertical.md(),
          FormLabel(label: 'Price'),
          PriceInput(controller: controller),
          BarterInput(controller: controller),
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
    );
  }

  Widget _buildListingPane(BuildContext context, Listing listing) {
    if (controller.l == null ||
        (listing.getDtag() != null &&
            controller.l?.getDtag() != listing.getDtag())) {
      controller.setState(listing);
    }

    final bottomBar = SaveBottomBar(
      controller: controller,
      onSave: () async {
        final saved = await controller.save();
        if (saved && context.mounted) {
          Navigator.of(context).pop();
        }
      },
    );

    return Form(
      key: controller.formKey,
      child: app_layout.AppPageGutter(
        maxWidth: app_layout.kAppWideContentMaxWidth,
        padding: EdgeInsets.zero,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final layout = app_layout.AppLayoutSpec.of(context);
            final paneWidth = layout.isExpanded
                ? constraints.maxWidth * 2 / 3
                : constraints.maxWidth;
            return app_layout.AppPaneLayout(
              totalFlex: 3,
              panes: [
                app_layout.AppPane(
                  flex: 2,
                  sliverAppBarBuilder: (context) =>
                      _buildHeroSliverAppBar(context, listing, paneWidth),
                  bottomBar: bottomBar,
                  promoteChromeWhenStacked: true,
                  child: _buildFormContent(context),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildLoadingPane() {
    return app_layout.AppPageGutter(
      maxWidth: app_layout.kAppWideContentMaxWidth,
      padding: EdgeInsets.zero,
      child: app_layout.AppPaneLayout(
        panes: [
          app_layout.AppPane(
            child: const Center(child: AppLoadingIndicator.large()),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.a == null) {
      return UnsavedChangesGuard(
        isDirty: () => controller.isDirty,
        child: _buildListingPane(context, _newListing!),
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
          return _buildLoadingPane();
        }
        return UnsavedChangesGuard(
          isDirty: () => controller.isDirty,
          child: _buildListingPane(context, state.data!),
        );
      },
    );
  }
}
