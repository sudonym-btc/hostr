import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/image_picker.cubit.dart';
import 'package:hostr/logic/forms/bool_field_controller.dart';
import 'package:hostr/logic/forms/image_field_controller.dart';
import 'package:hostr/logic/forms/listing_amenity_field_controller.dart';
import 'package:hostr/logic/forms/listing_price_field_controller.dart';
import 'package:hostr/logic/forms/text_field_controller.dart';
import 'package:hostr/logic/forms/upsert_form_controller.dart';
import 'package:hostr/presentation/forms/search/location_controller.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

class EditListingController extends UpsertFormController {
  Listing? l;

  // ── Sub-controllers ─────────────────────────────────────────────
  final ImageFieldController imageField = ImageFieldController(
    maxImages: 12,
    minImages: 1,
  );
  final TextFieldController titleField = TextFieldController(
    validator: (v) =>
        v == null || v.trim().isEmpty ? 'Title is required' : null,
  );
  final TextFieldController descriptionField = TextFieldController(
    validator: (v) =>
        v == null || v.trim().isEmpty ? 'Description is required' : null,
  );
  final ListingPriceFieldController priceField = ListingPriceFieldController();
  final ListingAmenityFieldController amenityField =
      ListingAmenityFieldController();
  final BoolFieldController activeField = BoolFieldController(initial: true);
  final BoolFieldController barterField = BoolFieldController();
  final LocationController locationController = LocationController();

  EditListingController() {
    registerField(imageField);
    registerField(titleField);
    registerField(descriptionField);
    registerField(priceField);
    registerField(amenityField);
    registerField(activeField);
    registerField(barterField);
    registerField(locationController);
  }

  // ── State initialisation ────────────────────────────────────────
  void setState(Listing? data) {
    l = data;
    imageField.setImages(
      (data?.images ?? []).map((i) => CustomImage.path(i)).toList(),
    );
    titleField.setState(data?.title ?? '');
    descriptionField.setState(data?.description ?? '');
    locationController.setState(data?.location ?? '');
    amenityField.setState(data?.amenities ?? Amenities());
    activeField.setState(data?.active ?? true);
    barterField.setState(data?.allowBarter ?? false);
    priceField.setState(data?.prices ?? []);
    notifyListeners();
  }

  // ── Upsert ──────────────────────────────────────────────────────
  @override
  Future<void> preValidate() async {}

  @override
  Future<void> upsert() async {
    final title = titleField.text.trim();
    final description = descriptionField.text.trim();
    final location = locationController.text.trim();

    if (l == null) throw Exception('Listing not loaded');

    final current = l!;
    final images = imageField.resolvedPaths;

    final h3Tags = locationController.h3Tags;
    var extraTags = h3Tags.isEmpty
        ? l!.tags
              .where((tag) => tag.isNotEmpty && tag.first == 'g')
              .map((tag) => List<String>.from(tag))
              .toList()
        : h3Tags.map((tag) => ['g', tag.index]).toList();

    final dTag =
        l!.getDtag() ?? DateTime.now().millisecondsSinceEpoch.toRadixString(36);

    final updatedListing = Listing.create(
      pubKey: getIt<Hostr>().auth.activeKeyPair!.publicKey,
      dTag: dTag,
      title: title,
      description: description,
      price: priceField.buildUpdatedPrices(current.prices),
      active: activeField.value,
      allowBarter: barterField.value,
      location: location,
      quantity: current.quantity,
      type: current.listingType,
      images: images,
      amenities: amenityField.amenities,
      requiresEscrow: current.requiresEscrow,
      minStay: current.minStay,
      checkIn: current.checkIn ?? '15:0',
      checkOut: current.checkOut ?? '11:0',
      extraTags: extraTags,
    );
    await getIt<Hostr>().listings.upsert(updatedListing);

    l = updatedListing;
  }
}
