import 'dart:math' as math;

import 'package:h3_dart/h3_dart.dart';

class PolygonInputGeometry {
  const PolygonInputGeometry({required this.outer, required this.holes});

  final List<GeoCoord> outer;
  final List<List<GeoCoord>> holes;
}

class PolygonSimplificationResult {
  const PolygonSimplificationResult({
    required this.geometry,
    required this.originalOuterVertices,
    required this.simplifiedOuterVertices,
    required this.originalHoleCount,
    required this.simplifiedHoleCount,
    required this.originalHoleVertices,
    required this.simplifiedHoleVertices,
    required this.droppedHoles,
    required this.toleranceKm,
    required this.minHoleAreaKm2,
  });

  final PolygonInputGeometry geometry;
  final int originalOuterVertices;
  final int simplifiedOuterVertices;
  final int originalHoleCount;
  final int simplifiedHoleCount;
  final int originalHoleVertices;
  final int simplifiedHoleVertices;
  final int droppedHoles;
  final double toleranceKm;
  final double minHoleAreaKm2;

  bool get changed =>
      originalOuterVertices != simplifiedOuterVertices ||
      originalHoleCount != simplifiedHoleCount ||
      originalHoleVertices != simplifiedHoleVertices;
}

class PolygonSimplification {
  const PolygonSimplification();

  PolygonSimplificationResult simplify({
    required PolygonInputGeometry polygon,
    required double toleranceKm,
    double minHoleAreaKm2 = 0.0,
  }) {
    final double safeToleranceKm = toleranceKm < 0 ? 0.0 : toleranceKm;
    final double collinearToleranceKm = _maxDouble(
      0.00025,
      safeToleranceKm * 0.1,
    );

    final cleanedOuter = _normalizeClosedRing(polygon.outer);
    final simplifiedOuter = _simplifyRing(
      cleanedOuter,
      toleranceKm: safeToleranceKm,
      collinearToleranceKm: collinearToleranceKm,
    );
    final validOuter =
        simplifiedOuter.length >= 4 ? simplifiedOuter : cleanedOuter;

    final holes = <List<GeoCoord>>[];
    int originalHoleVertices = 0;
    int simplifiedHoleVertices = 0;
    int droppedHoles = 0;

    for (final hole in polygon.holes) {
      originalHoleVertices += hole.length;

      final cleanedHole = _normalizeClosedRing(hole);
      if (cleanedHole.length < 4) {
        droppedHoles += 1;
        continue;
      }

      if (minHoleAreaKm2 > 0 && _ringAreaKm2(cleanedHole) < minHoleAreaKm2) {
        droppedHoles += 1;
        continue;
      }

      final simplifiedHole = _simplifyRing(
        cleanedHole,
        toleranceKm: safeToleranceKm,
        collinearToleranceKm: collinearToleranceKm,
      );
      final validHole =
          simplifiedHole.length >= 4 ? simplifiedHole : cleanedHole;

      if (minHoleAreaKm2 > 0 && _ringAreaKm2(validHole) < minHoleAreaKm2) {
        droppedHoles += 1;
        continue;
      }

      holes.add(validHole);
      simplifiedHoleVertices += validHole.length;
    }

    return PolygonSimplificationResult(
      geometry: PolygonInputGeometry(outer: validOuter, holes: holes),
      originalOuterVertices: polygon.outer.length,
      simplifiedOuterVertices: validOuter.length,
      originalHoleCount: polygon.holes.length,
      simplifiedHoleCount: holes.length,
      originalHoleVertices: originalHoleVertices,
      simplifiedHoleVertices: simplifiedHoleVertices,
      droppedHoles: droppedHoles,
      toleranceKm: safeToleranceKm,
      minHoleAreaKm2: minHoleAreaKm2,
    );
  }

  List<GeoCoord> _simplifyRing(
    List<GeoCoord> ring, {
    required double toleranceKm,
    required double collinearToleranceKm,
  }) {
    var simplified = _removeNearlyCollinearPoints(
      ring,
      toleranceKm: collinearToleranceKm,
    );

    if (toleranceKm > 0) {
      simplified = _simplifyClosedRingDouglasPeucker(
        simplified,
        toleranceKm: toleranceKm,
      );
      simplified = _removeNearlyCollinearPoints(
        simplified,
        toleranceKm: collinearToleranceKm,
      );
    }

    return _normalizeClosedRing(simplified);
  }

  List<GeoCoord> _normalizeClosedRing(List<GeoCoord> ring) {
    if (ring.isEmpty) return const <GeoCoord>[];

    final open = _stripClosure(ring);
    if (open.isEmpty) return const <GeoCoord>[];

    final deduped = <GeoCoord>[];
    for (final point in open) {
      if (deduped.isEmpty || !_samePoint(deduped.last, point)) {
        deduped.add(point);
      }
    }

    if (deduped.length < 3) {
      return List<GeoCoord>.from(deduped, growable: false);
    }

    return _closeRing(deduped);
  }

  List<GeoCoord> _removeNearlyCollinearPoints(
    List<GeoCoord> ring, {
    required double toleranceKm,
  }) {
    final open = _stripClosure(ring);
    if (open.length <= 3) {
      return _closeRing(open);
    }

    var points = List<GeoCoord>.from(open, growable: true);
    var changed = true;

    while (changed && points.length > 3) {
      changed = false;
      final reduced = <GeoCoord>[];

      for (var i = 0; i < points.length; i++) {
        final prev = points[(i - 1 + points.length) % points.length];
        final current = points[i];
        final next = points[(i + 1) % points.length];

        if (_distancePointToSegmentKm(current, prev, next) <= toleranceKm) {
          changed = true;
          continue;
        }

        reduced.add(current);
      }

      if (reduced.length < 3) {
        break;
      }

      points = reduced;
    }

    return _closeRing(points);
  }

