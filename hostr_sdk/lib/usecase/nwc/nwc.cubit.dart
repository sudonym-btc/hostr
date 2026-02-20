import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hydrated_bloc/hydrated_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:ndk/ndk.dart' hide Nwc;

@injectable
class NwcCubit extends Cubit<NwcCubitState> {
  final CustomLogger logger;
  final Nwc nwc;
  String? url;
  NwcConnection? connection;
  NwcCubit({required this.nwc, required this.logger, this.url})
    : super(NwcIdle());

  Future connect(String? url) async {
    emit(NwcLoading());
    try {
      connection = await nwc.connect((url ?? this.url)!);
      this.url = url ?? this.url;
      await checkInfo();
    } catch (e) {
      logger.e(e);
      emit(NwcFailure(e));
    }
  }

  Future checkInfo() async {
    emit(NwcLoading());
    return nwc
        .getInfo(connection!)
        .then((value) {
          emit(NwcSuccess(value));
        })
        .catchError((e) {
          logger.e(e);
          emit(NwcFailure(e));
        });
  }
}

class AsyncState<T, E> {}

abstract class NwcCubitState implements AsyncState<GetInfoResponse, dynamic> {}

class Idle<T, E> extends AsyncState<T, E> {}

class Loading<T, E> extends AsyncState<T, E> {}

class Success<T, E> extends AsyncState<T, E> {
  final T data;
  Success(this.data);

  T get content => data;
}

class Failure<T, E> extends AsyncState<T, E> {
  final E error;
  Failure(this.error);

  E get e => error;
}

class NwcIdle extends Idle<GetInfoResponse, dynamic> implements NwcCubitState {}

class NwcLoading extends Loading<GetInfoResponse, dynamic>
    implements NwcCubitState {}

class NwcSuccess extends Success<GetInfoResponse, dynamic>
    implements NwcCubitState {
  NwcSuccess(super.data);
}

class NwcFailure extends Failure<GetInfoResponse, dynamic>
    implements NwcCubitState {
  NwcFailure(super.error);
}
