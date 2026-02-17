import 'dart:isolate';
import 'dart:math' as math;

import 'package:h3_dart/h3_dart.dart';
import 'package:logger/logger.dart';

import 'h3_tag.dart';

class H3PolygonCover {
  final H3 _h3;
  H3PolygonCover(this._h3);

  final Logger _logger = Logger();
  int _minH3Resolution = 0;
  int _maxH3Resolution = 15;
  int _refinementProgressLogEvery = 100;
  int _maxRefinementIterations = 50000;
  double _initialProbeSlack = 6.0;

  ({double latitude, double longitude})? centerForTag(String h3Tag) {
    final index = BigInt.tryParse(h3Tag);
    if (index == null) return null;
    final geo = _h3.cellToGeo(index);
    return (latitude: geo.lat, longitude: geo.lon);
  }

  List<String> fromGeoJson({
    required Map<String, dynamic> geoJson,
    int maxH3Tags = 30,
  }) {
    return fromGeoJsonTags(
      geoJson: geoJson,
      maxH3Tags: maxH3Tags,
    ).map((tag) => tag.index).toList();
  }

  List<H3Tag> fromGeoJsonTags({
    required Map<String, dynamic> geoJson,
    int maxH3Tags = 30,
  }) {
    final totalSw = Stopwatch()..start();

    if (maxH3Tags <= 0) return const [];

    final type = (geoJson['type'] ?? '').toString();
    final coordinates = geoJson['coordinates'];
    if (coordinates is! List) {
      _logger.w('H3 cover skipped: geojson coordinates missing for type=$type');
      return const [];
    }

    if (type == 'Point') {
      final cell = _pointToCell(coordinates, _maxH3Resolution);
      if (cell == null) return const [];
      _logger.i('H3 cover(point): done in ${totalSw.elapsedMilliseconds}ms');
      return _toSortedTags({cell});
    }

    if (type == 'MultiPoint') {
      final cells = <BigInt>{};
      for (final point in coordinates) {
        if (point is! List) continue;
        final cell = _pointToCell(point, _maxH3Resolution);
        if (cell != null) cells.add(cell);
      }
      final tags = _toSortedTags(cells.take(maxH3Tags).toSet());
      _logger.i(
        'H3 cover(multipoint): points=${coordinates.length}, tags=${tags.length}, '
        'done in ${totalSw.elapsedMilliseconds}ms',
      );
      return tags;
    }

    final polygons = _extractPolygons(type: type, coordinates: coordinates);
    if (polygons.isEmpty) {
      _logger.w('Unsupported GeoJSON type for H3 cover: $type');
      return const [];
    }

    _logger.i(
      'H3 cover start: type=$type, polygons=${polygons.length}, maxTags=$maxH3Tags',
    );

    if (polygons.length == 1) {
      final tags = _toSortedTags(
        _coverPolygon(polygons.first, maxH3Tags, label: 'polygon[0]'),
      );
      _logger.i(
        'H3 cover end(single): tags=${tags.length}, '
        'elapsed=${totalSw.elapsedMilliseconds}ms',
      );
      return tags;
    }

    final areas = polygons
        .map((polygon) => _polygonAreaKm2(polygon.outer))
        .toList(growable: false);
    final totalArea = areas.fold<double>(0, (sum, value) => sum + value);
    final budgetByPolygon = List<int>.filled(polygons.length, 1);

    var remaining = math.max(0, maxH3Tags - polygons.length);
    if (remaining > 0) {
      if (totalArea > 0) {
        for (var i = 0; i < polygons.length; i++) {
          final share = ((areas[i] / totalArea) * remaining).floor();
          budgetByPolygon[i] += share;
        }
      }

      var assigned = budgetByPolygon.fold<int>(0, (sum, value) => sum + value);
      while (assigned < maxH3Tags) {
        var bestIndex = 0;
        for (var i = 1; i < polygons.length; i++) {
          if (areas[i] > areas[bestIndex]) bestIndex = i;
        }
        budgetByPolygon[bestIndex] += 1;
        assigned += 1;
      }
    }

    final merged = <BigInt>{};
    for (var i = 0; i < polygons.length; i++) {
      _logger.i(
        'H3 multipolygon budget: polygon[$i] areaKm2=${areas[i].toStringAsFixed(2)} '
        'budget=${budgetByPolygon[i]}',
      );
      merged.addAll(
        _coverPolygon(polygons[i], budgetByPolygon[i], label: 'polygon[$i]'),
      );
    }

    var cells = merged;
    while (cells.length > maxH3Tags) {
      final next = <BigInt>{};
      for (final cell in cells) {
        final resolution = _h3.getResolution(cell);
        if (resolution <= _minH3Resolution) {
          next.add(cell);
        } else {
          next.add(_h3.cellToParent(cell, resolution - 1));
        }
      }

      if (next.length == cells.length && next.containsAll(cells)) {
        break;
      }
      cells = next;
    }

    if (cells.length > maxH3Tags) {
      final ordered = cells.toList()
        ..sort((a, b) {
          final ra = _h3.getResolution(a);
          final rb = _h3.getResolution(b);
          if (ra != rb) return ra.compareTo(rb);
          return a.compareTo(b);
        });
      cells = ordered.take(maxH3Tags).toSet();
    }

    final tags = _toSortedTags(cells);
    _logger.i(
      'H3 cover end(multipolygon): mergedCells=${merged.length}, tags=${tags.length}, '
      'elapsed=${totalSw.elapsedMilliseconds}ms',
    );
    return tags;
  }

