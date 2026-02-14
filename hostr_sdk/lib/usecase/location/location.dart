import 'dart:convert';

import 'package:hostr_sdk/util/custom_logger.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

@Singleton()
class Location {
  final CustomLogger logger;
  final http.Client _client = http.Client();

  Location({required this.logger});

  /// Returns a geohash derived from the bounding box for [location].
  ///
  /// The geohash precision is chosen so that the geohash cell fully contains
  /// the bounding box. Larger bounding boxes yield shorter geohashes.
  Future<LocationGeohashResult> geohash(
    String location, {
    int minPrecision = 3,
    int maxPrecision = 8,
  }) async {
    final geocode = await _geocode(location);
    final precision = GeoHashPrecision.pickForBoundingBox(
      geocode.boundingBox,
      minPrecision: minPrecision,
      maxPrecision: maxPrecision,
    );
    final hash = GeoHash.encode(
      geocode.center.latitude,
      geocode.center.longitude,
      precision,
    );

    return LocationGeohashResult(
      geohash: hash,
      precision: precision,
      boundingBox: geocode.boundingBox,
      center: geocode.center,
      displayName: geocode.displayName,
    );
  }

  LocationFromGeohashResult getLocationFromGeohash(String geohash) {
    if (geohash.trim().isEmpty) {
      throw ArgumentError('Geohash must not be empty');
    }
    final decoded = GeoHash.decode(geohash.trim());
    return LocationFromGeohashResult(
      geohash: geohash.trim(),
      boundingBox: decoded.boundingBox,
      center: decoded.center,
      precision: geohash.trim().length,
    );
  }

  Future<List<LocationSuggestion>> suggestions(
    String input, {
    int limit = 5,
    bool preferBroadResults = true,
    Set<String>? featureTypes,
  }) async {
    final query = input.trim();
    if (query.isEmpty) return [];

    final normalizedFeatureTypes =
        (featureTypes == null || featureTypes.isEmpty)
        ? const <String>[]
        : featureTypes
              .map((type) => type.toLowerCase().trim())
              .map(_toNominatimFeatureType)
              .whereType<String>()
              .toSet()
              .toList();

    final rawResults = <Map<String, dynamic>>[];

    if (normalizedFeatureTypes.isEmpty) {
      rawResults.addAll(await _fetchSuggestionBatch(query, limit));
    } else {
      final batchLimit = limit;
      for (final featureType in normalizedFeatureTypes) {
        rawResults.addAll(
          await _fetchSuggestionBatch(
            query,
            batchLimit,
            featureType: featureType,
          ),
        );
      }
    }

    // Intentionally no post-filtering/ranking/deduplication here.
    // Results are constrained by request-side `featuretype` parameters.
    final mapped = rawResults
        .map(
          (result) => LocationSuggestion(
            displayName: (result['display_name'] ?? '').toString(),
            placeId: result['place_id']?.toString(),
            osmClass: result['class']?.toString(),
            osmType: result['type']?.toString(),
            addressType: result['addresstype']?.toString(),
            placeRank: _parseInt(result['place_rank']),
          ),
        )
        .toList();

    if (preferBroadResults) {
      // preserved for backward compatibility; no-op by design.
    }

    return mapped.length > limit ? mapped.take(limit).toList() : mapped;
  }

  Future<List<Map<String, dynamic>>> _fetchSuggestionBatch(
    String query,
    int limit, {
    String? featureType,
  }) async {
    final params = <String, String>{
      'q': query,
      'format': 'json',
      'limit': limit.toString(),
      'addressdetails': '1',
    };
    if (featureType != null) {
      params['featuretype'] = featureType;
    }

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', params);
    final response = await _client.get(
      uri,
      headers: const {'User-Agent': 'hostr-sdk/1.0 (+https://hostr.network)'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      logger.e(
        'Suggestion request failed: ${response.statusCode} ${response.body}',
      );
      throw Exception('Failed to fetch location suggestions');
    }

    final decoded = json.decode(response.body);
    if (decoded is! List) return const [];
    return decoded.whereType<Map<String, dynamic>>().toList();
  }

  static String? _toNominatimFeatureType(String type) {
    switch (type) {
      case 'country':
        return 'country';
      case 'state':
      case 'region':
      case 'province':
        return 'state';
      case 'city':
        return 'city';
      case 'town':
      case 'village':
      case 'settlement':
        return 'settlement';
      default:
        return null;
    }
  }

  static int? _parseInt(dynamic value) {
    if (value == null) return null;
    return int.tryParse(value.toString());
  }

  Future<GeocodedLocation> _geocode(String location) async {
    if (location.trim().isEmpty) {
      throw ArgumentError('Location must not be empty');
    }

    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': location,
      'format': 'json',
      'limit': '1',
      'addressdetails': '0',
    });