  List<GeoCoord> _simplifyClosedRingDouglasPeucker(
    List<GeoCoord> ring, {
    required double toleranceKm,
  }) {
    final open = _stripClosure(ring);
    if (open.length <= 3) {
      return _closeRing(open);
    }

    final projected = _projectOpenRing(open);
    final keep = List<bool>.filled(projected.length, false);
    keep[0] = true;
    keep[projected.length - 1] = true;
    _markDouglasPeucker(projected, 0, projected.length - 1, toleranceKm, keep);

    final simplified = <GeoCoord>[];
    for (var i = 0; i < open.length; i++) {
      if (keep[i]) simplified.add(open[i]);
    }

    if (simplified.length < 3) {
      return _closeRing(open);
    }

    return _closeRing(simplified);
  }

  void _markDouglasPeucker(
    List<_ProjectedPoint> points,
    int start,
    int end,
    double toleranceKm,
    List<bool> keep,
  ) {
    if (end <= start + 1) return;

    var maxDistance = -1.0;
    var maxIndex = -1;

    for (var i = start + 1; i < end; i++) {
      final distance = _distanceToProjectedSegmentKm(
        points[i],
        points[start],
        points[end],
      );
      if (distance > maxDistance) {
        maxDistance = distance;
        maxIndex = i;
      }
    }

    if (maxIndex == -1 || maxDistance <= toleranceKm) {
      return;
    }

    keep[maxIndex] = true;
    _markDouglasPeucker(points, start, maxIndex, toleranceKm, keep);
    _markDouglasPeucker(points, maxIndex, end, toleranceKm, keep);
  }

  List<_ProjectedPoint> _projectOpenRing(List<GeoCoord> ring) {
    final double meanLat =
        ring.map((point) => point.lat).fold<double>(0, (sum, v) => sum + v) /
            ring.length;
    const double kmPerDegLat = 110.574;
    final double kmPerDegLon = 111.320 * math.cos(_degToRad(meanLat));

    return ring
        .map(
          (point) => _ProjectedPoint(
            x: point.lon * kmPerDegLon,
            y: point.lat * kmPerDegLat,
          ),
        )
        .toList(growable: false);
  }

  double _distancePointToSegmentKm(GeoCoord point, GeoCoord a, GeoCoord b) {
    final projected = _projectOpenRing([point, a, b]);
    return _distanceToProjectedSegmentKm(
      projected[0],
      projected[1],
      projected[2],
    );
  }

  double _distanceToProjectedSegmentKm(
    _ProjectedPoint point,
    _ProjectedPoint a,
    _ProjectedPoint b,
  ) {
    final double dx = b.x - a.x;
    final double dy = b.y - a.y;

    if (dx == 0 && dy == 0) {
      final double px = point.x - a.x;
      final double py = point.y - a.y;
      return math.sqrt((px * px) + (py * py));
    }

    final double t = (((point.x - a.x) * dx) + ((point.y - a.y) * dy)) /
        ((dx * dx) + (dy * dy));
    final double clampedT = t < 0 ? 0.0 : (t > 1 ? 1.0 : t);
    final double px = a.x + (dx * clampedT);
    final double py = a.y + (dy * clampedT);
    final double deltaX = point.x - px;
    final double deltaY = point.y - py;
    return math.sqrt((deltaX * deltaX) + (deltaY * deltaY));
  }

  double _ringAreaKm2(List<GeoCoord> ring) {
    final open = _stripClosure(ring);
    if (open.length < 3) return 0;

    final projected = _projectOpenRing(open);
    var area2 = 0.0;
    for (var i = 0; i < projected.length; i++) {
      final a = projected[i];
      final b = projected[(i + 1) % projected.length];
      area2 += (a.x * b.y) - (b.x * a.y);
    }

    return area2.abs() / 2;
  }

  List<GeoCoord> _stripClosure(List<GeoCoord> ring) {
    if (ring.isEmpty) return const <GeoCoord>[];

    final points = List<GeoCoord>.from(ring, growable: false);
    if (points.length >= 2 && _samePoint(points.first, points.last)) {
      return points.sublist(0, points.length - 1);
    }
    return points;
  }

  List<GeoCoord> _closeRing(List<GeoCoord> ring) {
    if (ring.length < 3) {
      return List<GeoCoord>.from(ring, growable: false);
    }

    final closed = List<GeoCoord>.from(ring, growable: true);
    if (!_samePoint(closed.first, closed.last)) {
      closed.add(closed.first);
    }
    return List<GeoCoord>.from(closed, growable: false);
  }

  bool _samePoint(GeoCoord a, GeoCoord b) {
    return (a.lat - b.lat).abs() < 1e-12 && (a.lon - b.lon).abs() < 1e-12;
  }

  double _maxDouble(double a, double b) => a > b ? a : b;

  double _degToRad(double degrees) => degrees * math.pi / 180.0;
}

class _ProjectedPoint {
  const _ProjectedPoint({
    required this.x,
    required this.y,
  });

  final double x;
  final double y;
}