  Future<List<H3Tag>> fromGeoJsonTagsInBackground({
    required Map<String, dynamic> geoJson,
    int maxH3Tags = 30,
    bool kIsWeb = false,
  }) async {
    if (kIsWeb) {
      // Web doesn't benefit from Isolate.run in the same way.
      return fromGeoJsonTags(geoJson: geoJson, maxH3Tags: maxH3Tags);
    }

    final payload = <String, dynamic>{
      'geoJson': _toSerializableJson(geoJson),
      'maxH3Tags': maxH3Tags,
    };

    try {
      final raw = await Isolate.run(
        () => _fromGeoJsonTagsSerializablePayload(payload),
      );

      return raw
          .map(
            (e) => H3Tag(
              index: e['index']!.toString(),
              resolution: e['resolution']! as int,
            ),
          )
          .toList(growable: false);
    } catch (e, st) {
      _logger.w('H3 background cover failed; falling back to main isolate');
      _logger.e('H3 background cover error', error: e, stackTrace: st);
      return fromGeoJsonTags(geoJson: geoJson, maxH3Tags: maxH3Tags);
    }
  }

  List<Map<String, Object>> _fromGeoJsonTagsSerializablePayload(
    Map<String, dynamic> payload,
  ) {
    final geoJson = (payload['geoJson'] as Map).cast<String, dynamic>();
    final maxH3Tags = payload['maxH3Tags'] as int;
    final tags = fromGeoJsonTags(geoJson: geoJson, maxH3Tags: maxH3Tags);

    return tags
        .map<Map<String, Object>>(
          (tag) => <String, Object>{
            'index': tag.index,
            'resolution': tag.resolution,
          },
        )
        .toList(growable: false);
  }

  dynamic _toSerializableJson(dynamic value) {
    if (value is Map) {
      return value.map<String, dynamic>(
        (key, val) => MapEntry(key.toString(), _toSerializableJson(val)),
      );
    }
    if (value is List) {
      return value.map<dynamic>(_toSerializableJson).toList(growable: false);
    }
    return value;
  }

  List<H3Tag> _toSortedTags(Set<BigInt> cells) {
    final ordered = cells.toList()
      ..sort((a, b) {
        final resCompare = _h3.getResolution(a).compareTo(_h3.getResolution(b));
        if (resCompare != 0) return resCompare;
        return a.compareTo(b);
      });

    return ordered
        .map(
          (e) => H3Tag(index: e.toString(), resolution: _h3.getResolution(e)),
        )
        .toList();
  }

  List<_PolygonInput> _extractPolygons({
    required String type,
    required List<dynamic> coordinates,
  }) {
    switch (type) {
      case 'Polygon':
        final polygon = _toPolygonInput(coordinates);
        return polygon == null ? const [] : [polygon];
      case 'MultiPolygon':
        final polygons = <_PolygonInput>[];
        for (final polygonCoords in coordinates) {
          if (polygonCoords is! List) continue;
          final polygon = _toPolygonInput(polygonCoords);
          if (polygon != null) polygons.add(polygon);
        }
        return polygons;
      default:
        return const [];
    }
  }

