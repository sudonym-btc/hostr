import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/image_picker.cubit.dart';
import 'package:hostr/logic/forms/amount_field_controller.dart';
import 'package:hostr/logic/forms/bool_field_controller.dart';
import 'package:hostr/logic/forms/image_field_controller.dart';
import 'package:hostr/logic/forms/listing_price_field_controller.dart';
import 'package:hostr/logic/forms/listing_spec_field_controller.dart';
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
  final ListingSpecFieldController specField = ListingSpecFieldController();
  final BoolFieldController activeField = BoolFieldController(initial: true);
  final BoolFieldController negotiableField = BoolFieldController();
  final AmountFieldController securityDepositField = AmountFieldController();
  final AmountFieldController minPaymentField = AmountFieldController();
  final LocationController locationController = LocationController();

  EditListingController() {
    registerField(imageField);
    registerField(titleField);
    registerField(descriptionField);
    registerField(priceField);
    registerField(specField);
    registerField(activeField);
    registerField(negotiableField);
    registerField(securityDepositField);
    registerField(minPaymentField);
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
    specField.setState(data?.specifications ?? Specifications());
    activeField.setState(data?.active ?? true);
    negotiableField.setState(data?.negotiable ?? false);
    securityDepositField.setState(data?.securityDeposit);
    minPaymentField.setState(data?.minPaymentAmount);
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
      negotiable: negotiableField.value,
      location: location,
      quantity: current.quantity,
      type: current.listingType,
      images: images,
      specifications: specField.specifications,
      instantBook: current.instantBook,
      securityDeposit: securityDepositField.amount,
      minPaymentAmount: minPaymentField.amount,
      minStay: current.minStay,
      checkIn: current.checkIn ?? '15:0',
      checkOut: current.checkOut ?? '11:0',
      extraTags: extraTags,
    );
    await getIt<Hostr>().listings.upsert(updatedListing);

    l = updatedListing;
  }
}
