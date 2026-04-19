import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:ndk/entities.dart';

/// State representing the aggregate relay connectivity status.
class RelayConnectivityState extends Equatable {
  final int totalRelays;
  final int connectedRelays;
  final int disconnectedRelays;
  final bool hostrRelayConfigured;
  final bool hostrRelayConnected;

  const RelayConnectivityState({
    this.totalRelays = 0,
    this.connectedRelays = 0,
    this.disconnectedRelays = 0,
    this.hostrRelayConfigured = false,
    this.hostrRelayConnected = true,
  });

  /// True when fewer than 25% of configured relays are connected.
  bool get severelyDegraded => totalRelays > 0 && connectedFraction < 0.25;

  bool get hostrRelayDisconnected =>
      hostrRelayConfigured && !hostrRelayConnected;

  bool get shouldWarn => severelyDegraded;

  double get connectedFraction =>
      totalRelays > 0 ? connectedRelays / totalRelays : 1.0;

  @override
  List<Object> get props => [
    totalRelays,
    connectedRelays,
    disconnectedRelays,
    hostrRelayConfigured,
    hostrRelayConnected,
  ];
}

/// Cubit that monitors relay connectivity and emits aggregate state.
class RelayConnectivityCubit extends Cubit<RelayConnectivityState> {
  final Hostr _hostr;
  StreamSubscription<Map<String, RelayConnectivity<dynamic>>>? _subscription;

  RelayConnectivityCubit({required Hostr hostr})
    : _hostr = hostr,
      super(const RelayConnectivityState()) {
    _subscribe();
  }

  void _subscribe() {
    _subscription = _hostr.relays.connectivity().listen(
      (connectivityMap) {
        final hostrRelay = _hostr.config.hostrRelay;
        final total = connectivityMap.length;
        final connected = connectivityMap.values
            .where((c) => c.relayTransport?.isOpen() == true)
            .length;
        final hostrRelayConnected =
            hostrRelay.isEmpty ||
            connectivityMap[hostrRelay]?.relayTransport?.isOpen() == true;

        emit(
          RelayConnectivityState(
            totalRelays: total,
            connectedRelays: connected,
            disconnectedRelays: total - connected,
            hostrRelayConfigured: hostrRelay.isNotEmpty,
            hostrRelayConnected: hostrRelayConnected,
          ),
        );
      },
      onError: (_) {
        // Keep the last known state on stream errors.
      },
    );
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}
