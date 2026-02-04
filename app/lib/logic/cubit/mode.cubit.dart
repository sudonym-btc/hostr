import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/sources/local/mode_storage.dart';
import 'package:injectable/injectable.dart';

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
@injectable
class ModeCubit extends Cubit<ModeCubitState> {
  final ModeStorage modeStorage;

  ModeCubit({required this.modeStorage}) : super(ModeInitial());

  Future<void> setHost() async {
    await modeStorage.set('host');
    emit(HostMode());
  }

  Future<void> setGuest() async {
    await modeStorage.set('guest');
    emit(GuestMode());
  }

  Future<void> get() async {
    String mode = await modeStorage.get();
    if (mode == 'host') {
      emit(HostMode());
    } else {
      emit(GuestMode());
    }
  }

  void toggle() async {
    String mode = await modeStorage.get();
    if (mode == 'host') {
      setGuest();
    } else {
      setHost();
    }
  }
}
