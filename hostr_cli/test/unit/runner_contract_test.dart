import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hostr_cli/hostr_cli.dart';
import 'package:hostr_cli/src/output/qr.dart';
import 'package:test/test.dart';

void main() {
  group('runner contracts', () {
    test('diagnostics config returns a JSON envelope', () async {
      final result = await _run(['--json', 'diagnostics', 'config']);
      expect(result.exitCode, 0);
      final json = jsonDecode(result.stdout) as Map<String, dynamic>;
      expect(json['ok'], isTrue);
      expect(json['command'], 'diagnostics config');
      expect(json['data']['hostrRelay'], isA<String>());
    });

    test('session reset clears state with confirmation', () async {
      final stateDir = await Directory.systemTemp.createTemp('hostr-cli-test-');
      final result = await _run([
        '--json',
        '--state-dir',
        stateDir.path,
        '--allow-insecure-file-secrets',
        'session',
        'reset',
        '--yes',
      ]);
      expect(result.exitCode, 0);
      final json = jsonDecode(result.stdout) as Map<String, dynamic>;
      expect(json['ok'], isTrue);
      expect(json['data']['reset'], isTrue);
    });

    test('session connect print-only returns QR image payload', () async {
      final stateDir = await Directory.systemTemp.createTemp('hostr-cli-test-');
      final result = await _run([
        '--env',
        'development',
        '--json',
        '--state-dir',
        stateDir.path,
        '--allow-insecure-file-secrets',
        'session',
        'connect',
        '--print-only',
      ]);
      expect(result.exitCode, 0);
      final json = jsonDecode(result.stdout) as Map<String, dynamic>;
      expect(json['ok'], isTrue);
      expect(json['data']['nostrconnect'], startsWith('nostrconnect://'));
      expect(json['data']['qr'], isA<String>());
      expectPngDataUri(json['data']['qrImage'] as String);
    });

    test('shared QR image contract is a PNG data URI string', () {
      final nostrConnectQr = renderQrImageDataUri('nostrconnect://example');
      final invoiceQr = renderQrImageDataUri(
        'lnbc1u1pjexamplepp5qqqsyqcyq5rqwzqfka',
      );

      expectPngDataUri(nostrConnectQr);
      expectPngDataUri(invoiceQr);
    });

    test(
      'reservation flow commands fail fast without an active session',
      () async {
        final stateDir = await Directory.systemTemp.createTemp(
          'hostr-cli-test-',
        );
        Future<_RunResult> runIsolated(List<String> args) {
          return _run([
            '--env',
            'development',
            '--json',
            '--state-dir',
            stateDir.path,
            '--allow-insecure-file-secrets',
            ...args,
          ]);
        }

        _expectAuthRequired(
          await runIsolated([
            'reservations',
            'pay',
            '--trade-context',
            'trade-123',
          ]),
          'reservations pay',
        );
        _expectAuthRequired(
          await runIsolated(['swaps', 'watch', '--swap-id', 'swap-123']),
          'swaps watch',
        );
        _expectAuthRequired(
          await runIsolated([
            'reservations',
            'cancel',
            '--input',
            jsonEncode({'tradeId': 'trade-123'}),
          ]),
          'reservations cancel',
        );
        _expectAuthRequired(
          await runIsolated([
            'escrow-methods',
            '--user',
            List.filled(64, '0').join(),
          ]),
          'escrow-methods',
        );
      },
    );

    test(
      'listing create dry-run works after local mnemonic session',
      () async {
        final stateDir = await Directory.systemTemp.createTemp(
          'hostr-cli-test-',
        );
        final session = await _run([
          '--env',
          'development',
          '--json',
          '--state-dir',
          stateDir.path,
          '--allow-insecure-file-secrets',
          'session',
          'ensure',
          '--mnemonic',
          'abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon abandon about',
        ]);
        expect(session.exitCode, 0);

        final create = await _run([
          '--env',
          'development',
          '--json',
          '--dry-run',
          '--state-dir',
          stateDir.path,
          '--allow-insecure-file-secrets',
          'listings',
          'create',
          '--input',
          jsonEncode({
            'title': 'CLI dry run',
            'description': 'Created in a unit test',
            'address': 'not used when h3Tags are supplied',
            'h3Tags': ['599685771850416127'],
            'type': 'room',
            'guests': 1,
            'beds': 1,
            'bathrooms': 1,
            'images': [
              {
                'dataUrl':
                    'data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=',
                'filename': 'listing.png',
              },
            ],
            'price': {
              'amount': {'value': '50000', 'currency': 'BTC', 'unit': 'sats'},
              'frequency': 'day',
            },
          }),
        ]);
        expect(create.exitCode, 0);
        final json = jsonDecode(create.stdout) as Map<String, dynamic>;
        expect(json['data']['dryRun'], isTrue);
        expect(json['data']['event']['kind'], 30402);

        final profile = await _run([
          '--env',
          'development',
          '--json',
          '--dry-run',
          '--state-dir',
          stateDir.path,
          '--allow-insecure-file-secrets',
          'profile',
          'edit',
          '--input',
          jsonEncode({'name': 'CLI Test Host'}),
        ]);
        expect(profile.exitCode, 0);
        final profileJson = jsonDecode(profile.stdout) as Map<String, dynamic>;
        expect(profileJson['data']['dryRun'], isTrue);
        expect(profileJson['data']['event']['kind'], 0);

        final swaps = await _run([
          '--env',
          'development',
          '--json',
          '--state-dir',
          stateDir.path,
          '--allow-insecure-file-secrets',
          'swaps',
          'list',
        ]);
        expect(swaps.exitCode, 0);
        final swapsJson = jsonDecode(swaps.stdout) as Map<String, dynamic>;
        expect(swapsJson['data']['entries'], isA<List>());
      },
      timeout: const Timeout(Duration(seconds: 45)),
    );
  });
}

void _expectAuthRequired(_RunResult result, String command) {
  expect(result.exitCode, 1);
  final json = jsonDecode(result.stdout) as Map<String, dynamic>;
  expect(json['ok'], isFalse);
  expect(json['command'], command);
  expect(json['errors'], isA<List>());
  expect(json['errors'][0]['code'], 'auth_required');
}

void expectPngDataUri(String value) {
  const prefix = 'data:image/png;base64,';
  expect(value, startsWith(prefix));
  final bytes = base64Decode(value.substring(prefix.length));
  expect(bytes.take(8).toList(), [137, 80, 78, 71, 13, 10, 26, 10]);
}

Future<_RunResult> _run(List<String> args) async {
  final stdout = _MemoryIOSink();
  final stderr = _MemoryIOSink();
  final exitCode = await runHostrCli(
    args,
    stdout: stdout.sink,
    stderr: stderr.sink,
  );
  await stdout.sink.flush();
  await stderr.sink.flush();
  return _RunResult(exitCode, stdout.content, stderr.content);
}

class _RunResult {
  const _RunResult(this.exitCode, this.stdout, this.stderr);

  final int exitCode;
  final String stdout;
  final String stderr;
}

class _MemoryIOSink {
  _MemoryIOSink() : consumer = _MemoryConsumer() {
    sink = IOSink(consumer);
  }

  final _MemoryConsumer consumer;
  late final IOSink sink;

  String get content => utf8.decode(consumer.bytes);
}

class _MemoryConsumer implements StreamConsumer<List<int>> {
  final bytes = <int>[];

  @override
  Future<void> addStream(Stream<List<int>> stream) async {
    await for (final chunk in stream) {
      bytes.addAll(chunk);
    }
  }

  @override
  Future<void> close() async {}
}
