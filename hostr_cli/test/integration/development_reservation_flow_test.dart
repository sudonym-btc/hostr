@Tags(['integration', 'docker'])
library;

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:hostr_sdk/datasources/alby/alby.dart';
import 'package:test/test.dart';

const _hostNsec =
    '556f19cc663fa7ff6840e6b6dc4ab244e8e952161f116b06d04c76cba659b980';
const _guestNsec =
    '1714ff69753ae70a91d6e1989cb1ee859b10e98239c61d28bcb0577d8d626b74';

void main() {
  final runIntegration = Platform.environment['HOSTR_CLI_RUN_DEV_IT'] == '1';

  group(
    'development reservation CLI flow',
    () {
      late _CliSession host;
      late _CliSession guest;
      late String listingAnchor;
      late String hostPubkey;

      setUpAll(() async {
        _acceptSelfSignedDevelopmentCerts();
        host = await _CliSession.create('host');
        guest = await _CliSession.create('guest');

        hostPubkey = await host.ensure(nsec: _hostNsec, ensureSeed: true);
        await guest.ensure(nsec: _guestNsec, ensureSeed: true);
        await host.profile('CLI Dart Test Host');
        await guest.profile('CLI Dart Test Guest');
        await host.ensure(ensureSellerConfig: true);

        listingAnchor = await host.createListing(
          title:
              'CLI reservation flow ${DateTime.now().microsecondsSinceEpoch}',
        );
      });

      tearDownAll(() async {
        await host.dispose();
        await guest.dispose();
      });

      test(
        'private negotiation cancel, follow-up offer, accept, and pay availability',
        () async {
          final cancelTrade = await guest.offer(
            listingAnchor: listingAnchor,
            start: DateTime.utc(2027, 1, 5),
            end: DateTime.utc(2027, 1, 7),
            amount: _usd('1.00'),
          );
          final cancel = await guest.runOk([
            'reservations',
            'cancel',
            '--input',
            jsonEncode({'tradeId': cancelTrade}),
            '--yes',
          ]);
          expect(cancel['mode'], 'negotiation');
          expect(cancel['delivery'], isNull);
          expect(_eventStage(cancel['event']), 'cancel');

          final followUpTrade = await guest.offer(
            listingAnchor: listingAnchor,
            start: DateTime.utc(2027, 2, 5),
            end: DateTime.utc(2027, 2, 7),
            amount: _usd('1.00'),
          );
          final followUp = await host.runOk([
            'reservations',
            'negotiation',
            'offer',
            '--input',
            jsonEncode({'tradeId': followUpTrade, 'amount': _usd('1.50')}),
            '--yes',
          ]);
          expect(followUp['broadcast'], isTrue);
          expect(followUp['event']['pubkey'], hostPubkey);
          expect(_eventStage(followUp['event']), 'negotiate');

          final followUpPay = await guest.runOk([
            '--dry-run',
            'reservations',
            'pay',
            '--trade-context',
            followUpTrade,
          ]);
          expect(followUpPay['willCreateSwap'], isFalse);
          expect(followUpPay['mode'], 'create-swap');

          final acceptTrade = await guest.offer(
            listingAnchor: listingAnchor,
            start: DateTime.utc(2027, 3, 5),
            end: DateTime.utc(2027, 3, 7),
            amount: _usd('1.00'),
          );
          final accept = await host.runOk([
            'reservations',
            'negotiation',
            'accept',
            '--input',
            jsonEncode({'tradeId': acceptTrade}),
            '--yes',
          ]);
          expect(accept['broadcast'], isTrue);
          expect(accept['event']['pubkey'], hostPubkey);
          expect(_eventStage(accept['event']), 'negotiate');

          final acceptedPay = await guest.runOk([
            '--dry-run',
            'reservations',
            'pay',
            '--trade-context',
            acceptTrade,
          ]);
          expect(acceptedPay['willCreateSwap'], isFalse);
          expect(acceptedPay['mode'], 'create-swap');
        },
        timeout: const Timeout(Duration(minutes: 4)),
      );

      test(
        'full price pay, watch, commit, and committed cancel',
        () async {
          final tradeId = await guest.offer(
            listingAnchor: listingAnchor,
            start: DateTime.utc(2027, 4, 5),
            end: DateTime.utc(2027, 4, 7),
          );
          final tradeContext = guest.lastTradeContext;
          expect(tradeContext, isNotNull);

          final payment = await guest.runOk([
            'reservations',
            'pay',
            '--trade-context',
            jsonEncode(tradeContext),
            '--yes',
          ]);
          final invoice = payment['invoice'] as String;
          final swapId = payment['boltzId'] as String;
          expect(invoice, startsWith('ln'));
          expect(swapId, isNotEmpty);
          expect(payment['qrImage'], startsWith('data:image/png;base64,'));

          final alby = AlbyHubClient(
            baseUri: Uri.parse('https://alby.hostr.development'),
            unlockPassword:
                Platform.environment['ALBYHUB_PASSWORD'] ?? 'Testing123!',
          );
          final paymentFuture = alby.payInvoice(invoice: invoice);
          try {
            final watched = await guest.runOk([
              'swaps',
              'watch',
              '--swap-id',
              swapId,
            ], timeout: const Duration(minutes: 5));
            expect(watched['escrowProofAvailable'], isTrue);
            expect(watched['claimTxHash'], isNotEmpty);

            await paymentFuture.timeout(const Duration(minutes: 1));
          } finally {
            alby.close();
          }

          final commit = await guest.runOk([
            'reservations',
            'commit',
            '--swap-id',
            swapId,
            '--yes',
          ]);
          expect(commit['published'], isTrue);
          expect(commit['tradeId'], tradeId);
          expect(_eventStage(commit['event']), 'commit');
          expect(commit['readbackCount'], greaterThanOrEqualTo(1));

          final cancel = await guest.runOk([
            'reservations',
            'cancel',
            '--input',
            jsonEncode({'tradeId': tradeId}),
            '--yes',
          ]);
          expect(cancel['mode'], 'committed');
          expect(cancel['published'], isTrue);
          expect(_eventStage(cancel['event']), 'cancel');
        },
        timeout: const Timeout(Duration(minutes: 10)),
      );
    },
    skip: runIntegration
        ? false
        : 'Set HOSTR_CLI_RUN_DEV_IT=1 to run against the local development stack.',
  );
}

