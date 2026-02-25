import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr_sdk/hostr_sdk.dart';

/// Abstract class representing the state of authentication.
abstract class ModeCubitState extends Equatable {
  const ModeCubitState();

  @override
  List<Object> get props => [];
}

/// Initial state of authentication.
class ModeInitial extends ModeCubitState {}

class HostMode extends ModeCubitState {}

class GuestMode extends ModeCubitState {}

/// Cubit class to manage authentication state.
///
/// Reads and writes the user's mode via [UserConfigStore] so that mode is
/// persisted alongside all other user-level preferences in one place.
class ModeCubit extends Cubit<ModeCubitState> {
  final UserConfigStore _configStore;
  StreamSubscription<HostrUserConfig>? _sub;

  ModeCubit({required UserConfigStore configStore})
    : _configStore = configStore,
      super(ModeInitial());

  /// Load persisted mode and start listening for external changes.
  Future<void> load() async {
    final config = await _configStore.state;
    _emitMode(config.mode);

    _sub = _configStore.stream.listen((config) {
      _emitMode(config.mode);
    });
  }

  Future<void> setHost() async {
    final current = await _configStore.state;
    await _configStore.update(current.copyWith(mode: AppMode.host));
  }

  Future<void> setGuest() async {
    final current = await _configStore.state;
    await _configStore.update(current.copyWith(mode: AppMode.guest));
  }

  Future<void> toggle() async {
    final current = await _configStore.state;
    final newMode = current.mode == AppMode.host ? AppMode.guest : AppMode.host;
    await _configStore.update(current.copyWith(mode: newMode));
  }

  void _emitMode(AppMode mode) {
    if (mode == AppMode.host) {
      emit(HostMode());
    } else {
      emit(GuestMode());
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
