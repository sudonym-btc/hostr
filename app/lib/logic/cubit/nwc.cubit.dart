import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';

import '../services/nwc.dart';

class NwcCubit extends Cubit<NwcCubitState> {
  CustomLogger logger = CustomLogger();
  NwcService nwcService = getIt<NwcService>();
  NwcCubit() : super(Idle());

  Future connect(String str) async {
    try {
      await nwcService.save(str);
      await checkInfo();
    } catch (e) {
      print(e);
      emit(Error());
    }
  }

  Future checkInfo() {
    emit(NostrWalletConnectInProgress());
    return nwcService.getInfo().then((value) {
      emit(Success(
          content: value.parsedContent.result as NwcMethodGetInfoResponse));
    }).catchError((e) {
      print(e);
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

class NostrWalletConnectInProgress extends NwcCubitState {
  const NostrWalletConnectInProgress();
}

class Success extends NwcCubitState {
  final NwcMethodGetInfoResponse content;

  const Success({required this.content});
}

class Error extends NwcCubitState {
  final dynamic e;
  const Error({this.e});
}