  _PolygonInput? _toPolygonInput(List<dynamic> polygonCoords) {
    if (polygonCoords.isEmpty || polygonCoords.first is! List) {
      return null;
    }

    final outer = _toGeoCoordsClosed(polygonCoords.first as List<dynamic>);
    if (outer.length < 3) return null;

    final holes = <List<GeoCoord>>[];
    if (polygonCoords.length > 1) {
      for (final holeRing in polygonCoords.skip(1)) {
        if (holeRing is! List) continue;
        final hole = _toGeoCoordsClosed(holeRing);
        if (hole.length >= 3) holes.add(hole);
      }
    }

    return _PolygonInput(outer: outer, holes: holes);
  }

  BigInt? _pointToCell(List<dynamic> point, int resolution) {
    if (point.length < 2) return null;
    final lon = double.tryParse(point[0].toString());
    final lat = double.tryParse(point[1].toString());
    if (lon == null || lat == null) return null;
    return _h3.geoToCell(GeoCoord(lat: lat, lon: lon), resolution);
  }

  Set<BigInt> _coverPolygon(
    _PolygonInput polygon,
    int maxH3Cells, {
    String? label,
  }) {
    if (maxH3Cells <= 0) return const <BigInt>{};

    final name = label ?? 'polygon';
    final sw = Stopwatch()..start();
    final stats = _CoverStats();

    _logger.i(
      'H3 $name: start cover (outerVertices=${polygon.outer.length}, '
      'holes=${polygon.holes.length}, maxCells=$maxH3Cells)',
    );

    Set<BigInt> cells = const <BigInt>{};
    var selectedResolution = _minH3Resolution;
    final initialProbeResolution = _selectInitialProbeResolution(
      polygon: polygon,
      maxH3Cells: maxH3Cells,
    );
    _logger.i(
      'H3 $name: initial probe resolution=$initialProbeResolution '
      '(instead of $_maxH3Resolution for safety)',
    );

    for (var resolution = initialProbeResolution;
        resolution >= _minH3Resolution;
        resolution--) {
      cells = _polygonToCellsAtResolution(polygon, resolution);
      selectedResolution = resolution;
      _logger.i('H3 $name: probe res=$resolution -> cells=${cells.length}');
      if (cells.length <= maxH3Cells) {
        break;
      }
    }

    if (selectedResolution == _minH3Resolution && cells.length > maxH3Cells) {
      _logger.w(
        'H3 $name: fallback truncate at res=0 cells=${cells.length} max=$maxH3Cells',
      );
      return cells.take(maxH3Cells).toSet();
    }

    final queue = _MaxScoredCellHeap();
    for (final cell in cells) {
      if (_cellTouchesBoundary(cell, polygon, stats: stats)) {
        queue.push(
          _ScoredCell(
            cell: cell,
            score: _wasteScore(cell, polygon, stats: stats),
          ),
        );
        stats.queuePushes += 1;
      }
    }

    _logger.i(
      'H3 $name: initial selectedRes=$selectedResolution, seedCells=${cells.length}, '
      'boundaryCandidates=${queue.length}',
    );

    var iterations = 0;

    while (queue.isNotEmpty) {
      iterations += 1;
      if (iterations > _maxRefinementIterations) {
        _logger.w(
          'H3 $name: refinement stop after $iterations iterations '
          '(guard hit), cells=${cells.length}, queue=${queue.length}',
        );
        break;
      }

      if (cells.length >= maxH3Cells) {
        break;
      }

      final scored = queue.pop();
      stats.queuePops += 1;
      if (scored == null) {
        break;
      }

      final cell = scored.cell;
      if (!cells.contains(cell)) {
        stats.skippedMissingCells += 1;
        continue;
      }

      final resolution = _h3.getResolution(cell);
      if (resolution >= _maxH3Resolution) {
        continue;
      }

      final children = _h3.cellToChildren(cell, resolution + 1).toSet();
      if (children.isEmpty) {
        continue;
      }

      if (cells.length - 1 + children.length > maxH3Cells) {
        stats.skippedOverBudget += 1;
        continue;
      }

      cells.remove(cell);
      cells.addAll(children);
      stats.refinements += 1;

      for (final child in children) {
        if (_cellTouchesBoundary(child, polygon, stats: stats)) {
          queue.push(
            _ScoredCell(
              cell: child,
              score: _wasteScore(child, polygon, stats: stats),
            ),
          );
          stats.queuePushes += 1;
        }
      }

      if (iterations % _refinementProgressLogEvery == 0) {
        _logger.i(
          'H3 $name: refine progress iter=$iterations cells=${cells.length}/$maxH3Cells '
          'queue=${queue.length} refinements=${stats.refinements} '
          'boundaryChecks=${stats.boundaryChecks} segmentTests=${stats.segmentTests}',
        );
      }
    }

    _logger.i(
      'H3 $name: done cells=${cells.length}, selectedRes=$selectedResolution, '
      'iter=$iterations, elapsed=${sw.elapsedMilliseconds}ms, '
      'stats={refinements:${stats.refinements}, queuePushes:${stats.queuePushes}, '
      'queuePops:${stats.queuePops}, skippedOverBudget:${stats.skippedOverBudget}, '
      'skippedMissing:${stats.skippedMissingCells}, boundaryChecks:${stats.boundaryChecks}, '
      'wasteScores:${stats.wasteScores}, intersectionApproximations:${stats.intersectionApproximations}, '
      'ringIntersectionChecks:${stats.ringIntersectionChecks}, segmentTests:${stats.segmentTests}}',
    );

    return cells;
  }

