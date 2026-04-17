import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

/// Describes each step of the startup bootstrap process.
enum StartupStep {
  relay('Connecting to relays'),
  relayList('Fetching relay list'),
  metadata('Loading profile'),
  messages('Syncing messages'),
  funds('Scanning funds');

  final String label;
  const StartupStep(this.label);
}

/// The state emitted by [StartupGateCubit].
sealed class StartupGateState extends Equatable {
  const StartupGateState();

  @override
  List<Object?> get props => [];
}

/// Initial state – nothing started yet.
/// The UI should render as an extended splash (logo, no progress indicators).
class StartupGateInitial extends StartupGateState {
  const StartupGateInitial();
}

/// A step is in progress. [completedSteps] tracks what has finished so far.
class StartupGateInProgress extends StartupGateState {
  final StartupStep currentStep;
  final Set<StartupStep> completedSteps;

  const StartupGateInProgress({
    required this.currentStep,
    this.completedSteps = const {},
  });

  double get progress => completedSteps.length / StartupStep.values.length;

  @override
  List<Object?> get props => [currentStep, completedSteps];
}

/// All steps completed.
///
/// [hasMetadata] – whether an existing profile was found.
class StartupGateReady extends StartupGateState {
  final bool hasMetadata;
  const StartupGateReady({required this.hasMetadata});

  @override
  List<Object?> get props => [hasMetadata];
}

/// Something went wrong.
class StartupGateError extends StartupGateState {
  final String message;
  const StartupGateError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Orchestrates the cold-start and post-sign-in bootstrap:
///
/// 1. Connect to bootstrap relays (every startup).
/// 2. Fetch the user's NIP-65 relay list (logged in only).
/// 3. Download current user metadata (logged in only).
/// 4. Wait for giftwrap message sync to go live (logged in only).
class StartupGateCubit extends Cubit<StartupGateState> {
  final Hostr _hostr;
  StreamSubscription<StreamStatus>? _threadsSub;

  StartupGateCubit({required Hostr hostr})
    : _hostr = hostr,
      super(const StartupGateInitial());

  /// Run the full startup sequence. Safe to call multiple times — it
  /// no-ops if already in progress or complete.
  Future<void> run() async {
    if (state is StartupGateInProgress || state is StartupGateReady) return;

    final completed = <StartupStep>{};

    try {
      // ── Step 1: Relay connection ───────────────────────────────────────
      _emitStep(StartupStep.relay, completed);
      await _hostr.connect();
      completed.add(StartupStep.relay);

      // ── Unauthenticated path: skip directly to ready ───────────────────
      final pubkey = _hostr.auth.activeKeyPair?.publicKey;
      if (pubkey == null) {
        emit(const StartupGateReady(hasMetadata: true));
        return;
      }

      // ── Step 2: NIP-65 relay list sync ─────────────────────────────────
      // The auth-state listener inside Hostr.connect() already triggers
      // NIP-65 sync. We show the step for visual progress, then mark done.
      _emitStep(StartupStep.relayList, completed);
      completed.add(StartupStep.relayList);

      // ── Step 3: Load metadata ──────────────────────────────────────────
      _emitStep(StartupStep.metadata, completed);
      final metadata = await _hostr.metadata.loadMetadata(pubkey);
      completed.add(StartupStep.metadata);

      // ── Step 4: Wait for message sync ──────────────────────────────────
      _emitStep(StartupStep.messages, completed);
      await _waitForThreadSync();
      completed.add(StartupStep.messages);

      // ── Step 5: Scan funds ─────────────────────────────────────────────
      _emitStep(StartupStep.funds, completed);
      // await _hostr.fundsMonitor.seedAndAwait();
      completed.add(StartupStep.funds);

      // ── Done ───────────────────────────────────────────────────────────
      emit(StartupGateReady(hasMetadata: metadata != null));
    } catch (e) {
      emit(StartupGateError(e.toString()));
    }
  }

  /// Wait until the thread stream reports [StreamStatusLive], or time out
  /// after 30 seconds so the user isn't stuck forever.
  Future<void> _waitForThreadSync() async {
    final completer = Completer<void>();

    // If threads are already live, return immediately.
    _threadsSub = _hostr.messaging.threads.status.listen((status) {
      if (status is StreamStatusLive && !completer.isCompleted) {
        completer.complete();
      }
    });

    // Safety timeout so the user isn't stuck on a spinner forever.
    await completer.future.timeout(
      const Duration(seconds: 30),
      onTimeout: () {},
    );

    _threadsSub?.cancel();
    _threadsSub = null;
  }

  void _emitStep(StartupStep step, Set<StartupStep> completed) {
    emit(
      StartupGateInProgress(
        currentStep: step,
        completedSteps: Set.of(completed),
      ),
    );
  }

  /// Reset to initial so the cubit can be re-used on re-login.
  void reset() {
    _threadsSub?.cancel();
    _threadsSub = null;
    emit(const StartupGateInitial());
  }

  @override
  Future<void> close() {
    _threadsSub?.cancel();
    return super.close();
  }
}
