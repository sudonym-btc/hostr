import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

const startupGateInitialItems = [
  StartupItemProgress(id: StartupItemId.relays, label: 'Connecting to relays'),
];

sealed class StartupGateState extends Equatable {
  const StartupGateState();

  @override
  List<Object?> get props => [];
}

class StartupGateInitial extends StartupGateState {
  const StartupGateInitial();
}

class StartupGateInProgress extends StartupGateState {
  final List<StartupItemProgress> items;

  const StartupGateInProgress({required this.items});

  int get completedItemCount {
    return items.where((item) => item.isFinished).length;
  }

  int get totalItemCount => items.length;

  double get progress {
    if (items.isEmpty) return 0;
    return completedItemCount / totalItemCount;
  }

  StartupItemProgress get currentItem {
    return items.firstWhere(
      (item) => item.state == StartupItemState.running,
      orElse: () => items.firstWhere(
        (item) => item.state == StartupItemState.pending,
        orElse: () => items.last,
      ),
    );
  }

  @override
  List<Object?> get props => [items];
}

extension on StartupItemProgress {
  bool get isFinished {
    return state == StartupItemState.complete ||
        state == StartupItemState.skipped ||
        state == StartupItemState.degraded;
  }
}

class StartupGateReady extends StartupGateState {
  final StartupScope scope;
  final String? pubkey;
  final bool hasMetadata;
  const StartupGateReady({
    required this.scope,
    required this.hasMetadata,
    this.pubkey,
  });

  @override
  List<Object?> get props => [scope, pubkey, hasMetadata];
}

class StartupGateError extends StartupGateState {
  final String message;
  const StartupGateError(this.message);

  @override
  List<Object?> get props => [message];
}

class StartupGateCubit extends Cubit<StartupGateState> {
  final StartupCoordinator _startup;
  late final StreamSubscription<StartupSnapshot> _startupSub;

  StartupGateCubit({required StartupCoordinator startup})
    : _startup = startup,
      super(const StartupGateInitial()) {
    _startupSub = _startup.snapshots.listen(_onSnapshot);
  }

  void _onSnapshot(StartupSnapshot snapshot) {
    if (snapshot.hasFailed) {
      emit(StartupGateError(snapshot.error.toString()));
      return;
    }

    final result = snapshot.result;
    if (result == null) {
      emit(StartupGateInProgress(items: snapshot.items));
      return;
    }

    switch (result) {
      case PublicStartupReady():
        emit(StartupGateReady(scope: snapshot.scope, hasMetadata: true));
      case UserStartupReady(:final pubkey, :final hasMetadata):
        emit(
          StartupGateReady(
            scope: snapshot.scope,
            pubkey: pubkey,
            hasMetadata: hasMetadata,
          ),
        );
      case BackgroundStartupReady(:final pubkey):
        emit(
          StartupGateReady(
            scope: snapshot.scope,
            pubkey: pubkey,
            hasMetadata: true,
          ),
        );
    }
  }

  Future<void> retry() => _startup.retryActive();

  @override
  Future<void> close() async {
    await _startupSub.cancel();
    return super.close();
  }
}
