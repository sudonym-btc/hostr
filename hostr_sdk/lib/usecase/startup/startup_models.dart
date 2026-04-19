import 'dart:async';

import 'package:equatable/equatable.dart';

enum StartupScope { public, user, background, escrow }

enum StartupItemId { relays, evm, relayHints, profile, inbox, accountServices }

enum StartupItemState { pending, running, complete, skipped, degraded, failed }

class StartupItemProgress extends Equatable {
  final StartupItemId id;
  final String label;
  final StartupItemState state;
  final String? detail;
  final Object? error;

  const StartupItemProgress({
    required this.id,
    required this.label,
    this.state = StartupItemState.pending,
    this.detail,
    this.error,
  });

  StartupItemProgress copyWith({
    StartupItemState? state,
    String? detail,
    Object? error,
    bool clearError = false,
  }) {
    return StartupItemProgress(
      id: id,
      label: label,
      state: state ?? this.state,
      detail: detail ?? this.detail,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [id, label, state, detail, error];
}

sealed class StartupResult extends Equatable {
  const StartupResult();
}

class PublicStartupReady extends StartupResult {
  const PublicStartupReady();

  @override
  List<Object?> get props => [];
}

class UserStartupReady extends StartupResult {
  final String pubkey;
  final bool hasMetadata;
  final bool inboxLive;

  const UserStartupReady({
    required this.pubkey,
    required this.hasMetadata,
    required this.inboxLive,
  });

  @override
  List<Object?> get props => [pubkey, hasMetadata, inboxLive];
}

class BackgroundStartupReady extends StartupResult {
  final String? pubkey;

  const BackgroundStartupReady({required this.pubkey});

  @override
  List<Object?> get props => [pubkey];
}

class StartupSnapshot extends Equatable {
  final StartupScope scope;
  final List<StartupItemProgress> items;
  final StartupResult? result;
  final Object? error;

  const StartupSnapshot({
    required this.scope,
    required this.items,
    this.result,
    this.error,
  });

  bool get isReady => result != null;
  bool get hasFailed => error != null;

  StartupSnapshot copyWith({
    List<StartupItemProgress>? items,
    StartupResult? result,
    Object? error,
    bool clearResult = false,
    bool clearError = false,
  }) {
    return StartupSnapshot(
      scope: scope,
      items: items ?? this.items,
      result: clearResult ? null : result ?? this.result,
      error: clearError ? null : error ?? this.error,
    );
  }

  @override
  List<Object?> get props => [scope, items, result, error];
}

class StartupRunToken {
  bool _cancelled = false;

  bool get isCancelled => _cancelled;

  void cancel() {
    _cancelled = true;
  }

  void throwIfCancelled() {
    if (_cancelled) {
      throw const StartupCancelledException();
    }
  }
}

class StartupCancelledException implements Exception {
  const StartupCancelledException();

  @override
  String toString() => 'Startup cancelled';
}

class StartupLaunchContext {
  final StartupRunToken token;
  final void Function(StartupSnapshot snapshot) emit;

  const StartupLaunchContext({required this.token, required this.emit});
}

abstract interface class StartupProfile {
  StartupScope get scope;

  Future<StartupResult> launch(StartupLaunchContext context);

  Future<void> stop();
}

class StartupTracker {
  final StartupScope scope;
  final StartupLaunchContext _context;
  late StartupSnapshot _snapshot;

  StartupTracker({
    required this.scope,
    required List<StartupItemProgress> items,
    required StartupLaunchContext context,
  }) : _context = context {
    _snapshot = StartupSnapshot(scope: scope, items: items);
    _context.emit(_snapshot);
  }

  StartupSnapshot get snapshot => _snapshot;

  Future<T> run<T>(StartupItemId id, Future<T> Function() task) async {
    _context.token.throwIfCancelled();
    _set(id, StartupItemState.running, clearError: true);

    try {
      final value = await task();
      _context.token.throwIfCancelled();
      _set(id, StartupItemState.complete, clearError: true);
      return value;
    } catch (e) {
      if (e is StartupCancelledException) rethrow;
      _set(id, StartupItemState.failed, error: e);
      rethrow;
    }
  }

  Future<T?> runOptional<T>(StartupItemId id, Future<T> Function() task) async {
    _context.token.throwIfCancelled();
    _set(id, StartupItemState.running, clearError: true);

    try {
      final value = await task();
      _context.token.throwIfCancelled();
      _set(id, StartupItemState.complete, clearError: true);
      return value;
    } catch (e) {
      if (e is StartupCancelledException) rethrow;
      _set(id, StartupItemState.degraded, error: e);
      return null;
    }
  }

  void skip(StartupItemId id, {String? detail}) {
    _set(id, StartupItemState.skipped, detail: detail, clearError: true);
  }

  void ready(StartupResult result) {
    _context.token.throwIfCancelled();
    _snapshot = _snapshot.copyWith(result: result, clearError: true);
    _context.emit(_snapshot);
  }

  void fail(Object error) {
    _snapshot = _snapshot.copyWith(error: error);
    _context.emit(_snapshot);
  }

  void _set(
    StartupItemId id,
    StartupItemState state, {
    String? detail,
    Object? error,
    bool clearError = false,
  }) {
    final items = _snapshot.items
        .map((item) {
          if (item.id != id) return item;
          return item.copyWith(
            state: state,
            detail: detail,
            error: error,
            clearError: clearError,
          );
        })
        .toList(growable: false);

    _snapshot = _snapshot.copyWith(
      items: items,
      clearResult: true,
      clearError: clearError,
    );
    _context.emit(_snapshot);
  }
}
