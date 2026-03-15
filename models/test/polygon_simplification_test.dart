import 'package:h3_dart/h3_dart.dart';
import 'package:models/util/location/polygon_simplification.dart';
import 'package:test/test.dart';

void main() {
  group('PolygonSimplification', () {
    test('removes redundant vertices and tiny holes', () {
      const simplification = PolygonSimplification();

      final polygon = PolygonInputGeometry(
        outer: const [
          GeoCoord(lat: 0, lon: 0),
          GeoCoord(lat: 0, lon: 0.25),
          GeoCoord(lat: 0, lon: 0.5),
          GeoCoord(lat: 0, lon: 0.75),
          GeoCoord(lat: 0, lon: 1),
          GeoCoord(lat: 0.5, lon: 1),
          GeoCoord(lat: 1, lon: 1),
          GeoCoord(lat: 1, lon: 0.5),
          GeoCoord(lat: 1, lon: 0),
          GeoCoord(lat: 0.5, lon: 0),
          GeoCoord(lat: 0, lon: 0),
        ],
        holes: const [
          [
            GeoCoord(lat: 0.40, lon: 0.40),
            GeoCoord(lat: 0.40, lon: 0.401),
            GeoCoord(lat: 0.401, lon: 0.401),
            GeoCoord(lat: 0.401, lon: 0.40),
            GeoCoord(lat: 0.40, lon: 0.40),
          ],
        ],
      );

      final result = simplification.simplify(
        polygon: polygon,
        toleranceKm: 5,
        minHoleAreaKm2: 0.5,
      );

      expect(result.changed, isTrue);
      expect(result.geometry.outer.length, lessThan(polygon.outer.length));
      expect(result.geometry.outer.first.lat, polygon.outer.first.lat);
      expect(result.geometry.outer.first.lon, polygon.outer.first.lon);
      expect(result.geometry.outer.first.lat, result.geometry.outer.last.lat);
      expect(result.geometry.outer.first.lon, result.geometry.outer.last.lon);
      expect(result.geometry.holes, isEmpty);
      expect(result.droppedHoles, 1);
    });
  });
}