  int _selectInitialProbeResolution({
    required _PolygonInput polygon,
    required int maxH3Cells,
  }) {
    if (maxH3Cells <= 2) {
      return 2;
    }

    final areaKm2 = _polygonAreaKm2(polygon.outer).abs();
    if (areaKm2 <= 0) {
      return math.min(9, _maxH3Resolution);
    }

    final targetUpperBound = math.max(1.0, maxH3Cells * _initialProbeSlack);

    for (var resolution = _maxH3Resolution;
        resolution >= _minH3Resolution;
        resolution--) {
      final avgHexAreaKm2 = _h3.getHexagonAreaAvg(resolution, H3MetricUnits.km);
      if (avgHexAreaKm2 <= 0) continue;

      final estimatedCells = areaKm2 / avgHexAreaKm2;
      if (estimatedCells <= targetUpperBound) {
        return resolution;
      }
    }

    return _minH3Resolution;
  }

  Set<BigInt> _polygonToCellsAtResolution(
    _PolygonInput polygon,
    int resolution,
  ) {
    try {
      return _h3
          .polygonToCellsExperimental(
            perimeter: polygon.outer,
            holes: polygon.holes,
            resolution: resolution,
            flag: PolygonToCellFlags.containmentCenter,
          )
          .toSet();
    } catch (e, st) {
      _logger.w(
        'polygonToCellsExperimental failed at resolution=$resolution; '
        'falling back to polygonToCells',
      );
      _logger.e('polygonToCellsExperimental error', error: e, stackTrace: st);

      try {
        return _h3
            .polygonToCells(
              perimeter: polygon.outer,
              holes: polygon.holes,
              resolution: resolution,
            )
            .toSet();
      } catch (fallbackError, fallbackSt) {
        _logger.e(
          'polygonToCells failed at resolution=$resolution '
          '(perimeter=${polygon.outer.length}, holes=${polygon.holes.length})',
          error: fallbackError,
          stackTrace: fallbackSt,
        );
        return const <BigInt>{};
      }
    }
  }

  double _wasteScore(
    BigInt cell,
    _PolygonInput polygon, {
    _CoverStats? stats,
  }) {
    stats?.wasteScores += 1;
    final cellArea = _h3.cellArea(cell, H3Units.m);
    final intersectionArea = _approxIntersectionArea(
      cell,
      polygon,
      cellArea,
      stats: stats,
    );
    return math.max(0.0, cellArea - intersectionArea);
  }

  double _approxIntersectionArea(
    BigInt cell,
    _PolygonInput polygon,
    double cellArea, {
    _CoverStats? stats,
  }) {
    stats?.intersectionApproximations += 1;

    if (!_cellTouchesBoundary(cell, polygon, stats: stats)) {
      return cellArea;
    }

    final boundary = _h3.cellToBoundary(cell);
    if (boundary.isEmpty) return 0;

    var inside = 0;
    for (final point in boundary) {
      if (_pointInPolygon(point, polygon)) {
        inside += 1;
      }
    }

    final center = _h3.cellToGeo(cell);
    final centerInside = _pointInPolygon(center, polygon) ? 1 : 0;
    final ratio = (inside + centerInside) / (boundary.length + 1);

    return cellArea * ratio.clamp(0.0, 1.0);
  }

