@Tags(['integration', 'docker'])
library;

import 'dart:async';

import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/seed/signet_bunker_client.dart';
import 'package:logger/logger.dart';
import 'package:ndk/ndk.dart' show Nip01Event, Nip01Utils;
import 'package:ndk/shared/nips/nip01/bip340.dart' as ndk_bip340;
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

import '../../../support/integration_test_harness.dart';

const _testTimeout = Timeout(Duration(minutes: 3));
const _keyPrefix = 'hostr-sdk-bunker-signin';

void main() {
  late IntegrationTestHarness harness;
  late Hostr hostr;

  setUpAll(() async {
    harness = await IntegrationTestHarness.create(
      name: 'hostr_bunker_signin_it',
      seed: DateTime.now().microsecondsSinceEpoch,
      logLevel: Level.debug,
      cleanHydratedStorage: true,
    );
    hostr = harness.hostr;
  });

  tearDown(() async {
    await hostr.auth.logout();
  });

  tearDownAll(() async {
    await harness.dispose();
    IntegrationTestHarness.resetLogLevel();
  });

  test(
    'bunker signin test signs in and signs an event through Signet',
    () async {
      final buyer = harness.seeds.deriveKeyPair(
        DateTime.now().microsecondsSinceEpoch % 1000000000,
      );
      await _withBunkerSignedIn(
        hostr: hostr,
        buyer: buyer,
        body: () async {
          expect(hostr.auth.isBunkerBacked, isTrue);
          expect(hostr.ndk.accounts.canSign, isTrue);

          final unsigned = Nip01Event(
            pubKey: buyer.publicKey,
            kind: 1,
            tags: const [],
            content:
                'hostr bunker signin smoke ${DateTime.now().toIso8601String()}',
            createdAt: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          );

          final signed = await hostr.ndk.accounts
              .sign(unsigned)
              .timeout(const Duration(seconds: 30));

          expect(signed.pubKey, buyer.publicKey);
          expect(signed.sig, isNotNull);
          expect(Nip01Utils.isIdValid(signed), isTrue);
          expect(
            ndk_bip340.Bip340.verify(signed.id, signed.sig!, signed.pubKey),
            isTrue,
          );
        },
      );
    },
    timeout: _testTimeout,
  );
}

Future<void> _withBunkerSignedIn({
  required Hostr hostr,
  required KeyPair buyer,
  required Future<void> Function() body,
}) async {
  final signet = SignetBunkerClient(
    baseUri: Uri.parse('https://bunker-nostr.hostr.development/'),
    maxRateLimitRetries: 12,
  );
  final keyName = '$_keyPrefix-${DateTime.now().microsecondsSinceEpoch}';
  _SignetApprovalLoop? approvals;

  try {
    final imported = await signet.importNsec(
      keyName: keyName,
      nsec: buyer.privateKeyBech32!,
    );
    if (imported.bunkerUri.isEmpty) {
      throw StateError('Signet did not return a bunker URI for $keyName');
    }

    approvals = _SignetApprovalLoop(signet: signet, keyName: keyName);
    await approvals.start();
    // Signet reports the key as online even though nostr-tools may not have
    // finished registering the backend relay subscription. The first bunker
    // connect is an ephemeral kind 24133 event, so logging in immediately can
    // publish it just before Signet is actually listening.
    await Future<void>.delayed(const Duration(milliseconds: 200));
    await hostr.auth
        .signinWithBunkerUrl(imported.bunkerUri)
        .timeout(const Duration(seconds: 30));
    await body();
  } finally {
    await approvals?.stop();
    try {
      await signet.deleteKey(keyName);
    } finally {
      await signet.close();
    }
  }
}

class _SignetApprovalLoop {
  _SignetApprovalLoop({required this.signet, required this.keyName});

  final SignetBunkerClient signet;
  final String keyName;

  bool _stopped = false;
  Future<void>? _loop;
  final Set<String> _submittedRequestIds = <String>{};

  Future<void> start() async {
    _loop ??= _approveLoop();
  }

  Future<void> stop() async {
    _stopped = true;
    await _loop;
  }

  Future<void> _approveLoop() async {
    while (!_stopped) {
      try {
        final pending = (await signet.requests())
            .where(
              (request) =>
                  request.keyName == keyName &&
                  !_submittedRequestIds.contains(request.id),
            )
            .toList(growable: false);
        if (pending.isNotEmpty) {
          print(
            'BUNKER_SIGNIN_IT approve key=$keyName '
            'ids=${pending.map((request) => request.id).join(',')}',
          );
          await signet.approveBatch(pending);
          _submittedRequestIds.addAll(pending.map((request) => request.id));
        }
      } on SignetBunkerException catch (error) {
        print('BUNKER_SIGNIN_IT approve-error $error');
        if (error.statusCode == 429) {
          _submittedRequestIds.clear();
          await Future<void>.delayed(const Duration(seconds: 5));
        } else {
          await Future<void>.delayed(const Duration(seconds: 1));
        }
      } catch (error) {
        print('BUNKER_SIGNIN_IT approve-error $error');
        await Future<void>.delayed(const Duration(seconds: 1));
      }
      await Future<void>.delayed(const Duration(milliseconds: 500));
    }
  }
}
