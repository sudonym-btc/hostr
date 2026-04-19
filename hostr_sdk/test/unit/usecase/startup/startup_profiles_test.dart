@Tags(['unit'])
library;

import 'dart:async';

import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/relays/relays.dart';
import 'package:hostr_sdk/usecase/startup/main.dart';
import 'package:mockito/mockito.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:test/test.dart';

void main() {
  group('Startup profiles', () {
    test('public startup starts relay and EVM readiness', () async {
      final core = _FakeStartupCore()
        ..relayCompleter = Completer<void>()
        ..evmCompleter = Completer<void>();
      final profile = PublicStartupProfile(core: core);
      final snapshots = <StartupSnapshot>[];

      final run = profile.launch(
        StartupLaunchContext(token: StartupRunToken(), emit: snapshots.add),
      );
      await pumpEventQueue();

      expect(core.relayStarts, 1);
      expect(core.evmStarts, 1);
      expect(_states(snapshots.last), {
        StartupItemId.relays: StartupItemState.running,
        StartupItemId.evm: StartupItemState.running,
      });

      core.relayCompleter!.complete();
      core.evmCompleter!.complete();

      final result = await run;
      expect(result, isA<PublicStartupReady>());
      expect(snapshots.last.isReady, isTrue);
    });

    test(
      'background startup skips relay hints without an active user',
      () async {
        final profile = BackgroundStartupProfile(
          core: _FakeStartupCore(),
          auth: _FakeAuth(),
          relays: _FakeRelays(),
        );
        final snapshots = <StartupSnapshot>[];

        final result = await profile.launch(
          StartupLaunchContext(token: StartupRunToken(), emit: snapshots.add),
        );

        expect(result, const BackgroundStartupReady(pubkey: null));
        expect(
          _states(snapshots.last)[StartupItemId.relayHints],
          StartupItemState.skipped,
        );
      },
    );

    test('background startup loads relay hints for the active user', () async {
      final relays = _FakeRelays();
      final profile = BackgroundStartupProfile(
        core: _FakeStartupCore(),
        auth: _FakeAuth(pubkey: 'pubkey'),
        relays: relays,
      );

      final result = await profile.launch(
        StartupLaunchContext(token: StartupRunToken(), emit: (_) {}),
      );

      expect(result, const BackgroundStartupReady(pubkey: 'pubkey'));
      expect(relays.loadedPubkeys, ['pubkey']);
    });
  });
}

class _FakeStartupCore extends Fake implements StartupCore {
  int relayStarts = 0;
  int evmStarts = 0;
  Completer<void>? relayCompleter;
  Completer<void>? evmCompleter;

  @override
  Future<void> ensureRelaysReady({
    Duration timeout = const Duration(seconds: 15),
  }) {
    relayStarts++;
    return relayCompleter?.future ?? Future.value();
  }

  @override
  Future<void> ensureEvmReady() {
    evmStarts++;
    return evmCompleter?.future ?? Future.value();
  }
}

class _FakeAuth extends Fake implements Auth {
  final String? pubkey;

  _FakeAuth({this.pubkey});

  @override
  KeyPair? get activeKeyPair {
    final value = pubkey;
    return value == null ? null : KeyPair('privkey', value, null, null);
  }
}

class _FakeRelays extends Fake implements Relays {
  final List<String> loadedPubkeys = [];

  @override
  Future<bool> loadNip65Hints(String pubkey) async {
    loadedPubkeys.add(pubkey);
    return true;
  }
}

Map<StartupItemId, StartupItemState> _states(StartupSnapshot snapshot) {
  return {for (final item in snapshot.items) item.id: item.state};
}