    final response = await _client.get(
      uri,
      headers: const {'User-Agent': 'hostr-sdk/1.0 (+https://hostr.network)'},
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      logger.e(
        'Geocode request failed: ${response.statusCode} ${response.body}',
      );
      throw Exception('Failed to geocode location');
    }

    final decoded = json.decode(response.body);
    if (decoded is! List || decoded.isEmpty) {
      throw Exception('No geocode results for location');
    }

    final result = decoded.first as Map<String, dynamic>;
    final boundingBoxList = result['boundingbox'] as List<dynamic>;
    if (boundingBoxList.length != 4) {
      throw Exception('Invalid bounding box returned from geocoder');
    }

    final south = double.parse(boundingBoxList[0].toString());
    final north = double.parse(boundingBoxList[1].toString());
    final west = double.parse(boundingBoxList[2].toString());
    final east = double.parse(boundingBoxList[3].toString());

    final boundingBox = BoundingBox(
      south: south,
      north: north,
      west: west,
      east: east,
    );

    final center = GeoPoint(
      latitude: (south + north) / 2,
      longitude: (west + east) / 2,
    );

    return GeocodedLocation(
      boundingBox: boundingBox,
      center: center,
      displayName: (result['display_name'] ?? '').toString(),
    );
  }
}

class GeocodedLocation {
  final BoundingBox boundingBox;
  final GeoPoint center;
  final String displayName;

  GeocodedLocation({
    required this.boundingBox,
    required this.center,
    required this.displayName,
  });
}

class LocationGeohashResult {
  final String geohash;
  final int precision;
  final BoundingBox boundingBox;
  final GeoPoint center;
  final String displayName;

  LocationGeohashResult({
    required this.geohash,
    required this.precision,
    required this.boundingBox,
    required this.center,
    required this.displayName,
  });
}

class LocationFromGeohashResult {
  final String geohash;
  final int precision;
  final BoundingBox boundingBox;
  final GeoPoint center;

  LocationFromGeohashResult({
    required this.geohash,
    required this.precision,
    required this.boundingBox,
    required this.center,
  });
}

class LocationSuggestion {
  final String displayName;
  final String? placeId;
  final String? osmClass;
  final String? osmType;
  final String? addressType;
  final int? placeRank;

  const LocationSuggestion({
    required this.displayName,
    this.placeId,
    this.osmClass,
    this.osmType,
    this.addressType,
    this.placeRank,
  });
}

class GeoPoint {
  final double latitude;
  final double longitude;

  GeoPoint({required this.latitude, required this.longitude});
}

class BoundingBox {
  final double south;
  final double north;
  final double west;
  final double east;

  BoundingBox({
    required this.south,
    required this.north,
    required this.west,
    required this.east,
  });

  double get latSpan => (north - south).abs();
  double get lonSpan => (east - west).abs();
}

