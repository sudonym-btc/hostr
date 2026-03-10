import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/image_picker.cubit.dart';
import 'package:hostr/logic/forms/upsert_form_controller.dart';
import 'package:hostr/presentation/forms/search/location_controller.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:models/main.dart';

class EditListingController extends UpsertFormController {
  @override
  bool get isDirty {
    if (l == null) return false;
    if (titleController.text != l!.title) return true;
    if (descriptionController.text != l!.description) return true;
    if (locationController.text != l!.location) return true;
    if (active != l!.active) return true;
    // Compare allowBarter
    final origAllowBarter = l!.allowBarter == true;
    if (allowBarter != origAllowBarter) return true;
    // Price check (strip commas for comparison)
    final currentPriceSats = priceController.text.replaceAll(',', '').trim();
    if (currentPriceSats != _originalPriceSats) return true;
    // Images check (by path)
    final origImages = l!.images;
    final currImages = imageController.images.map((i) => i.path).toList();
    if (origImages.length != currImages.length ||
        !const ListEquality<String?>().equals(origImages, currImages)) {
      return true;
    }
    return false;
  }

  Listing? l;
  String _originalPriceSats = '0';
  final ImagePickerCubit imageController = ImagePickerCubit(maxImages: 12);
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final LocationController locationController = LocationController();
  Amenities amenities = Amenities();
  Set<String> selectedAmenityKeys = {};
  Currency priceCurrency = Currency.BTC;
  bool active = true;
  bool allowBarter = false;
  late final Listenable submitListenable;

  EditListingController() {
    submitListenable = Listenable.merge([
      this,
      titleController,
      descriptionController,
      priceController,
      locationController,
      imageController.notifier,
    ]);
  }

  @override
  bool get canSubmit =>
      super.canSubmit &&
      locationController.canSubmit &&
      imageController.canSubmit;

  static List<String> amenityKeys() {
    final map = Amenities().toMap();
    final keys = map.entries
        .where((entry) => entry.value is bool)
        .map((entry) => entry.key)
        .toList();
    keys.sort();
    return keys;
  }

  void setState(Listing? data) {
    l = data;
    imageController.setImages(
      (data?.images ?? []).map((i) => CustomImage.path(i)).toList(),
    );
    titleController.text = data?.title ?? '';
    descriptionController.text = data?.description ?? '';
    locationController.updateTextFromUser(data?.location ?? '');
    locationController.clearH3();
    amenities = data?.amenities ?? Amenities();
    selectedAmenityKeys = _selectedKeysFromAmenities(amenities);
    active = data?.active ?? true;
    allowBarter = data?.allowBarter ?? false;

    final prices = data?.prices ?? [];
    final nightly = prices.firstWhere(
      (p) => p.frequency == Frequency.daily,
      orElse: () => prices.isNotEmpty
          ? prices.first
          : Price(
              amount: Amount(value: BigInt.zero, currency: Currency.BTC),
              frequency: Frequency.daily,
            ),
    );
    priceCurrency = Currency.BTC;
    final bitcoinAmount = BitcoinAmount.fromAmount(nightly.amount);
    _originalPriceSats = bitcoinAmount.getInSats.toString();
    priceController.text = _formatWithCommas(_originalPriceSats);
    notifyListeners();
  }

  void updateSelectedAmenities(Set<String> keys) {
    selectedAmenityKeys = keys;
    amenities = _amenitiesFromKeys(amenities, keys);
    notifyListeners();
  }

  void setAllowBarter(bool value) {
    if (allowBarter == value) {
      return;
    }
    allowBarter = value;
    notifyListeners();
  }

  void setActive(bool value) {
    if (active == value) {
      return;
    }
    active = value;
    notifyListeners();
  }

  Set<String> _selectedKeysFromAmenities(Amenities value) {
    final map = value.toMap();
    return map.entries
        .where((entry) => entry.value is bool && entry.value == true)
        .map((entry) => entry.key)
        .toSet();
  }

