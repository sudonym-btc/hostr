@Tags(['unit'])
library;

import 'dart:convert';

import 'package:hostr_sdk/usecase/location/location.dart';
import 'package:hostr_sdk/util/custom_logger.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('Location', () {
    test('retries polygon lookup after transient client failure', () async {
      var attempts = 0;
      final location = Location(
        logger: CustomLogger(),
        client: MockClient((request) async {
          attempts += 1;
          if (attempts == 1) {
            throw http.ClientException('Failed to fetch');
          }
          return http.Response(
            jsonEncode([
              {
                'place_id': 1,
                'display_name': 'San Salvador, El Salvador',
                'geojson': {
                  'type': 'Polygon',
                  'coordinates': [
                    [
                      [-89.2, 13.6],
                      [-89.1, 13.6],
                      [-89.1, 13.7],
                      [-89.2, 13.7],
                      [-89.2, 13.6],
                    ],
                  ],
                },
              },
            ]),
            200,
          );
        }),
      );

      final result = await location.polygon(
        'San Salvador, El Salvador',
        featureTypes: const {'country'},
      );

      expect(result.displayName, 'San Salvador, El Salvador');
      expect(attempts, 2);
    });

    test('retries geocode lookup after transient server failure', () async {
      var attempts = 0;
      final location = Location(
        logger: CustomLogger(),
        client: MockClient((request) async {
          attempts += 1;
          if (attempts == 1) {
            return http.Response('temporary failure', 503);
          }
          return http.Response(
            jsonEncode([
              {
                'display_name': 'San Salvador, El Salvador',
                'lat': '13.6976290',
                'lon': '-89.1911560',
                'boundingbox': ['13.6', '13.7', '-89.2', '-89.1'],
              },
            ]),
            200,
          );
        }),
      );

      final result = await location.point('San Salvador, El Salvador');

      expect(result.latitude, closeTo(13.6976290, 0.000001));
      expect(result.longitude, closeTo(-89.1911560, 0.000001));
      expect(attempts, 2);
    });
  });
}
