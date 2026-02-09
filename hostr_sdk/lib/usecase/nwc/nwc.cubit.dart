import 'package:equatable/equatable.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:ndk/ndk.dart' hide Nwc;

class NwcCubit extends Cubit<NwcCubitState> {
  final CustomLogger logger;
  final Nwc nwc;
  String? url;
  NwcConnection? connection;
  NwcCubit({required this.nwc, required this.logger, this.url}) : super(Idle());

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
