import 'package:flutter_bloc/flutter_bloc.dart';

class SwapCubit extends Cubit<SwapCubitState> {
  SwapCubit() : super(SwapCubitState());

  init() {
    checkStatus();
  }

  checkStatus() {}

  abortInFlight() {}
}

class SwapCubitState {}

class SwapCubitStateRequesting extends SwapCubitState {}

class SwapCubitInFlight {}

class SwapCubitTerminalState extends SwapCubitState {}

class SwapCubitStateCompleted extends SwapCubitTerminalState {}

class SwapCubitStateFailed extends SwapCubitTerminalState {}
