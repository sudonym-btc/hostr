import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/usecase/nwc/nwc.cubit.dart';

/// State representing the aggregate NWC wallet connectivity status.
class NwcConnectivityState extends Equatable {
  /// Whether the user has any wallet connections saved.
  final bool hasWallet;

  /// Total number of wallet connections.
  final int totalConnections;

  /// Number of connections that are successfully connected.
  final int connectedCount;

  /// Number of connections that failed.
  final int failedCount;

  /// Whether connections are still loading.
  final bool loading;

  const NwcConnectivityState({
    this.hasWallet = false,
    this.totalConnections = 0,
    this.connectedCount = 0,
    this.failedCount = 0,
    this.loading = false,
  });

  /// True when the user has a wallet but all connections have failed.
  bool get walletDisconnected =>
      hasWallet && !loading && totalConnections > 0 && connectedCount == 0;

  @override
  List<Object> get props => [
    hasWallet,
    totalConnections,
    connectedCount,
    failedCount,
    loading,
  ];
}

/// Cubit that monitors NWC wallet connectivity and emits aggregate state.
///
/// Subscribes to [Hostr.nwc.connectionsStream] and then listens to each
/// individual [NwcCubit]'s state to derive an aggregate connectivity picture.
class NwcConnectivityCubit extends Cubit<NwcConnectivityState> {
  final Hostr _hostr;
  StreamSubscription<List<NwcCubit>>? _connectionsSubscription;
  final Map<NwcCubit, StreamSubscription<NwcCubitState>> _cubitSubscriptions =
      {};

  NwcConnectivityCubit({required Hostr hostr})
    : _hostr = hostr,
      super(const NwcConnectivityState()) {
    _subscribe();
  }

  void _subscribe() {
    _connectionsSubscription = _hostr.nwc.connectionsStream.listen(
      _onConnectionsChanged,
    );
  }

  void _onConnectionsChanged(List<NwcCubit> cubits) {
    // Unsubscribe from cubits that are no longer in the list.
    final currentCubits = Set<NwcCubit>.from(cubits);
    _cubitSubscriptions.keys
        .where((c) => !currentCubits.contains(c))
        .toList()
        .forEach((removed) {
          _cubitSubscriptions.remove(removed)?.cancel();
        });

    // Subscribe to new cubits.
    for (final cubit in cubits) {
      if (!_cubitSubscriptions.containsKey(cubit)) {
        _cubitSubscriptions[cubit] = cubit.stream.listen((_) => _evaluate());
      }
    }

    _evaluate();
  }

  void _evaluate() {
    final cubits = _hostr.nwc.connections;
    final hasWallet = cubits.isNotEmpty;
    final total = cubits.length;

    int connected = 0;
    int failed = 0;
    bool loading = false;

    for (final cubit in cubits) {
      final s = cubit.state;
      if (s is NwcSuccess) {
        connected++;
      } else if (s is NwcFailure) {
        failed++;
      } else {
        // Idle or Loading
        loading = true;
      }
    }

    emit(
      NwcConnectivityState(
        hasWallet: hasWallet,
        totalConnections: total,
        connectedCount: connected,
        failedCount: failed,
        loading: loading,
      ),
    );
  }

  @override
  Future<void> close() {
    _connectionsSubscription?.cancel();
    for (final sub in _cubitSubscriptions.values) {
      sub.cancel();
    }
    _cubitSubscriptions.clear();
    return super.close();
  }
}