  bool _cellTouchesBoundary(
    BigInt cell,
    _PolygonInput polygon, {
    _CoverStats? stats,
  }) {
    stats?.boundaryChecks += 1;
    final boundary = _toClosedGeoRing(_h3.cellToBoundary(cell));
    if (boundary.length < 4) return false;

    if (_ringIntersectsPolygon(boundary, polygon, stats: stats)) {
      return true;
    }

    var anyInside = false;
    var anyOutside = false;
    for (final vertex in boundary.take(boundary.length - 1)) {
      if (_pointInPolygon(vertex, polygon)) {
        anyInside = true;
      } else {
        anyOutside = true;
      }

      if (anyInside && anyOutside) {
        return true;
      }
    }

    for (final vertex in polygon.outer.take(polygon.outer.length - 1)) {
      if (_pointInRing(vertex, boundary)) {
        return true;
      }
    }

    for (final hole in polygon.holes) {
      for (final vertex in hole.take(hole.length - 1)) {
        if (_pointInRing(vertex, boundary)) {
          return true;
        }
      }
    }

    return false;
  }

  bool _ringIntersectsPolygon(
    List<GeoCoord> ring,
    _PolygonInput polygon, {
    _CoverStats? stats,
  }) {
    if (_ringsIntersect(ring, polygon.outer, stats: stats)) return true;
    for (final hole in polygon.holes) {
      if (_ringsIntersect(ring, hole, stats: stats)) return true;
    }
    return false;
  }

  bool _ringsIntersect(
    List<GeoCoord> a,
    List<GeoCoord> b, {
    _CoverStats? stats,
  }) {
    stats?.ringIntersectionChecks += 1;
    if (a.length < 4 || b.length < 4) return false;

    for (var i = 0; i < a.length - 1; i++) {
      final a1 = a[i];
      final a2 = a[i + 1];
      for (var j = 0; j < b.length - 1; j++) {
        final b1 = b[j];
        final b2 = b[j + 1];
        if (_segmentsIntersect(a1, a2, b1, b2, stats: stats)) {
          return true;
        }
      }
    }

    return false;
  }

  bool _segmentsIntersect(
    GeoCoord p1,
    GeoCoord p2,
    GeoCoord q1,
    GeoCoord q2, {
    _CoverStats? stats,
  }) {
    stats?.segmentTests += 1;
    final o1 = _orientation(p1, p2, q1);
    final o2 = _orientation(p1, p2, q2);
    final o3 = _orientation(q1, q2, p1);
    final o4 = _orientation(q1, q2, p2);

    if (o1 != o2 && o3 != o4) return true;

    if (o1 == 0 && _onSegment(p1, q1, p2)) return true;
    if (o2 == 0 && _onSegment(p1, q2, p2)) return true;
    if (o3 == 0 && _onSegment(q1, p1, q2)) return true;
    if (o4 == 0 && _onSegment(q1, p2, q2)) return true;

    return false;
  }

  int _orientation(GeoCoord a, GeoCoord b, GeoCoord c) {
    final value = ((b.lon - a.lon) * (c.lat - b.lat)) -
        ((b.lat - a.lat) * (c.lon - b.lon));
    if (value.abs() < 1e-12) return 0;
    return value > 0 ? 1 : 2;
  }

  bool _onSegment(GeoCoord a, GeoCoord b, GeoCoord c) {
    return b.lon <= math.max(a.lon, c.lon) + 1e-12 &&
        b.lon + 1e-12 >= math.min(a.lon, c.lon) &&
        b.lat <= math.max(a.lat, c.lat) + 1e-12 &&
        b.lat + 1e-12 >= math.min(a.lat, c.lat);
  }

  bool _pointInPolygon(GeoCoord point, _PolygonInput polygon) {
    if (!_pointInRing(point, polygon.outer)) {
      return false;
    }

    for (final hole in polygon.holes) {
      if (_pointInRing(point, hole)) {
        return false;
      }
    }

    return true;
  }

