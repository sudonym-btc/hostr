@Tags(['unit'])
library;

import 'dart:async';

import 'package:hostr_sdk/usecase/evm/evm.dart';
import 'package:hostr_sdk/usecase/relays/relays.dart';
import 'package:hostr_sdk/usecase/startup/startup_core.dart';
import 'package:mockito/mockito.dart';
import 'package:test/test.dart';

void main() {
  group('StartupCore', () {
    test('uses a 30 second default relay readiness timeout', () async {
      final relays = _FakeRelays();
      final core = StartupCore(relays: relays, evm: _FakeEvm());

      await core.ensureRelaysReady();

      expect(relays.startSeedRelaysCalls, 1);
      expect(relays.awaitCoreRelayCalls, 1);
      expect(relays.lastTimeout, const Duration(seconds: 30));
    });

    test('reuses the in-flight relay readiness future', () async {
      final relays = _FakeRelays()..awaitCompleter = Completer<void>();
      final core = StartupCore(relays: relays, evm: _FakeEvm());

      final first = core.ensureRelaysReady();
      final second = core.ensureRelaysReady();

      expect(identical(first, second), isTrue);
      await pumpEventQueue();
      expect(relays.startSeedRelaysCalls, 1);
      expect(relays.awaitCoreRelayCalls, 1);

      relays.awaitCompleter!.complete();
      await Future.wait([first, second]);
    });
  });
}

class _FakeRelays extends Fake implements Relays {
  int startSeedRelaysCalls = 0;
  int awaitCoreRelayCalls = 0;
  Duration? lastTimeout;
  Completer<void>? awaitCompleter;

  @override
  Future<void> startSeedRelays() async {
    startSeedRelaysCalls += 1;
  }

  @override
  Future<void> awaitCoreRelay({
    Duration timeout = const Duration(seconds: 30),
  }) {
    awaitCoreRelayCalls += 1;
    lastTimeout = timeout;
    return awaitCompleter?.future ?? Future.value();
  }
}

class _FakeEvm extends Fake implements Evm {
  @override
  Future<void> init() async {}
}
