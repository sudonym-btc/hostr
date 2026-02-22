import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:ndk/ndk.dart' show Filter;

/// Describes each step of the post-login bootstrap process.
enum OnboardingStep {
  relayList('Fetching relay list…'),
  connectRelays('Connecting to relays…'),
  metadata('Loading profile…'),
  messages('Syncing messages…');

  final String label;
  const OnboardingStep(this.label);
}

/// The state emitted by [OnboardingCubit].
sealed class OnboardingState extends Equatable {
  const OnboardingState();

  @override
  List<Object?> get props => [];
}

/// Initial state – nothing started yet.
class OnboardingInitial extends OnboardingState {
  const OnboardingInitial();
}

/// A step is in progress. [completedSteps] tracks what has finished so far.
class OnboardingInProgress extends OnboardingState {
  final OnboardingStep currentStep;
  final Set<OnboardingStep> completedSteps;

  const OnboardingInProgress({
    required this.currentStep,
    this.completedSteps = const {},
  });

  double get progress => completedSteps.length / OnboardingStep.values.length;

  @override
  List<Object?> get props => [currentStep, completedSteps];
}

/// All steps completed.
///
/// [hasMetadata] – whether an existing profile was found.
/// [isHost] – whether the user owns at least one listing and should be
///            switched to host mode.
class OnboardingComplete extends OnboardingState {
  final bool hasMetadata;
  final bool isHost;
  const OnboardingComplete({required this.hasMetadata, required this.isHost});

  @override
  List<Object?> get props => [hasMetadata, isHost];
}

/// Something went wrong.
class OnboardingError extends OnboardingState {
  final String message;
  const OnboardingError(this.message);

  @override
  List<Object?> get props => [message];
}

/// Orchestrates the post-login bootstrap:
///
/// 1. Fetch the user's NIP-65 relay list from bootstrap relays.
/// 2. Connect to the discovered relays.
/// 3. Download current user metadata.
/// 4. Wait for giftwrap message sync to go live.
class OnboardingCubit extends Cubit<OnboardingState> {
  final Hostr _hostr;
  StreamSubscription<StreamStatus>? _threadsSub;

  OnboardingCubit({required Hostr hostr})
    : _hostr = hostr,
      super(const OnboardingInitial());

  /// Run the full onboarding sequence. Safe to call multiple times — it
  /// no-ops if already in progress or complete.
  Future<void> run() async {
    if (state is OnboardingInProgress || state is OnboardingComplete) return;

    final pubkey = _hostr.auth.activeKeyPair?.publicKey;
    if (pubkey == null) return;

    final completed = <OnboardingStep>{};

    try {
      // ── Step 1–2: Relay sync ─────────────────────────────────────────
      // NIP-65 relay list fetch and connection is handled automatically
      // by Hostr.start() when auth state changes to LoggedIn. We just
      // mark these steps as complete for the progress UI.
      _emitStep(OnboardingStep.relayList, completed);
      completed.add(OnboardingStep.relayList);
      _emitStep(OnboardingStep.connectRelays, completed);
      completed.add(OnboardingStep.connectRelays);

      // ── Step 3: Load metadata ────────────────────────────────────────
      _emitStep(OnboardingStep.metadata, completed);
      final metadata = await _hostr.metadata.loadMetadata(pubkey);
      completed.add(OnboardingStep.metadata);

      // ── Step 4: Wait for message sync ────────────────────────────────
      _emitStep(OnboardingStep.messages, completed);
      await _waitForThreadSync();
      completed.add(OnboardingStep.messages);

      // ── Check for existing listings (host mode) ──────────────────────
      final hasListing = await _checkHasListing(pubkey);

      // ── Done ─────────────────────────────────────────────────────────
      emit(
        OnboardingComplete(hasMetadata: metadata != null, isHost: hasListing),
      );
    } catch (e) {
      emit(OnboardingError(e.toString()));
    }
  }

  Future<bool> _checkHasListing(String pubkey) async {
    try {
      final listing = await _hostr.listings.getOne(Filter(authors: [pubkey]));
      return listing != null;
    } catch (_) {
      return false;
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

  void _emitStep(OnboardingStep step, Set<OnboardingStep> completed) {
    emit(
      OnboardingInProgress(
        currentStep: step,
        completedSteps: Set.of(completed),
      ),
    );
  }

  /// Reset to initial so the cubit can be re-used on re-login.
  void reset() {
    _threadsSub?.cancel();
    _threadsSub = null;
    emit(const OnboardingInitial());
  }

  @override
  Future<void> close() {
    _threadsSub?.cancel();
    return super.close();
  }
}
