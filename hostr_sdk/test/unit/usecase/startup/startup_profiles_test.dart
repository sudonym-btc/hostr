@Tags(['unit'])
library;

import 'dart:async';

import 'package:hostr_sdk/config.dart';
import 'package:hostr_sdk/mocks/usecase_mocks.mocks.dart' as usecase_mocks;
import 'package:hostr_sdk/usecase/background_worker/background_worker.dart';
import 'package:hostr_sdk/usecase/auth/auth.dart';
import 'package:hostr_sdk/usecase/calendar/calendar.dart';
import 'package:hostr_sdk/usecase/deterministic_keys/account_seed_store.dart';
import 'package:hostr_sdk/usecase/evm/config/evm_config.dart';
import 'package:hostr_sdk/usecase/evm/operations/funds_monitor/funds_monitor_service.dart';
import 'package:hostr_sdk/usecase/user_subscriptions/user_subscriptions.dart';
import 'package:hostr_sdk/usecase/trades/payment_proof_orchestrator.dart';
import 'package:hostr_sdk/usecase/relays/relays.dart';
import 'package:hostr_sdk/usecase/startup/main.dart';
import 'package:mockito/mockito.dart';
import 'package:models/main.dart';
import 'package:ndk/entities.dart';
import 'package:ndk/shared/nips/nip01/key_pair.dart';
import 'package:rxdart/rxdart.dart';
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

    test(
      'user startup reports incomplete profile when metadata stays missing',
      () async {
        final auth = usecase_mocks.MockAuth();
        final relays = usecase_mocks.MockRelays();
        final metadata = usecase_mocks.MockMetadataUseCase();
        final seedStore = _FakeAccountSeedStore();
        final userSubscriptions = _FakeUserSubscriptions()..markLive();
        final paymentProof = _FakePaymentProofOrchestrator();
        final fundsMonitor = _FakeFundsMonitorService();
        final nwc = usecase_mocks.MockNwc();
        final backgroundWorker = _FakeBackgroundWorker();
        final calendar = _FakeCalendar();
        final messaging = usecase_mocks.MockMessaging();
        final reservations = usecase_mocks.MockReservations();

        when(
          auth.activeKeyPair,
        ).thenReturn(KeyPair('privkey', 'user-pubkey', null, null));
        when(auth.activePubkey).thenReturn('user-pubkey');
        when(
          relays.loadNip65Hints('user-pubkey'),
        ).thenAnswer((_) async => false);
        when(
          metadata.loadMetadata('user-pubkey', forceRefresh: false),
        ).thenAnswer((_) async => null);
        when(nwc.start()).thenAnswer((_) async {});

        final profile = UserStartupProfile(
          core: _FakeStartupCore(),
          auth: auth,
          config: HostrConfig(
            bootstrapRelays: const [],
            bootstrapBlossom: const [],
            hostrRelay: '',
            evmConfig: const EvmConfig(),
          ),
          relays: relays,
          accountSeedStore: seedStore,
          metadata: metadata,
          userSubscriptions: userSubscriptions,
          paymentProofOrchestrator: paymentProof,
          fundsMonitor: fundsMonitor,
          nwc: nwc,
          backgroundWorker: backgroundWorker,
          calendar: calendar,
          messaging: messaging,
          reservations: reservations,
        );

        final result = await profile.launch(
          StartupLaunchContext(token: StartupRunToken(), emit: (_) {}),
        );

        expect(
          result,
          const UserStartupReady(
            pubkey: 'user-pubkey',
            hasMetadata: false,
            inboxLive: true,
          ),
        );
        expect(userSubscriptions.starts, 1);
        expect(seedStore.ensureCalls, ['user-pubkey']);
        expect(paymentProof.starts, 1);
        expect(fundsMonitor.starts, 1);
        expect(backgroundWorker.watchCalls, 1);
        expect(calendar.starts, 1);
        verify(relays.loadNip65Hints('user-pubkey')).called(1);
        verify(
          metadata.loadMetadata('user-pubkey', forceRefresh: false),
        ).called(1);
        verifyNever(metadata.loadMetadata('user-pubkey', forceRefresh: true));
        verifyNever(metadata.ensureUserConfig('user-pubkey'));
      },
    );

    test('user startup surfaces seed backup publish failures', () async {
      final auth = usecase_mocks.MockAuth();
      final relays = usecase_mocks.MockRelays();
      final metadata = usecase_mocks.MockMetadataUseCase();
      final seedFailure = StateError('Unable to publish seed backup');
      final seedStore = _FakeAccountSeedStore()..failure = seedFailure;
      final userSubscriptions = _FakeUserSubscriptions()..markLive();
      final paymentProof = _FakePaymentProofOrchestrator();
      final fundsMonitor = _FakeFundsMonitorService();
      final nwc = usecase_mocks.MockNwc();
      final backgroundWorker = _FakeBackgroundWorker();
      final calendar = _FakeCalendar();
      final messaging = usecase_mocks.MockMessaging();
      final reservations = usecase_mocks.MockReservations();
      final snapshots = <StartupSnapshot>[];

      when(
        auth.activeKeyPair,
      ).thenReturn(KeyPair('privkey', 'user-pubkey', null, null));
      when(auth.activePubkey).thenReturn('user-pubkey');
      when(relays.loadNip65Hints('user-pubkey')).thenAnswer((_) async => true);

      final profile = UserStartupProfile(
        core: _FakeStartupCore(),
        auth: auth,
        config: HostrConfig(
          bootstrapRelays: const [],
          bootstrapBlossom: const [],
          hostrRelay: '',
          evmConfig: const EvmConfig(),
        ),
        relays: relays,
        accountSeedStore: seedStore,
        metadata: metadata,
        userSubscriptions: userSubscriptions,
        paymentProofOrchestrator: paymentProof,
        fundsMonitor: fundsMonitor,
        nwc: nwc,
        backgroundWorker: backgroundWorker,
        calendar: calendar,
        messaging: messaging,
        reservations: reservations,
      );

      await expectLater(
        profile.launch(
          StartupLaunchContext(token: StartupRunToken(), emit: snapshots.add),
        ),
        throwsA(same(seedFailure)),
      );

      expect(snapshots.last.hasFailed, isTrue);
      expect(snapshots.last.error, same(seedFailure));
      expect(
        _states(snapshots.last)[StartupItemId.seed],
        StartupItemState.failed,
      );
      expect(seedStore.ensureCalls, ['user-pubkey']);
      expect(userSubscriptions.starts, 0);
      expect(paymentProof.starts, 0);
      expect(fundsMonitor.starts, 0);
      expect(backgroundWorker.watchCalls, 0);
      expect(calendar.starts, 0);
      verifyNever(
        metadata.loadMetadata(any, forceRefresh: anyNamed('forceRefresh')),
      );
    });

    test('user startup force refreshes metadata when NIP-65 exists', () async {
      final auth = usecase_mocks.MockAuth();
      final relays = usecase_mocks.MockRelays();
      final metadata = usecase_mocks.MockMetadataUseCase();
      final seedStore = _FakeAccountSeedStore();
      final userSubscriptions = _FakeUserSubscriptions()..markLive();
      final paymentProof = _FakePaymentProofOrchestrator();
      final fundsMonitor = _FakeFundsMonitorService();
      final nwc = usecase_mocks.MockNwc();
      final backgroundWorker = _FakeBackgroundWorker();
      final calendar = _FakeCalendar();
      final messaging = usecase_mocks.MockMessaging();
      final reservations = usecase_mocks.MockReservations();
      final refreshed = _profile('user-pubkey');

      when(
        auth.activeKeyPair,
      ).thenReturn(KeyPair('privkey', 'user-pubkey', null, null));
      when(auth.activePubkey).thenReturn('user-pubkey');
      when(relays.loadNip65Hints('user-pubkey')).thenAnswer((_) async => true);
      when(
        metadata.loadMetadata('user-pubkey', forceRefresh: false),
      ).thenAnswer((_) async => null);
      when(
        metadata.loadMetadata('user-pubkey', forceRefresh: true),
      ).thenAnswer((_) async => refreshed);
      when(nwc.start()).thenAnswer((_) async {});

      final profile = UserStartupProfile(
        core: _FakeStartupCore(),
        auth: auth,
        config: HostrConfig(
          bootstrapRelays: const [],
          bootstrapBlossom: const [],
          hostrRelay: '',
          evmConfig: const EvmConfig(),
        ),
        relays: relays,
        accountSeedStore: seedStore,
        metadata: metadata,
        userSubscriptions: userSubscriptions,
        paymentProofOrchestrator: paymentProof,
        fundsMonitor: fundsMonitor,
        nwc: nwc,
        backgroundWorker: backgroundWorker,
        calendar: calendar,
        messaging: messaging,
        reservations: reservations,
      );

      final result = await profile.launch(
        StartupLaunchContext(token: StartupRunToken(), emit: (_) {}),
      );

      expect(
        result,
        const UserStartupReady(
          pubkey: 'user-pubkey',
          hasMetadata: true,
          inboxLive: true,
        ),
      );
      verify(
        metadata.loadMetadata('user-pubkey', forceRefresh: false),
      ).called(1);
      expect(seedStore.ensureCalls, ['user-pubkey']);
      verify(
        metadata.loadMetadata('user-pubkey', forceRefresh: true),
      ).called(1);
      verifyNever(metadata.ensureUserConfig('user-pubkey'));
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
    Duration timeout = const Duration(seconds: 30),
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

  @override
  String? get activePubkey => pubkey;
}

class _FakeAccountSeedStore extends Fake implements AccountSeedStore {
  final List<String> ensureCalls = [];
  Object? failure;

  @override
  Future<void> ensureReady({String? pubkey}) async {
    if (pubkey != null) {
      ensureCalls.add(pubkey);
    }
    final error = failure;
    if (error != null) {
      throw error;
    }
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

class _FakeUserSubscriptions extends Fake implements UserSubscriptions {
  final BehaviorSubject<bool> _isLive = BehaviorSubject.seeded(false);
  int starts = 0;

  void markLive() => _isLive.add(true);

  @override
  ValueStream<bool> get isLive => _isLive;

  @override
  Future<void> start({bool validateReservationGroups = true}) async {
    starts += 1;
  }
}

class _FakePaymentProofOrchestrator extends Fake
    implements PaymentProofOrchestrator {
  int starts = 0;

  @override
  Future<void> start() async {
    starts += 1;
  }
}

class _FakeFundsMonitorService extends Fake implements FundsMonitorService {
  int starts = 0;

  @override
  Future<void> start() async {
    starts += 1;
  }
}

class _FakeBackgroundWorker extends Fake implements BackgroundWorker {
  int watchCalls = 0;

  @override
  Future<void> watch({OnBackgroundProgress? onProgress}) async {
    watchCalls += 1;
  }
}

class _FakeCalendar extends Fake implements Calendar {
  int starts = 0;

  @override
  Future<void> start() async {
    starts += 1;
  }
}

ProfileMetadata _profile(String pubkey) {
  return ProfileMetadata.fromNostrEvent(
    Nip01Event(
      pubKey: pubkey,
      createdAt: 1,
      kind: Metadata.kKind,
      tags: const [],
      content: '{"name":"Test"}',
      sig: 'sig',
      id: 'id-$pubkey',
    ),
  );
}

Map<StartupItemId, StartupItemState> _states(StartupSnapshot snapshot) {
  return {for (final item in snapshot.items) item.id: item.state};
}