  bool _pointInRing(GeoCoord point, List<GeoCoord> ring) {
    if (ring.length < 4) return false;

    var inside = false;
    for (var i = 0, j = ring.length - 1; i < ring.length; j = i++) {
      final xi = ring[i].lon;
      final yi = ring[i].lat;
      final xj = ring[j].lon;
      final yj = ring[j].lat;

      final intersects = ((yi > point.lat) != (yj > point.lat)) &&
          (point.lon <
              ((xj - xi) * (point.lat - yi)) / ((yj - yi) + 1e-20) + xi);

      if (intersects) {
        inside = !inside;
      }
    }

    return inside;
  }

  double _polygonAreaKm2(List<GeoCoord> ring) {
    if (ring.length < 3) return 0;

    final meanLat =
        ring.map((p) => p.lat).fold<double>(0, (sum, v) => sum + v) /
            ring.length;
    final kmPerDegLat = 110.574;
    final kmPerDegLon = 111.320 * math.cos(_h3.degsToRads(meanLat));

    var area2 = 0.0;
    for (var i = 0; i < ring.length; i++) {
      final a = ring[i];
      final b = ring[(i + 1) % ring.length];
      final ax = a.lon * kmPerDegLon;
      final ay = a.lat * kmPerDegLat;
      final bx = b.lon * kmPerDegLon;
      final by = b.lat * kmPerDegLat;
      area2 += (ax * by) - (bx * ay);
    }

    return area2.abs() / 2;
  }

  List<GeoCoord> _toClosedGeoRing(List<GeoCoord> ring) {
    if (ring.isEmpty) return const <GeoCoord>[];
    final closed = List<GeoCoord>.from(ring);
    final first = closed.first;
    final last = closed.last;
    if (first.lat != last.lat || first.lon != last.lon) {
      closed.add(GeoCoord(lat: first.lat, lon: first.lon));
    }
    return closed;
  }

  List<GeoCoord> _toGeoCoordsClosed(List<dynamic> ring) {
    final coords = <GeoCoord>[];
    for (final point in ring) {
      if (point is! List || point.length < 2) continue;
      final lon = double.tryParse(point[0].toString());
      final lat = double.tryParse(point[1].toString());
      if (lat == null || lon == null) continue;
      coords.add(GeoCoord(lat: lat, lon: lon));
    }

    if (coords.length < 3) {
      return coords;
    }

    final first = coords.first;
    final last = coords.last;
    if (first.lat != last.lat || first.lon != last.lon) {
      coords.add(GeoCoord(lat: first.lat, lon: first.lon));
    }

    return coords;
  }
}

class _PolygonInput {
  const _PolygonInput({required this.outer, required this.holes});

  final List<GeoCoord> outer;
  final List<List<GeoCoord>> holes;
}

class _ScoredCell {
  const _ScoredCell({required this.cell, required this.score});

  final BigInt cell;
  final double score;
}

class _CoverStats {
  int boundaryChecks = 0;
  int wasteScores = 0;
  int intersectionApproximations = 0;
  int ringIntersectionChecks = 0;
  int segmentTests = 0;
  int queuePushes = 0;
  int queuePops = 0;
  int refinements = 0;
  int skippedOverBudget = 0;
  int skippedMissingCells = 0;
}

class _MaxScoredCellHeap {
  final List<_ScoredCell> _items = <_ScoredCell>[];

  bool get isNotEmpty => _items.isNotEmpty;
  int get length => _items.length;

  void push(_ScoredCell item) {
    _items.add(item);
    _siftUp(_items.length - 1);
  }

  _ScoredCell? pop() {
    if (_items.isEmpty) return null;
    final top = _items.first;
    final tail = _items.removeLast();
    if (_items.isNotEmpty) {
      _items[0] = tail;
      _siftDown(0);
    }
    return top;
  }

  void _siftUp(int index) {
    var child = index;
    while (child > 0) {
      final parent = (child - 1) ~/ 2;
      if (_items[parent].score >= _items[child].score) {
        break;
      }
      final temp = _items[parent];
      _items[parent] = _items[child];
      _items[child] = temp;
      child = parent;
    }
  }

  void _siftDown(int index) {
    var parent = index;
    while (true) {
      final left = (2 * parent) + 1;
      final right = left + 1;
      var largest = parent;

      if (left < _items.length && _items[left].score > _items[largest].score) {
        largest = left;
      }

      if (right < _items.length &&
          _items[right].score > _items[largest].score) {
        largest = right;
      }

      if (largest == parent) {
        break;
      }

      final temp = _items[parent];
      _items[parent] = _items[largest];
      _items[largest] = temp;
      parent = largest;
    }
  }
}