  Amenities _amenitiesFromKeys(Amenities base, Set<String> keys) {
    final map = base.toMap();
    for (final entry in map.entries) {
      if (entry.value is bool) {
        map[entry.key] = keys.contains(entry.key);
      }
    }

    return Amenities.fromJSON(map);
  }

  @override
  Future<void> preValidate() async {}

  @override
  Future<void> upsert() async {
    final title = titleController.text.trim();
    final description = descriptionController.text.trim();
    final location = locationController.text.trim();

    if (l == null) {
      throw Exception('Listing not loaded');
    }

    final current = l!;
    final images = imageController.resolvedPaths;

    final h3Tags = locationController.h3Tags;
    var extraTags = h3Tags.isEmpty
        ? l!.tags
              .where((tag) => tag.isNotEmpty && tag.first == 'g')
              .map((tag) => List<String>.from(tag))
              .toList()
        : h3Tags.map((tag) => ['g', tag.index]).toList();

    // Ensure a d-tag exists — generate one for new listings.
    final dTag =
        l!.getDtag() ?? DateTime.now().millisecondsSinceEpoch.toRadixString(36);

    final updatedListing = Listing.create(
      pubKey: getIt<Hostr>().auth.activeKeyPair!.publicKey,
      dTag: dTag,
      title: title,
      description: description,
      price: _buildUpdatedPrices(current.prices),
      active: active,
      allowBarter: allowBarter,
      location: location,
      quantity: current.quantity,
      type: current.listingType,
      images: images,
      amenities: amenities,
      requiresEscrow: current.requiresEscrow,
      minStay: current.minStay,
      checkIn: current.checkIn ?? '15:0',
      checkOut: current.checkOut ?? '11:0',
      extraTags: extraTags,
    );
    await getIt<Hostr>().listings.upsert(updatedListing);

    l = updatedListing;
  }

  String? validateTitle(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Title is required';
    }
    return null;
  }

  String? validatePrice(String? value) {
    final amount = _amountFromSatsInput(value ?? '');
    if (amount.value <= BigInt.zero) {
      return 'Enter a valid price';
    }
    return null;
  }

  String? validateDescription(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Description is required';
    }
    return null;
  }

  List<Price> _buildUpdatedPrices(List<Price> currentPrices) {
    final updatedAmount = _amountFromSatsInput(priceController.text);
    print('Updated amount: ${updatedAmount.value}');
    if (currentPrices.isEmpty) {
      return [Price(amount: updatedAmount, frequency: Frequency.daily)];
    }

    bool replaced = false;
    final updated = currentPrices.map((price) {
      if (price.frequency == Frequency.daily) {
        replaced = true;
        return Price(amount: updatedAmount, frequency: Frequency.daily);
      }
      return price;
    }).toList();

    if (!replaced) {
      updated.add(Price(amount: updatedAmount, frequency: Frequency.daily));
    }

    print(
      'Updated prices: ${updated.first.amount.value} ${updated.first.frequency}',
    );

    return updated;
  }

  Amount _amountFromSatsInput(String input) {
    final trimmed = input.replaceAll(',', '').trim();
    if (trimmed.isEmpty) {
      return Amount(value: BigInt.zero, currency: Currency.BTC);
    }

    try {
      final btcAmount = BitcoinAmount.fromBase10String(
        BitcoinUnit.sat,
        trimmed,
      );
      return btcAmount.toAmount();
    } on FormatException {
      return Amount(value: BigInt.zero, currency: Currency.BTC);
    }
  }

  static String _formatWithCommas(String digits) {
    final buf = StringBuffer();
    for (var i = 0; i < digits.length; i++) {
      final posFromEnd = digits.length - i;
      if (i > 0 && posFromEnd % 3 == 0) buf.write(',');
      buf.write(digits[i]);
    }
    return buf.toString();
  }
}
