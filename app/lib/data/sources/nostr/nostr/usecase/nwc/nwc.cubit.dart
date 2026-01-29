import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/core/main.dart';
import 'package:ndk/ndk.dart' hide Nwc;

import 'nwc.dart';

class NwcCubit extends Cubit<NwcCubitState> {
  final CustomLogger logger = CustomLogger();
  final Nwc nwc;
  String? url;
  NwcConnection? connection;
  NwcCubit({required this.nwc, this.url}) : super(Idle());

  Future connect(String? url) async {
    emit(Loading());
    try {
      connection = await nwc.connect((url ?? this.url)!);
      this.url = url ?? this.url;
      await checkInfo();
    } catch (e) {
      logger.e(e);
      emit(Error(e: e));
    }
  }

  Future checkInfo() async {
    emit(Loading());
    return nwc
        .getInfo(connection!)
        .then((value) {
          emit(Success(content: value));
        })
        .catchError((e) {
          logger.e(e);
          emit(Error(e: e));
        });
  }
}

class NwcCubitState extends Equatable {
  const NwcCubitState();

  @override
  List<Object?> get props => [];
}

class Idle extends NwcCubitState {}

class Loading extends NwcCubitState {
  const Loading();
}

class Success extends NwcCubitState {
  final GetInfoResponse content;

  const Success({required this.content});
}

class Error extends NwcCubitState {
  final dynamic e;
  const Error({this.e});
}