class GeoHashPrecision {
  static const Map<int, GeoHashCellSize> _cellSizes = {
    1: GeoHashCellSize(latHeight: 45.0, lonWidth: 45.0),
    2: GeoHashCellSize(latHeight: 11.25, lonWidth: 5.625),
    3: GeoHashCellSize(latHeight: 1.40625, lonWidth: 1.40625),
    4: GeoHashCellSize(latHeight: 0.3515625, lonWidth: 0.17578125),
    5: GeoHashCellSize(latHeight: 0.0439453125, lonWidth: 0.0439453125),
    6: GeoHashCellSize(latHeight: 0.010986328125, lonWidth: 0.0054931640625),
    7: GeoHashCellSize(
      latHeight: 0.001373291015625,
      lonWidth: 0.001373291015625,
    ),
    8: GeoHashCellSize(
      latHeight: 0.00034332275390625,
      lonWidth: 0.000171661376953125,
    ),
    9: GeoHashCellSize(
      latHeight: 0.00004291534423828125,
      lonWidth: 0.00004291534423828125,
    ),
    10: GeoHashCellSize(
      latHeight: 0.000010728836059570312,
      lonWidth: 0.000005364418029785156,
    ),
  };

  static int pickForBoundingBox(
    BoundingBox boundingBox, {
    int minPrecision = 3,
    int maxPrecision = 8,
  }) {
    final latSpan = boundingBox.latSpan;
    final lonSpan = boundingBox.lonSpan;

    for (int precision = maxPrecision; precision >= minPrecision; precision--) {
      final cell = _cellSizes[precision];
      if (cell == null) continue;
      if (cell.latHeight >= latSpan && cell.lonWidth >= lonSpan) {
        return precision;
      }
    }

    return minPrecision;
  }
}

class GeoHashCellSize {
  final double latHeight;
  final double lonWidth;

  const GeoHashCellSize({required this.latHeight, required this.lonWidth});
}

class GeoHash {
  static const _base32 = '0123456789bcdefghjkmnpqrstuvwxyz';

  static String encode(double latitude, double longitude, int precision) {
    var latRange = [-90.0, 90.0];
    var lonRange = [-180.0, 180.0];
    var hash = StringBuffer();
    var isEven = true;
    var bit = 0;
    var ch = 0;

    while (hash.length < precision) {
      if (isEven) {
        final mid = (lonRange[0] + lonRange[1]) / 2;
        if (longitude >= mid) {
          ch |= 1 << (4 - bit);
          lonRange[0] = mid;
        } else {
          lonRange[1] = mid;
        }
      } else {
        final mid = (latRange[0] + latRange[1]) / 2;
        if (latitude >= mid) {
          ch |= 1 << (4 - bit);
          latRange[0] = mid;
        } else {
          latRange[1] = mid;
        }
      }

      isEven = !isEven;

      if (bit < 4) {
        bit++;
      } else {
        hash.write(_base32[ch]);
        bit = 0;
        ch = 0;
      }
    }

    return hash.toString();
  }

  static GeoHashDecoded decode(String geohash) {
    var latRange = [-90.0, 90.0];
    var lonRange = [-180.0, 180.0];
    var isEven = true;

    for (final char in geohash.toLowerCase().split('')) {
      final charIndex = _base32.indexOf(char);
      if (charIndex == -1) {
        throw ArgumentError('Invalid geohash character: $char');
      }

      for (var mask = 16; mask != 0; mask >>= 1) {
        if (isEven) {
          final mid = (lonRange[0] + lonRange[1]) / 2;
          if ((charIndex & mask) != 0) {
            lonRange[0] = mid;
          } else {
            lonRange[1] = mid;
          }
        } else {
          final mid = (latRange[0] + latRange[1]) / 2;
          if ((charIndex & mask) != 0) {
            latRange[0] = mid;
          } else {
            latRange[1] = mid;
          }
        }
        isEven = !isEven;
      }
    }

    final boundingBox = BoundingBox(
      south: latRange[0],
      north: latRange[1],
      west: lonRange[0],
      east: lonRange[1],
    );

    final center = GeoPoint(
      latitude: (latRange[0] + latRange[1]) / 2,
      longitude: (lonRange[0] + lonRange[1]) / 2,
    );

    return GeoHashDecoded(boundingBox: boundingBox, center: center);
  }
}

class GeoHashDecoded {
  final BoundingBox boundingBox;
  final GeoPoint center;

  GeoHashDecoded({required this.boundingBox, required this.center});
}
