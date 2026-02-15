import 'package:h3_flutter/h3_flutter.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

class H3PolygonCover {
  static final H3 _h3 = const H3Factory().load();
  static final CustomLogger _logger = CustomLogger();

  static List<String> hierarchyForPoint({
    required double latitude,
    required double longitude,
    int finestResolution = 15,
    int? maxTags,
  }) {
    final boundedResolution = finestResolution.clamp(0, 15);
    final finest = _h3.geoToCell(
      GeoCoord(lat: latitude, lon: longitude),
      boundedResolution,
    );

    final tags = <String>[];
    final seen = <BigInt>{};
    for (var res = boundedResolution; res >= 0; res--) {
      final index = res == boundedResolution
          ? finest
          : _h3.cellToParent(finest, res);
      if (seen.add(index)) {
        tags.add(index.toString());
        if (maxTags != null && tags.length >= maxTags) {
          break;
        }
      }
    }

    return tags;
  }

  static ({double latitude, double longitude})? centerForTag(String h3Tag) {
    final index = BigInt.tryParse(h3Tag);
    if (index == null) return null;
    final geo = _h3.cellToGeo(index);
    return (latitude: geo.lat, longitude: geo.lon);
  }

  static List<String> fromGeoJson({
    required Map<String, dynamic> geoJson,
    int preferredResolution = 7,
    int minResolution = 2,
    int maxH3Tags = 30,
  }) {
    final type = (geoJson['type'] ?? '').toString();
    final coordinates = geoJson['coordinates'];
    if (coordinates is! List) {
      _logger.w('H3 cover skipped: geojson coordinates missing for type=$type');
      return const [];
    }

    _logger.i(
      'Building H3 cover from GeoJSON: type=$type, preferredRes=$preferredResolution, minRes=$minResolution, maxTags=$maxH3Tags',
    );

    final allCells = <BigInt>{};
    Object? lastError;
    for (
      var resolution = preferredResolution;
      resolution >= minResolution;
      resolution--
    ) {
      allCells
        ..clear()
        ..addAll(
          _coverGeometry(
            type: type,
            coordinates: coordinates,
            resolution: resolution,
            onError: (e) => lastError = e,
          ),
        );

      _logger.i('H3 cover resolution=$resolution -> cells=${allCells.length}');

      if (allCells.isNotEmpty && allCells.length <= maxH3Tags) {
        final ordered = allCells.toList()..sort((a, b) => a.compareTo(b));
        return ordered.map((e) => e.toString()).toList();
      }
    }

    if (allCells.isEmpty) {
      _logger.w('H3 cover failed: no cells produced for type=$type');
      if (lastError != null) {
        throw Exception('H3 polygon cover failed: $lastError');
      }
      return const [];
    }
    final ordered = allCells.toList()..sort((a, b) => a.compareTo(b));
    return ordered.take(maxH3Tags).map((e) => e.toString()).toList();
  }

  static Set<BigInt> _coverGeometry({
    required String type,
    required List<dynamic> coordinates,
    required int resolution,
    void Function(Object error)? onError,
  }) {
    switch (type) {
      case 'Polygon':
        return _coverPolygon(coordinates, resolution, onError: onError);
      case 'MultiPolygon':
        final cells = <BigInt>{};
        for (final polygon in coordinates) {
          if (polygon is List) {
            cells.addAll(_coverPolygon(polygon, resolution, onError: onError));
          }
        }
        return cells;
      case 'Point':
        return _coverPoint(coordinates, resolution);
      case 'MultiPoint':
        final cells = <BigInt>{};
        for (final point in coordinates) {
          if (point is List) {
            cells.addAll(_coverPoint(point, resolution));
          }
        }
        return cells;
      default:
        _logger.w('Unsupported GeoJSON type for H3 cover: $type');
        return const <BigInt>{};
    }
  }

  static Set<BigInt> _coverPoint(List<dynamic> point, int resolution) {
    if (point.length < 2) return const <BigInt>{};
    final lon = double.tryParse(point[0].toString());
    final lat = double.tryParse(point[1].toString());
    if (lon == null || lat == null) return const <BigInt>{};
    final h3Index = _h3.geoToCell(GeoCoord(lat: lat, lon: lon), resolution);
    return {h3Index};
  }

  static Set<BigInt> _coverPolygon(
    List<dynamic> polygonCoords,
    int resolution, {
    void Function(Object error)? onError,
  }) {
    if (polygonCoords.isEmpty || polygonCoords.first is! List) {
      return const <BigInt>{};
    }

    final perimeter = _toGeoCoords(polygonCoords.first as List<dynamic>);
    if (perimeter.length < 3) return const <BigInt>{};

    final holes = <List<GeoCoord>>[];
    for (final hole in polygonCoords.skip(1)) {
      if (hole is List) {
        final holeCoords = _toGeoCoords(hole);
        if (holeCoords.length >= 3) {
          holes.add(holeCoords);
        }
      }
    }

    try {
      final indexes = _h3.polygonToCells(
        perimeter: perimeter,
        resolution: resolution,
        holes: holes,
      );
      return indexes.toSet();
    } catch (e, st) {
      onError?.call(e);
      _logger.e(
        'polygonToCells failed at resolution=$resolution '
        '(perimeter=${perimeter.length}, holes=${holes.length})',
        error: e,
        stackTrace: st,
      );
      return const <BigInt>{};
    }
  }

  static List<GeoCoord> _toGeoCoords(List<dynamic> ring) {
    final coords = <GeoCoord>[];
    for (final point in ring) {
      if (point is! List || point.length < 2) continue;
      final lon = double.tryParse(point[0].toString());
      final lat = double.tryParse(point[1].toString());
      if (lat == null || lon == null) continue;
      coords.add(GeoCoord(lat: lat, lon: lon));
    }

    return coords;
  }
}
