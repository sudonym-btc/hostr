import 'dart:convert';

import 'package:hostr_sdk/util/custom_logger.dart';
import 'package:http/http.dart' as http;
import 'package:injectable/injectable.dart';

@Singleton()
class Location {
  final CustomLogger logger;
  final http.Client _client = http.Client();
  final Map<String, LocationPolygonResult> _polygonCache = {};

  Location({required this.logger});

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
            latitude: _parseDouble(result['lat']),
            longitude: _parseDouble(result['lon']),
          ),
        )
        .toList();

    if (preferBroadResults) {
      // preserved for backward compatibility; no-op by design.
    }

    return mapped.length > limit ? mapped.take(limit).toList() : mapped;
  }

  Future<LocationPolygonResult> polygon(
    String location, {
    Set<String>? featureTypes,
  }) async {
    final query = location.trim();
    if (query.isEmpty) {
      throw ArgumentError('Location must not be empty');
    }

    final normalizedFeatureTypes =
        (featureTypes == null || featureTypes.isEmpty)
        ? const <String>[]
        : featureTypes
              .map((type) => type.toLowerCase().trim())
              .map(_toNominatimFeatureType)
              .whereType<String>()
              .toSet()
              .toList();

    final cacheKey =
        '${query.toLowerCase()}|${normalizedFeatureTypes.join(',')}';
    final cached = _polygonCache[cacheKey];
    if (cached != null) {
      return cached;
    }

    final rawResults = <Map<String, dynamic>>[];
    if (normalizedFeatureTypes.isEmpty) {
      rawResults.addAll(
        await _fetchSuggestionBatch(query, 1, includePolygon: true),
      );
    } else {
      for (final featureType in normalizedFeatureTypes) {
        rawResults.addAll(
          await _fetchSuggestionBatch(
            query,
            1,
            featureType: featureType,
            includePolygon: true,
          ),
        );
        if (rawResults.isNotEmpty) {
          break;
        }
      }
    }

    if (rawResults.isEmpty) {
      logger.w(
        'No polygon results for query="$query" with featureTypes=$normalizedFeatureTypes',
      );
      throw Exception('No polygon results for location');
    }

    final firstWithGeometry = rawResults.firstWhere(
      (result) => result['geojson'] is Map,
      orElse: () => rawResults.first,
    );

    final displayName = (firstWithGeometry['display_name'] ?? '').toString();
    logger.i(
      'Polygon result query="$query": '
      'type=${firstWithGeometry['geojson'] is Map ? (firstWithGeometry['geojson'] as Map)['type'] : 'bbox-fallback'}, '
      'display="$displayName"',
    );
    final geoJson = firstWithGeometry['geojson'] is Map<String, dynamic>
        ? (firstWithGeometry['geojson'] as Map<String, dynamic>)
        : _geoJsonFromBoundingBox(firstWithGeometry['boundingbox']);

    if (geoJson == null) {
      throw Exception('Location result has no polygon geometry');
    }

    final result = LocationPolygonResult(
      displayName: displayName,
      geoJson: geoJson,
      placeId: firstWithGeometry['place_id']?.toString(),
    );

    _polygonCache[cacheKey] = result;
    return result;
  }

  Future<GeoPoint> point(String location) async {
    final query = location.trim();
    if (query.isEmpty) {
      throw ArgumentError('Location must not be empty');
    }

    try {
      final geocode = await _geocode(query);
      return geocode.center;
    } catch (e) {
      logger.w('Primary geocode failed for "$query": $e');

      final fallbackResults = await _fetchSuggestionBatch(query, 1);
      if (fallbackResults.isNotEmpty) {
        final point = _pointFromRawResult(fallbackResults.first);
        if (point != null) {
          logger.i('Point resolved via suggestion fallback for "$query"');
          return point;
        }
      }

      rethrow;
    }
  }

  GeoPoint? _pointFromRawResult(Map<String, dynamic> result) {
    final lat = _parseDouble(result['lat']);
    final lon = _parseDouble(result['lon']);
    if (lat != null && lon != null) {
      return GeoPoint(latitude: lat, longitude: lon);
    }

    final bbox = result['boundingbox'];
    if (bbox is List && bbox.length == 4) {
      final south = _parseDouble(bbox[0]);
      final north = _parseDouble(bbox[1]);
      final west = _parseDouble(bbox[2]);
      final east = _parseDouble(bbox[3]);
      if (south != null && north != null && west != null && east != null) {
        return GeoPoint(
          latitude: (south + north) / 2,
          longitude: (west + east) / 2,
        );
      }
    }

    return null;
  }

  Future<List<Map<String, dynamic>>> _fetchSuggestionBatch(
    String query,
    int limit, {
    String? featureType,
    bool includePolygon = false,
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
    if (includePolygon) {
      params['polygon_geojson'] = '1';
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

  static double? _parseDouble(dynamic value) {
    if (value == null) return null;
    return double.tryParse(value.toString());
  }

  static Map<String, dynamic>? _geoJsonFromBoundingBox(dynamic rawBoundingBox) {
    if (rawBoundingBox is! List || rawBoundingBox.length != 4) {
      return null;
    }

    final south = double.tryParse(rawBoundingBox[0].toString());
    final north = double.tryParse(rawBoundingBox[1].toString());
    final west = double.tryParse(rawBoundingBox[2].toString());
    final east = double.tryParse(rawBoundingBox[3].toString());
    if (south == null || north == null || west == null || east == null) {
      return null;
    }

    return {
      'type': 'Polygon',
      'coordinates': [
        [
          [west, south],
          [east, south],
          [east, north],
          [west, north],
          [west, south],
        ],
      ],
    };
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

    final lat = _parseDouble(result['lat']);
    final lon = _parseDouble(result['lon']);
    final boundingBoxList = result['boundingbox'];

    BoundingBox? boundingBox;
    if (boundingBoxList is List && boundingBoxList.length == 4) {
      final south = _parseDouble(boundingBoxList[0]);
      final north = _parseDouble(boundingBoxList[1]);
      final west = _parseDouble(boundingBoxList[2]);
      final east = _parseDouble(boundingBoxList[3]);

      if (south != null && north != null && west != null && east != null) {
        boundingBox = BoundingBox(
          south: south,
          north: north,
          west: west,
          east: east,
        );
      }
    }

    if (boundingBox == null && lat != null && lon != null) {
      boundingBox = BoundingBox(south: lat, north: lat, west: lon, east: lon);
    }

    if (boundingBox == null) {
      throw Exception('Geocoder result missing usable coordinates');
    }

    final center = (lat != null && lon != null)
        ? GeoPoint(latitude: lat, longitude: lon)
        : GeoPoint(
            latitude: (boundingBox.south + boundingBox.north) / 2,
            longitude: (boundingBox.west + boundingBox.east) / 2,
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
  final double? latitude;
  final double? longitude;

  const LocationSuggestion({
    required this.displayName,
    this.placeId,
    this.osmClass,
    this.osmType,
    this.addressType,
    this.placeRank,
    this.latitude,
    this.longitude,
  });
}

class LocationPolygonResult {
  final String displayName;
  final Map<String, dynamic> geoJson;
  final String? placeId;

  const LocationPolygonResult({
    required this.displayName,
    required this.geoJson,
    this.placeId,
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