Map<String, Object?> _usd(String value) => {'value': value, 'currency': 'USD'};

String _eventStage(Object? event) {
  final map = Map<String, dynamic>.from(event as Map);
  final content = jsonDecode(map['content'] as String) as Map<String, dynamic>;
  return content['stage'] as String;
}

void _acceptSelfSignedDevelopmentCerts() {
  HttpOverrides.global = _PermissiveHttpOverrides();
}

class _PermissiveHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    final client = super.createHttpClient(context);
    client.badCertificateCallback = (_, _, _) => true;
    return client;
  }
}

class _CliSession {
  _CliSession._(this.stateDir);

  final Directory stateDir;
  Map<String, dynamic>? lastTradeContext;

  static Future<_CliSession> create(String role) async {
    final dir = await Directory.systemTemp.createTemp('hostr-cli-$role-');
    return _CliSession._(dir);
  }

  Future<String> ensure({
    String? nsec,
    bool ensureSeed = false,
    bool ensureSellerConfig = false,
  }) async {
    final args = <String>['session', 'ensure'];
    if (nsec != null) args.addAll(['--nsec', nsec]);
    if (ensureSeed) args.add('--ensure-seed');
    if (ensureSellerConfig) args.add('--ensure-seller-config');
    final data = await runOk(args);
    return data['pubkey'] as String;
  }

  Future<void> profile(String name) async {
    await runOk([
      'profile',
      'edit',
      '--input',
      jsonEncode({
        'name': name,
        'about': 'Created by hostr_cli Dart integration tests',
      }),
      '--yes',
    ]);
  }

  Future<String> createListing({required String title}) async {
    final data = await runOk([
      'listings',
      'create',
      '--input',
      jsonEncode({
        'title': title,
        'description': 'Development reservation-flow listing',
        'address': 'not used when h3Tags are supplied',
        'h3Tags': ['599685771850416127'],
        'type': 'room',
        'guests': 2,
        'beds': 1,
        'bathrooms': 1,
        'images': ['https://hostr.network/example.jpg'],
        'price': {'amount': _usd('1.00'), 'frequency': 'day'},
      }),
      '--yes',
    ]);
    return data['listing']['anchor'] as String;
  }

