import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/data/sources/local/mode_storage.dart';
import 'package:hostr/injection.dart';
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
  ModeStorage modeStorage = getIt<ModeStorage>();

  ModeCubit() : super(ModeInitial());

  Future<void> setHost() async {
    await modeStorage.set('host');
    emit(HostMode());
  }

  Future<void> setGuest() async {
    await modeStorage.set('guest');
    emit(GuestMode());
  }

  get() async {
    print('Mode Cubit getting mode');
    print(await modeStorage.get());
    String mode = await modeStorage.get();
    if (mode == 'host') {
      print('emiiting host');
      print(HostMode() == GuestMode());
      emit(HostMode());
    } else {
      emit(GuestMode());
    }
  }
}
