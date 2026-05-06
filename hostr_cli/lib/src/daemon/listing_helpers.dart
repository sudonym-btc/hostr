import 'dart:io';
import 'dart:typed_data';

import 'package:crypto/crypto.dart' as crypto;
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:mime/mime.dart';
import 'package:models/main.dart';
import 'package:ndk/ndk.dart';

import '../output/result.dart';

Map<String, Object?> listingSummary(Listing listing) => {
  'id': listing.id,
  'anchor': listing.anchor,
  'pubkey': listing.pubKey,
  'title': listing.title,
  'description': listing.description,
  'active': listing.active,
  'type': listing.listingType.name,
  'images': listing.images,
  'prices': listing.prices.map(priceJson).toList(),
  'specifications': listing.specifications.toMap(),
  'location': listing.location,
  'tags': listing.tags,
};

Map<String, Object?> priceJson(Price price) => {
  'amount': amountJson(price.amount),
  if (price.frequency != null) 'frequency': price.frequency!.name,
};

Map<String, Object?> amountJson(DenominatedAmount amount) => {
  'value': amount.toDecimalString(),
  'smallestUnitValue': amount.value.toString(),
  'denomination': amount.denomination,
  'decimals': amount.decimals,
};

Map<String, Object?> eventJson(Nip01Event event) =>
    Nip01EventModel.fromEntity(event).toJson();

Map<String, Object?> relayResponseJson(dynamic response) => {
  'relayUrl': response.relayUrl,
  'okReceived': response.okReceived,
  'broadcastSuccessful': response.broadcastSuccessful,
  'message': response.msg,
};

Listing buildListingFromInput({
  required String pubkey,
  required Map<String, dynamic> input,
  required List<String> images,
  required List<IMeta> imageMetas,
  required List<H3Tag> h3Tags,
}) {
  if (images.isEmpty) {
    throw HostrCliException(
      'images_required',
      'Listings require at least one image.',
      path: 'images',
      exitCode: 64,
    );
  }
  final prices = parsePrices(input);
  final securityDeposit = parseOptionalAmount(
    input['securityDeposit'],
    'securityDeposit',
  );
  final minPaymentAmount = parseOptionalAmount(
    input['minPaymentAmount'],
    'minPaymentAmount',
  );
  assertSingleDenomination([
    ...prices.map((price) => price.amount),
    ?securityDeposit,
    ?minPaymentAmount,
  ]);

  return Listing.create(
    pubKey: pubkey,
    dTag:
        input['dTag']?.toString() ??
        DateTime.now().microsecondsSinceEpoch.toRadixString(36),
    title: _requiredString(input, 'title'),
    description: _requiredString(input, 'description'),
    images: images,
    imageMetas: imageMetas,
    price: prices,
    location: '',
    type: listingType(input['type']?.toString() ?? 'room'),
    specifications: buildSpecifications(input),
    active: optionalBool(input['active']) ?? true,
    negotiable: optionalBool(input['negotiable']) ?? false,
    minStay: optionalInt(input['minStay']) ?? 1,
    checkIn: input['checkIn']?.toString() ?? '15:0',
    checkOut: input['checkOut']?.toString() ?? '11:0',
    quantity: optionalInt(input['quantity']) ?? 1,
    instantBook: optionalBool(input['instantBook']) ?? true,
    securityDeposit: securityDeposit,
    minPaymentAmount: minPaymentAmount,
    extraTags: h3Tags.map((tag) => ['g', tag.index]).toList(),
  );
}

Specifications buildSpecifications(Map<String, dynamic> input) {
  final specs = <String, dynamic>{};
  final source = input['specifications'] ?? input['specs'];
  if (source is Map) {
    for (final entry in source.entries) {
      specs[entry.key.toString()] = entry.value;
    }
  }
  for (final key in const [
    'max_guests',
    'guests',
    'beds',
    'bedrooms',
    'bathrooms',
  ]) {
    final value = optionalInt(input[key]);
    if (value != null) {
      specs[key == 'guests' ? 'max_guests' : key] = value;
    }
  }
  return Specifications(specs);
}

List<Price> parsePrices(Map<String, dynamic> input) {
  final raw = input['prices'] ?? input['price'];
  final items = raw is List ? raw : [raw];
  final prices = items
      .where((item) => item != null)
      .map((item) => parsePrice(item))
      .toList();
  if (prices.isEmpty) {
    throw HostrCliException(
      'price_required',
      'Listings require at least one price.',
      path: 'price',
      exitCode: 64,
    );
  }
  return prices;
}

