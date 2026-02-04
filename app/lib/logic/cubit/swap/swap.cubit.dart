import 'package:flutter_bloc/flutter_bloc.dart';

class SwapCubit extends Cubit<SwapCubitState> {
  SwapCubit() : super(SwapCubitState());

  void init() {
    checkStatus();
  }

  void checkStatus() {}

  void abortInFlight() {}
}

class SwapCubitState {}

class SwapCubitStateRequesting extends SwapCubitState {}

class SwapCubitInFlight {}

class SwapCubitTerminalState extends SwapCubitState {}

class SwapCubitStateCompleted extends SwapCubitTerminalState {}

class SwapCubitStateFailed extends SwapCubitTerminalState {}