  Future<String> offer({
    required String listingAnchor,
    required DateTime start,
    required DateTime end,
    Map<String, Object?>? amount,
  }) async {
    final input = <String, Object?>{
      'listingAnchor': listingAnchor,
      'start': start.toIso8601String(),
      'end': end.toIso8601String(),
    };
    if (amount != null) input['amount'] = amount;
    final data = await runOk([
      'reservations',
      'offer',
      '--input',
      jsonEncode(input),
      '--yes',
    ]);
    expect(data['delivery'], 'giftwrap');
    expect(_eventStage(data['event']), 'negotiate');
    final tradeContext = data['tradeContext'];
    if (tradeContext is Map) {
      lastTradeContext = Map<String, dynamic>.from(tradeContext);
    }
    return data['tradeId'] as String;
  }

  Future<Map<String, dynamic>> runOk(
    List<String> args, {
    Duration timeout = const Duration(minutes: 2),
  }) async {
    late _RunResult result;
    for (var attempt = 1; attempt <= 5; attempt++) {
      result = await _run([
        '--env',
        'development',
        '--json',
        '--relay',
        'ws://relay.hostr.development',
        '--state-dir',
        stateDir.path,
        '--allow-insecure-file-secrets',
        ...args,
      ], timeout: timeout);
      if (result.exitCode == 0 || !_isTransientRelayFailure(result)) break;
      await Future<void>.delayed(Duration(seconds: attempt));
    }
    expect(
      result.exitCode,
      0,
      reason: [
        result.stderr,
        result.stdout,
      ].where((line) => line.trim().isNotEmpty).join('\n'),
    );
    final json = _decodeProcessJson(result.stdout);
    expect(json['ok'], isTrue, reason: result.stdout);
    return Map<String, dynamic>.from(json['data'] as Map);
  }

  Future<void> dispose() async {
    if (await stateDir.exists()) {
      await stateDir.delete(recursive: true);
    }
  }
}

bool _isTransientRelayFailure(_RunResult result) {
  final output = '${result.stdout}\n${result.stderr}'.toLowerCase();
  return output.contains('could not connect to relay') ||
      output.contains('connection failed') ||
      output.contains('broadcast failed') ||
      output.contains('websocket');
}

Map<String, dynamic> _decodeProcessJson(String stdout) {
  final start = stdout.indexOf('{');
  if (start < 0) {
    throw FormatException('No JSON object found in stdout', stdout);
  }
  return jsonDecode(stdout.substring(start)) as Map<String, dynamic>;
}

Future<_RunResult> _run(
  List<String> args, {
  Duration timeout = const Duration(minutes: 2),
}) async {
  final process = await Process.start('dart', [
    'run',
    'bin/hostr.dart',
    ...args,
  ], workingDirectory: Directory.current.path);
  final stdoutFuture = utf8.decodeStream(process.stdout);
  final stderrFuture = utf8.decodeStream(process.stderr);
  late final int exitCode;
  try {
    exitCode = await process.exitCode.timeout(timeout);
  } on TimeoutException {
    process.kill(ProcessSignal.sigterm);
    exitCode = await process.exitCode.timeout(
      const Duration(seconds: 5),
      onTimeout: () {
        process.kill(ProcessSignal.sigkill);
        return -1;
      },
    );
    final stdout = await stdoutFuture;
    final stderr = await stderrFuture;
    return _RunResult(
      exitCode == -1 ? -1 : 124,
      stdout,
      [
        stderr,
        'Timed out after ${timeout.inSeconds}s: dart run bin/hostr.dart ${args.join(' ')}',
      ].where((line) => line.trim().isNotEmpty).join('\n'),
    );
  }
  return _RunResult(exitCode, await stdoutFuture, await stderrFuture);
}

class _RunResult {
  const _RunResult(this.exitCode, this.stdout, this.stderr);

  final int exitCode;
  final String stdout;
  final String stderr;
}
