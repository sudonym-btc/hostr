import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../config.dart';
import '../auth/auth.dart';
import '../background_worker/background_worker.dart';
import '../calendar/calendar.dart';
import '../evm/operations/funds_monitor/funds_monitor_service.dart';
import '../messaging/messaging.dart';
import '../metadata/metadata.dart';
import '../nwc/nwc.dart';
import '../relays/relays.dart';
import '../reservations/reservations.dart';
import '../trades/payment_proof_orchestrator.dart';
import '../user_subscriptions/user_subscriptions.dart';
import 'startup_core.dart';
import 'startup_models.dart';
import 'user_startup_profile_bootstrap.dart';

@Singleton()
class PublicStartupProfile implements StartupProfile {
  final StartupCore _core;

  PublicStartupProfile({required StartupCore core}) : _core = core;

  @override
  StartupScope get scope => StartupScope.public;

  @override
  Future<StartupResult> launch(StartupLaunchContext context) async {
    final tracker = StartupTracker(
      scope: scope,
      context: context,
      items: const [
        StartupItemProgress(
          id: StartupItemId.relays,
          label: 'Connecting to relays',
        ),
        StartupItemProgress(id: StartupItemId.evm, label: 'Preparing swaps'),
      ],
    );

    try {
      await Future.wait([
        tracker.run(StartupItemId.relays, _core.ensureRelaysReady),
        tracker.run(StartupItemId.evm, _core.ensureEvmReady),
      ]);

      const result = PublicStartupReady();
      tracker.ready(result);
      return result;
    } catch (e) {
      if (e is! StartupCancelledException) {
        tracker.fail(e);
      }
      rethrow;
    }
  }

  @override
  Future<void> stop() async {}
}

@Singleton()
class BackgroundStartupProfile implements StartupProfile {
  final StartupCore _core;
  final Auth _auth;
  final Relays _relays;

  BackgroundStartupProfile({
    required StartupCore core,
    required Auth auth,
    required Relays relays,
  }) : _core = core,
       _auth = auth,
       _relays = relays;

  @override
  StartupScope get scope => StartupScope.background;

  @override
  Future<StartupResult> launch(StartupLaunchContext context) async {
    final tracker = StartupTracker(
      scope: scope,
      context: context,
      items: const [
        StartupItemProgress(
          id: StartupItemId.relays,
          label: 'Connecting to relays',
        ),
        StartupItemProgress(id: StartupItemId.evm, label: 'Preparing swaps'),
        StartupItemProgress(
          id: StartupItemId.relayHints,
          label: 'Loading relay list',
        ),
      ],
    );

    try {
      await Future.wait([
        tracker.run(StartupItemId.relays, _core.ensureRelaysReady),
        tracker.run(StartupItemId.evm, _core.ensureEvmReady),
      ]);
      context.token.throwIfCancelled();

      final pubkey = _auth.activeKeyPair?.publicKey;
      if (pubkey == null) {
        tracker.skip(StartupItemId.relayHints, detail: 'No active user');
      } else {
        await tracker.run(
          StartupItemId.relayHints,
          () => _relays.loadNip65Hints(pubkey),
        );
      }

      final result = BackgroundStartupReady(pubkey: pubkey);
      tracker.ready(result);
      return result;
    } catch (e) {
      if (e is! StartupCancelledException) {
        tracker.fail(e);
      }
      rethrow;
    }
  }

  @override
  Future<void> stop() async {}
}

@Singleton()
class UserStartupProfile implements StartupProfile {
  final StartupCore _core;
  final Auth _auth;
  final HostrConfig _config;
  final Relays _relays;
  final MetadataUseCase _metadata;
  final UserSubscriptions _userSubscriptions;
  final PaymentProofOrchestrator _paymentProofOrchestrator;
  final FundsMonitorService _fundsMonitor;
  final Nwc _nwc;
  final BackgroundWorker _backgroundWorker;
  final Calendar _calendar;
  final Messaging _messaging;
  final Reservations _reservations;
  late final UserStartupProfileBootstrapper _profileBootstrapper;

