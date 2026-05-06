@Tags(['integration', 'docker'])
library;

import 'dart:convert';
import 'dart:io';

import 'package:test/test.dart';

const _mnemonic =
    'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about';

void main() {
  final runIntegration = Platform.environment['HOSTR_CLI_RUN_DEV_IT'] == '1';

  group('development CLI', () {
    test(
      'publishes and lists a real development listing',
      () async {
        final stateDir = await Directory.systemTemp.createTemp(
          'hostr-cli-dev-',
        );

        final session = await _process([
          '--env',
          'development',
          '--json',
          '--state-dir',
          stateDir.path,
          '--allow-insecure-file-secrets',
          'session',
          'ensure',
          '--mnemonic',
          _mnemonic,
        ]);
        expect(session.exitCode, 0, reason: session.stderr);

        final create = await _process([
          '--env',
          'development',
          '--json',
          '--state-dir',
          stateDir.path,
          '--allow-insecure-file-secrets',
          'listings',
          'create',
          '--yes',
          '--input',
          jsonEncode({
            'title':
                'Hostr CLI integration ${DateTime.now().microsecondsSinceEpoch}',
            'description': 'Development relay integration test',
            'address': 'not used when h3Tags are supplied',
            'h3Tags': ['599685771850416127'],
            'type': 'room',
            'guests': 1,
            'beds': 1,
            'bathrooms': 1,
            'images': ['https://hostr.network/example.jpg'],
            'price': {
              'amount': {'value': '50000', 'currency': 'BTC', 'unit': 'sats'},
              'frequency': 'day',
            },
          }),
        ]);
        expect(create.exitCode, 0, reason: create.stderr);
        final created = _decodeProcessJson(create.stdout as String);
        expect(
          created['data']['relayResponses'].first['broadcastSuccessful'],
          isTrue,
        );
        expect(created['data']['event']['sig'], isNotEmpty);

        final list = await _process([
          '--env',
          'development',
          '--json',
          '--state-dir',
          stateDir.path,
          '--allow-insecure-file-secrets',
          'listings',
          'list',
          '--mine',
          '--limit',
          '10',
        ]);
        expect(list.exitCode, 0, reason: list.stderr);
        final listed = _decodeProcessJson(list.stdout as String);
        expect(listed['data']['count'], greaterThanOrEqualTo(1));
      },
      skip: runIntegration
          ? false
          : 'Set HOSTR_CLI_RUN_DEV_IT=1 to run against the local development stack.',
      timeout: const Timeout(Duration(minutes: 3)),
    );
  });
}

Map<String, dynamic> _decodeProcessJson(String stdout) {
  final start = stdout.indexOf('{');
  if (start < 0) {
    throw FormatException('No JSON object found in stdout', stdout);
  }
  return jsonDecode(stdout.substring(start)) as Map<String, dynamic>;
}

Future<ProcessResult> _process(List<String> args) {
  return Process.run('dart', [
    'run',
    'bin/hostr.dart',
    ...args,
  ], workingDirectory: Directory.current.path);
}
