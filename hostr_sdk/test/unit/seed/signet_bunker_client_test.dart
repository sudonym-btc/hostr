@Tags(['unit'])
library;

import 'dart:convert';

import 'package:hostr_sdk/seed/signet_bunker_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:test/test.dart';

void main() {
  group('SignetBunkerClient', () {
    test('revokeAppsForKey matches nested Signet app key shapes', () async {
      final requests = <http.Request>[];
      final client = MockClient((request) async {
        requests.add(request);
        return switch ((request.method, request.url.path)) {
          ('GET', '/apps') => http.Response(
            jsonEncode({
              'apps': [
                {'id': 1, 'keyName': 'other'},
                {
                  'id': '2',
                  'key': {'name': 'target-key'},
                },
                {
                  'id': 3,
                  'signer': {'keyName': 'target-key'},
                },
                {'id': 4, 'bunkerKeyName': 'target-key'},
              ],
            }),
            200,
          ),
          ('GET', '/csrf-token') => http.Response(
            jsonEncode({'csrfToken': 'csrf'}),
            200,
          ),
          ('POST', '/apps/2/revoke') ||
          ('POST', '/apps/3/revoke') ||
          ('POST', '/apps/4/revoke') => http.Response('{}', 200),
          _ => http.Response(
            'unexpected ${request.method} ${request.url}',
            500,
          ),
        };
      });
      final signet = SignetBunkerClient(
        baseUri: Uri.parse('https://signet.test/'),
        httpClient: client,
      );

      await signet.revokeAppsForKey('target-key');

      expect(
        requests.map((request) => '${request.method} ${request.url.path}'),
        [
          'GET /apps',
          'GET /csrf-token',
          'POST /apps/2/revoke',
          'POST /apps/3/revoke',
          'POST /apps/4/revoke',
        ],
      );
      for (final request in requests.where((r) => r.method == 'POST')) {
        expect(request.headers['x-csrf-token'], 'csrf');
      }
    });

    test(
      'updateAppTrustLevelForKey patches nested Signet app matches',
      () async {
        final requests = <http.Request>[];
        final client = MockClient((request) async {
          requests.add(request);
          return switch ((request.method, request.url.path)) {
            ('GET', '/apps') => http.Response(
              jsonEncode({
                'apps': [
                  {
                    'id': '42',
                    'key': {'keyName': 'target-key'},
                  },
                ],
              }),
              200,
            ),
            ('GET', '/csrf-token') => http.Response(
              jsonEncode({'csrfToken': 'csrf'}),
              200,
            ),
            ('PATCH', '/apps/42') => http.Response('{}', 200),
            _ => http.Response(
              'unexpected ${request.method} ${request.url}',
              500,
            ),
          };
        });
        final signet = SignetBunkerClient(
          baseUri: Uri.parse('https://signet.test/'),
          httpClient: client,
        );

        await signet.updateAppTrustLevelForKey('target-key', 'full');

        final patch = requests.singleWhere(
          (request) => request.method == 'PATCH',
        );
        expect(patch.url.path, '/apps/42');
        expect(jsonDecode(patch.body), {'trustLevel': 'full'});
      },
    );
  });
}