  UserStartupProfile({
    required StartupCore core,
    required Auth auth,
    required HostrConfig config,
    required Relays relays,
    required MetadataUseCase metadata,
    required UserSubscriptions userSubscriptions,
    required PaymentProofOrchestrator paymentProofOrchestrator,
    required FundsMonitorService fundsMonitor,
    required Nwc nwc,
    required BackgroundWorker backgroundWorker,
    required Calendar calendar,
    required Messaging messaging,
    required Reservations reservations,
  }) : _core = core,
       _auth = auth,
       _config = config,
       _relays = relays,
       _metadata = metadata,
       _userSubscriptions = userSubscriptions,
       _paymentProofOrchestrator = paymentProofOrchestrator,
       _fundsMonitor = fundsMonitor,
       _nwc = nwc,
       _backgroundWorker = backgroundWorker,
       _calendar = calendar,
       _messaging = messaging,
       _reservations = reservations {
    _profileBootstrapper = UserStartupProfileBootstrapper(metadata: _metadata);
  }

  @override
  StartupScope get scope => StartupScope.user;

  @override
  Future<StartupResult> launch(StartupLaunchContext context) async {
    final pubkey = _auth.activeKeyPair?.publicKey;
    if (pubkey == null) {
      throw StateError('Cannot launch user startup without an active user');
    }

    final tracker = StartupTracker(
      scope: scope,
      context: context,
      items: const [
        StartupItemProgress(
          id: StartupItemId.relays,
          label: 'Connecting to relays',
        ),
        StartupItemProgress(id: StartupItemId.evm, label: 'Preparing swaps'),
        StartupItemProgress(
          id: StartupItemId.relayHints,
          label: 'Loading relay list',
        ),
        StartupItemProgress(
          id: StartupItemId.profile,
          label: 'Loading profile',
        ),
        StartupItemProgress(id: StartupItemId.inbox, label: 'Opening inbox'),
        StartupItemProgress(
          id: StartupItemId.accountServices,
          label: 'Starting account services',
        ),
      ],
    );

    try {
      await Future.wait([
        tracker.run(StartupItemId.relays, _core.ensureRelaysReady),
        tracker.run(StartupItemId.evm, _core.ensureEvmReady),
      ]);
      context.token.throwIfCancelled();

      final hasNip65Future = tracker.run(
        StartupItemId.relayHints,
        () => _relays.loadNip65Hints(pubkey),
      );

      final metadataFuture = tracker.run(
        StartupItemId.profile,
        () => _profileBootstrapper.run(
          pubkey: pubkey,
          hasNip65Future: hasNip65Future,
        ),
      );

      final inboxFuture = tracker.runOptional(StartupItemId.inbox, () async {
        await hasNip65Future;
        context.token.throwIfCancelled();
        await _userSubscriptions.start();
        return _userSubscriptions.isLive
            .where((live) => live)
            .first
            .timeout(const Duration(seconds: 30), onTimeout: () => false);
      });

      final results = await Future.wait<Object?>([metadataFuture, inboxFuture]);
      context.token.throwIfCancelled();

      await tracker.run(StartupItemId.accountServices, () async {
        await Future.wait([
          _paymentProofOrchestrator.start(),
          _fundsMonitor.start(),
          _nwc.start(),
          _backgroundWorker.watch(onProgress: _onProgressFromConfig()),
          _calendar.start(),
        ]);
      });

      final profileBootstrap =
          results[0] as UserStartupProfileBootstrapResult;
      final result = UserStartupReady(
        pubkey: pubkey,
        hasMetadata: profileBootstrap.hasMetadata,
        inboxLive: results[1] == true,
      );
      tracker.ready(result);
      return result;
    } catch (e) {
      if (e is! StartupCancelledException) {
        tracker.fail(e);
      }
      rethrow;
    }
  }

  @override
  Future<void> stop() async {
    await _backgroundWorker.stop();
    await _calendar.stop();
    await _fundsMonitor.stop();
    await _paymentProofOrchestrator.reset();
    await _userSubscriptions.reset();
    await _messaging.threads.reset();
    await _nwc.reset();
    await _reservations.reset();
  }

  OnBackgroundProgress? _onProgressFromConfig() {
    final show = _config.showNotification;
    if (show == null) return null;
    return (notification) => show(
      id: notification.operationId.hashCode,
      title: 'Hostr',
      body: notification.body,
      payload: notification.payload,
    );
  }
}