Price parsePrice(dynamic value) {
  if (value is! Map) {
    throw HostrCliException(
      'invalid_price',
      'Price must be an object.',
      path: 'price',
      exitCode: 64,
    );
  }
  final map = Map<String, dynamic>.from(value);
  return Price(
    amount: parseAmount(map['amount'] ?? map, 'price.amount'),
    frequency: parseFrequency(map['frequency']?.toString()),
  );
}

Frequency? parseFrequency(String? input) {
  if (input == null || input.trim().isEmpty) return Frequency.daily;
  switch (input.trim().toLowerCase()) {
    case 'daily':
    case 'day':
    case 'night':
    case 'nightly':
      return Frequency.daily;
    case 'weekly':
    case 'week':
      return Frequency.weekly;
    case 'monthly':
    case 'month':
      return Frequency.monthly;
    case 'yearly':
    case 'year':
      return Frequency.yearly;
    case 'fixed':
    case 'once':
    case 'one_time':
      return null;
    default:
      throw HostrCliException(
        'invalid_frequency',
        'Unsupported frequency "$input".',
        path: 'frequency',
        exitCode: 64,
      );
  }
}

DenominatedAmount? parseOptionalAmount(dynamic value, String path) {
  if (value == null) return null;
  return parseAmount(value, path);
}

DenominatedAmount parseAmount(dynamic value, String path) {
  if (value is num || value is String) {
    throw HostrCliException(
      'currency_required',
      'Amount at "$path" must include a currency/denomination.',
      path: path,
      exitCode: 64,
    );
  }
  if (value is! Map) {
    throw HostrCliException(
      'invalid_amount',
      'Amount at "$path" must be an object.',
      path: path,
      exitCode: 64,
    );
  }
  final map = Map<String, dynamic>.from(value);
  final currency = (map['currency'] ?? map['denomination'])
      ?.toString()
      .toUpperCase();
  if (currency == null || currency.isEmpty) {
    throw HostrCliException(
      'currency_required',
      'Amount at "$path" must include currency.',
      path: path,
      exitCode: 64,
    );
  }
  final rawValue = map['value'] ?? map['amount'];
  if (rawValue == null) {
    throw HostrCliException(
      'amount_required',
      'Amount at "$path" must include value.',
      path: path,
      exitCode: 64,
    );
  }
  final unit = map['unit']?.toString().toLowerCase();
  if (currency == 'BTC' &&
      (unit == 'sat' || unit == 'sats' || unit == 'satoshis')) {
    return DenominatedAmount(
      denomination: 'BTC',
      value: BigInt.parse(rawValue.toString()),
      decimals: DenominatedAmount.decimalsFor('BTC'),
    );
  }
  final decimals =
      int.tryParse(map['decimals']?.toString() ?? '') ??
      DenominatedAmount.decimalsFor(currency);
  return DenominatedAmount.fromDecimal(rawValue.toString(), currency, decimals);
}

void assertSingleDenomination(List<DenominatedAmount> amounts) {
  final denominations = amounts.map((amount) => amount.denomination).toSet();
  if (denominations.length > 1) {
    throw HostrCliException(
      'mixed_currencies',
      'All listing monetary fields must use the same currency.',
      details: {'currencies': denominations.toList()},
      exitCode: 64,
    );
  }
}

Future<List<H3Tag>> addressH3Tags(
  Hostr hostr,
  Map<String, dynamic> input,
) async {
  final rawTags = input['h3Tags'];
  if (rawTags is List && rawTags.isNotEmpty) {
    return rawTags
        .map((value) => H3Tag(index: value.toString(), resolution: 0))
        .toList();
  }
  final address = input['address']?.toString();
  if (address == null || address.trim().isEmpty) {
    throw HostrCliException(
      'address_required',
      'Listing creation requires an address so H3 hierarchy tags can be generated.',
      path: 'address',
      exitCode: 64,
    );
  }
  final point = await hostr.location.point(address);
  return H3Engine.bundled().hierarchy.hierarchyForPointTags(
    latitude: point.latitude,
    longitude: point.longitude,
    finestResolution: optionalInt(input['h3FinestResolution']) ?? 15,
    maxTags: optionalInt(input['h3MaxTags']),
  );
}

