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

  double get progress {
    if (items.isEmpty) return 0;
    final finished = items.where((item) {
      return item.state == StartupItemState.complete ||
          item.state == StartupItemState.skipped ||
          item.state == StartupItemState.degraded;
    }).length;
    return finished / items.length;
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

class StartupGateReady extends StartupGateState {
  final bool hasMetadata;
  const StartupGateReady({required this.hasMetadata});

  @override
  List<Object?> get props => [hasMetadata];
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
        emit(const StartupGateReady(hasMetadata: true));
      case UserStartupReady(:final hasMetadata):
        emit(StartupGateReady(hasMetadata: hasMetadata));
      case BackgroundStartupReady():
        emit(const StartupGateReady(hasMetadata: true));
    }
  }

  Future<void> retry() => _startup.retryActive();

  @override
  Future<void> close() async {
    await _startupSub.cancel();
    return super.close();
  }
}
