import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:hostr/core/util/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/cubit/image_picker.cubit.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

class EditListingController {
  CustomLogger logger = CustomLogger();
  Listing? l;
  final ImagePickerCubit imageController = ImagePickerCubit(maxImages: 12);
  final TextEditingController titleController = TextEditingController();
  final TextEditingController descriptionController = TextEditingController();
  final TextEditingController priceController = TextEditingController();
  final TextEditingController locationController = TextEditingController();
  Amenities amenities = Amenities();
  Set<String> selectedAmenityKeys = {};
  Currency priceCurrency = Currency.BTC;

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
      (data?.parsedContent.images ?? [])
          .map((i) => CustomImage.path(i))
          .toList(),
    );
    titleController.text = data?.parsedContent.title ?? '';
    descriptionController.text = data?.parsedContent.description ?? '';
    locationController.text = data?.parsedContent.location ?? '';
    amenities = data?.parsedContent.amenities ?? Amenities();
    selectedAmenityKeys = _selectedKeysFromAmenities(amenities);

    final prices = data?.parsedContent.price ?? [];
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
    priceController.text = bitcoinAmount.getInSats.toString();
  }

  void updateSelectedAmenities(Set<String> keys) {
    selectedAmenityKeys = keys;
    amenities = _amenitiesFromKeys(amenities, keys);
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

    final updated = Amenities.fromJSON(map);
    return updated is Amenities ? updated : base;
  }

  Future<void> uploadImagesToBlossom() async {
    for (var i = 0; i < imageController.images.length; i++) {
      final image = imageController.images[i];
      if (image.file == null) {
        continue;
      }

      try {
        print('Uploading image to Blossom: ${image.file!.path}');
        final data = await image.file!.readAsBytes();
        final results = await getIt<Ndk>().blossom.uploadBlob(data: data);
        for (final result in results) {
          if (!result.success) {
            throw result.error ??
                Exception('Unknown error uploading to Blossom');
          }
          print('Blossom upload result: ${result.error}');
        }
        final imagePath = sha256.convert(data).toString();
        imageController.images[i] = CustomImage.path(imagePath);
      } catch (e, st) {
        logger.e('Failed to upload image to Blossom', error: e, stackTrace: st);
        // Best-effort upload; keep local image if upload fails.
        rethrow;
      }
    }
  }

  Future<void> save() async {
    await uploadImagesToBlossom();

    final title = titleController.text;
    final description = descriptionController.text;
    final location = locationController.text;

    if (l == null) {
      throw Exception('Listing not loaded');
    }

    final current = l!.parsedContent;
    final images = imageController.images
        .map((image) => image.path)
        .whereType<String>()
        .toList();

    final updatedContent = ListingContent(
      title: title,
      description: description,
      price: _buildUpdatedPrices(current.price),
      allowBarter: current.allowBarter,
      minStay: current.minStay,
      checkIn: current.checkIn,
      checkOut: current.checkOut,
      location: location,
      quantity: current.quantity,
      type: current.type,
      images: images,
      amenities: amenities,
      requiresEscrow: current.requiresEscrow,
    );

    final signed = await getIt<Ndk>().accounts.sign(
      Nip01Event(
        kind: Listing.kinds.first,
        tags: l!.tags.map((tag) => List<String>.from(tag)).toList(),
        content: updatedContent.toString(),
        pubKey: getIt<Ndk>().accounts.getPublicKey()!,
      ),
    );

    final updatedListing = Listing.fromNostrEvent(signed);
    await getIt<Hostr>().listings.update(updatedListing);
    l = updatedListing;
  }

  List<Price> _buildUpdatedPrices(List<Price> currentPrices) {
    final updatedAmount = _amountFromSatsInput(priceController.text);

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

    return updated;
  }

  Amount _amountFromSatsInput(String input) {
    final trimmed = input.trim();
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
}