class MaterializedImages {
  const MaterializedImages({
    required this.urls,
    required this.metas,
    required this.plannedUploads,
  });

  final List<String> urls;
  final List<IMeta> metas;
  final List<Map<String, Object?>> plannedUploads;
}

Future<MaterializedImages> materializeListingImages({
  required Hostr hostr,
  required List<dynamic> rawImages,
  required bool dryRun,
}) async {
  if (rawImages.isEmpty) {
    throw HostrCliException(
      'images_required',
      'Listings require at least one image.',
      path: 'images',
      exitCode: 64,
    );
  }
  final urls = <String>[];
  final metas = <IMeta>[];
  final planned = <Map<String, Object?>>[];
  for (var index = 0; index < rawImages.length; index++) {
    final raw = rawImages[index];
    final image = raw is Map
        ? Map<String, dynamic>.from(raw)
        : {'url': raw.toString()};
    final url = image['url']?.toString();
    final filePath = image['path']?.toString();
    final alt = image['alt']?.toString();
    if (url != null &&
        (url.startsWith('http://') || url.startsWith('https://'))) {
      urls.add(url);
      metas.add(IMeta(url: url, alt: alt, mime: image['mime']?.toString()));
      continue;
    }
    final effectivePath = filePath ?? url;
    if (effectivePath == null || effectivePath.trim().isEmpty) {
      throw HostrCliException(
        'invalid_image',
        'Image ${index + 1} must include url or path.',
        path: 'images[$index]',
        exitCode: 64,
      );
    }
    final file = File(effectivePath);
    if (!await file.exists()) {
      throw HostrCliException(
        'image_not_found',
        'Image file does not exist: $effectivePath',
        path: 'images[$index]',
        exitCode: 64,
      );
    }
    final bytes = await file.readAsBytes();
    final hash = crypto.sha256.convert(bytes).toString();
    final mime =
        image['mime']?.toString() ??
        lookupMimeType(file.path, headerBytes: bytes);
    planned.add({
      'path': file.path,
      'sha256': hash,
      'size': bytes.length,
      'mime': mime,
      'dryRunOnly': dryRun,
    });
    if (dryRun) {
      final plannedUrl = 'blossom://dry-run/$hash';
      urls.add(plannedUrl);
      metas.add(
        IMeta(
          url: plannedUrl,
          sha256: hash,
          size: bytes.length,
          mime: mime,
          alt: alt,
        ),
      );
      continue;
    }
    final uploadResults = await hostr.blossom.uploadBlob(
      data: Uint8List.fromList(bytes),
      contentType: mime,
    );
    final success = uploadResults
        .where((result) => result.success && result.descriptor != null)
        .map((result) => result.descriptor!)
        .firstOrNull;
    if (success == null) {
      throw HostrCliException(
        'image_upload_failed',
        'Blossom upload failed for $effectivePath.',
        details: uploadResults
            .map(
              (result) => {
                'serverUrl': result.serverUrl,
                'success': result.success,
                'error': result.error,
              },
            )
            .toList(),
      );
    }
    urls.add(success.url);
    metas.add(
      IMeta(
        url: success.url,
        sha256: success.sha256,
        size: success.size,
        mime: success.type ?? mime,
        alt: alt,
      ),
    );
  }
  return MaterializedImages(urls: urls, metas: metas, plannedUploads: planned);
}

ListingType listingType(String input) {
  return ListingType.values.firstWhere(
    (type) => type.name == input.trim().toLowerCase(),
    orElse: () => throw HostrCliException(
      'invalid_listing_type',
      'Unsupported listing type "$input".',
      path: 'type',
      exitCode: 64,
    ),
  );
}

int? optionalInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  return int.tryParse(value.toString());
}

bool? optionalBool(dynamic value) {
  if (value == null) return null;
  if (value is bool) return value;
  final normalized = value.toString().toLowerCase();
  if (normalized == 'true' || normalized == 'yes' || normalized == '1') {
    return true;
  }
  if (normalized == 'false' || normalized == 'no' || normalized == '0') {
    return false;
  }
  return null;
}

String _requiredString(Map<String, dynamic> input, String key) {
  final value = input[key]?.toString();
  if (value == null || value.trim().isEmpty) {
    throw HostrCliException(
      'missing_$key',
      'Listing requires "$key".',
      path: key,
      exitCode: 64,
    );
  }
  return value;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
