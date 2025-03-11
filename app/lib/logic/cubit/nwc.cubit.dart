import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/injection.dart';
import 'package:ndk/ndk.dart';

import '../services/nwc.dart';

class NwcCubit extends Cubit<NwcCubitState> {
  CustomLogger logger = CustomLogger();
  NwcService nwcService = getIt<NwcService>();
  String? url;
  NwcConnection? connection;
  NwcCubit({this.url}) : super(Idle());

  Future connect(String? url) async {
    emit(Loading());
    try {
      connection = await nwcService.connect((url ?? this.url)!);
      this.url = url;
      await nwcService.add(this);
      await checkInfo();
    } catch (e) {
      logger.e(e);
      emit(Error(e: e));
    }
  }

  Future checkInfo() async {
    emit(Loading());
    return nwcService.getInfo(connection!).then((value) {
      emit(Success(content: value));
    }).catchError((e) {
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
