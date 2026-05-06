import 'dart:convert';
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
  const maxDownloadBytes = 20 * 1024 * 1024;
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
    final dataUrl =
        image['dataUrl']?.toString() ?? image['dataUri']?.toString();
    final base64Data = image['base64']?.toString() ?? image['data']?.toString();
    final filePath = image['path']?.toString();
    final filename = image['filename']?.toString() ?? image['name']?.toString();
    final alt = image['alt']?.toString();
    final sourceUrl =
        url != null && (url.startsWith('http://') || url.startsWith('https://'))
        ? url
        : null;

    final dataUrlSource =
        dataUrl ?? (url?.startsWith('data:') == true ? url : null);
    final imageData = sourceUrl != null
        ? await _imageDataFromHttpUrl(
            sourceUrl,
            index,
            maxBytes: maxDownloadBytes,
          )
        : dataUrlSource != null
        ? _imageDataFromDataUrl(dataUrlSource, index)
        : base64Data != null
        ? _imageDataFromBase64(
            base64Data,
            index,
            mime: image['mime']?.toString(),
            filename: filename,
          )
        : null;
    Uint8List bytes;
    String? mime;
    String source;
    String? path;
    String? originalUrl;
    if (imageData != null) {
      bytes = imageData.bytes;
      mime = image['mime']?.toString() ?? imageData.mime;
      source = sourceUrl != null
          ? 'url'
          : dataUrlSource != null
          ? 'dataUrl'
          : 'base64';
      originalUrl = sourceUrl;
    } else {
      final effectivePath = filePath ?? url;
      if (effectivePath == null || effectivePath.trim().isEmpty) {
        throw HostrCliException(
          'invalid_image',
          'Image ${index + 1} must include url, path, dataUrl, or base64.',
          path: 'images[$index]',
          exitCode: 64,
        );
      }
      final file = File(effectivePath);
      if (!await file.exists()) {
        throw HostrCliException(
          'image_not_found',
          'Image file does not exist: $effectivePath. For web or remote MCP clients, pass a public HTTP(S) image URL, dataUrl, or base64 image bytes instead of a client-local path.',
          path: 'images[$index]',
          exitCode: 64,
        );
      }
      bytes = await file.readAsBytes();
      mime =
          image['mime']?.toString() ??
          lookupMimeType(file.path, headerBytes: bytes);
      source = 'path';
      path = file.path;
    }

    if (bytes.isEmpty) {
      throw HostrCliException(
        'invalid_image',
        'Image ${index + 1} is empty.',
        path: 'images[$index]',
        exitCode: 64,
      );
    }
    final hash = crypto.sha256.convert(bytes).toString();
    final uploadPlan = <String, Object?>{
      'source': source,
      'sha256': hash,
      'size': bytes.length,
      'mime': mime,
      'dryRunOnly': dryRun,
    };
    if (path != null) uploadPlan['path'] = path;
    if (originalUrl != null) uploadPlan['url'] = originalUrl;
    if (filename != null) uploadPlan['filename'] = filename;
    planned.add(uploadPlan);
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
      data: bytes,
      contentType: mime,
    );
    final success = uploadResults
        .where((result) => result.success && result.descriptor != null)
        .map((result) => result.descriptor!)
        .firstOrNull;
    if (success == null) {
      throw HostrCliException(
        'image_upload_failed',
        'Blossom upload failed for image ${index + 1}.',
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

class _ImageData {
  const _ImageData({required this.bytes, this.mime});

  final Uint8List bytes;
  final String? mime;
}

Future<_ImageData> _imageDataFromHttpUrl(
  String url,
  int index, {
  required int maxBytes,
}) async {
  final uri = Uri.tryParse(url);
  if (uri == null || !(uri.isScheme('http') || uri.isScheme('https'))) {
    throw HostrCliException(
      'invalid_image_url',
      'Image ${index + 1} URL must be HTTP(S).',
      path: 'images[$index].url',
      exitCode: 64,
    );
  }
  final client = HttpClient();
  try {
    final request = await client.getUrl(uri);
    request.followRedirects = true;
    final response = await request.close();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HostrCliException(
        'image_download_failed',
        'Image ${index + 1} URL returned HTTP ${response.statusCode}.',
        path: 'images[$index].url',
        exitCode: 64,
      );
    }
    if (response.contentLength > maxBytes) {
      throw HostrCliException(
        'image_too_large',
        'Image ${index + 1} exceeds the ${maxBytes ~/ (1024 * 1024)} MB limit.',
        path: 'images[$index].url',
        exitCode: 64,
      );
    }
    final chunks = <List<int>>[];
    var total = 0;
    await for (final chunk in response) {
      total += chunk.length;
      if (total > maxBytes) {
        throw HostrCliException(
          'image_too_large',
          'Image ${index + 1} exceeds the ${maxBytes ~/ (1024 * 1024)} MB limit.',
          path: 'images[$index].url',
          exitCode: 64,
        );
      }
      chunks.add(chunk);
    }
    final bytes = Uint8List(total);
    var offset = 0;
    for (final chunk in chunks) {
      bytes.setRange(offset, offset + chunk.length, chunk);
      offset += chunk.length;
    }
    return _ImageData(
      bytes: bytes,
      mime:
          response.headers.contentType?.mimeType ??
          lookupMimeType(uri.path, headerBytes: bytes),
    );
  } on HostrCliException {
    rethrow;
  } on Object catch (error) {
    throw HostrCliException(
      'image_download_failed',
      'Image ${index + 1} URL could not be downloaded: $error',
      path: 'images[$index].url',
      exitCode: 64,
    );
  } finally {
    client.close(force: true);
  }
}

_ImageData _imageDataFromDataUrl(String dataUrl, int index) {
  final commaIndex = dataUrl.indexOf(',');
  if (!dataUrl.startsWith('data:') || commaIndex < 0) {
    throw HostrCliException(
      'invalid_image_data_url',
      'Image ${index + 1} dataUrl must use the data:<mime>;base64,<bytes> format.',
      path: 'images[$index].dataUrl',
      exitCode: 64,
    );
  }
  final header = dataUrl.substring(5, commaIndex);
  final payload = dataUrl.substring(commaIndex + 1);
  final headerParts = header.split(';');
  final mime = headerParts.first.isEmpty ? null : headerParts.first;
  final isBase64 = headerParts.any((part) => part.toLowerCase() == 'base64');
  if (!isBase64) {
    throw HostrCliException(
      'invalid_image_data_url',
      'Image ${index + 1} dataUrl must be base64 encoded.',
      path: 'images[$index].dataUrl',
      exitCode: 64,
    );
  }
  return _ImageData(bytes: _decodeImageBase64(payload, index), mime: mime);
}

_ImageData _imageDataFromBase64(
  String data,
  int index, {
  String? mime,
  String? filename,
}) {
  final bytes = _decodeImageBase64(data, index);
  return _ImageData(
    bytes: bytes,
    mime: mime ?? lookupMimeType(filename ?? '', headerBytes: bytes),
  );
}

Uint8List _decodeImageBase64(String data, int index) {
  try {
    return base64Decode(data.replaceAll(RegExp(r'\s+'), ''));
  } on FormatException catch (error) {
    throw HostrCliException(
      'invalid_image_base64',
      'Image ${index + 1} base64 data is invalid: ${error.message}',
      path: 'images[$index]',
      exitCode: 64,
    );
  }
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
