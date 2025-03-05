import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/injection.dart';
import 'package:ndk/ndk.dart';

import '../services/nwc.dart';

class NwcCubit extends Cubit<NwcCubitState> {
  CustomLogger logger = CustomLogger();
  NwcService nwcService = getIt<NwcService>();
  NwcCubit() : super(Idle());

  Future connect(String str) async {
    try {
      /// todo emit intermediate state
      await nwcService.getInfo(parseNwc(str).toString());
      await nwcService.save(str);
      await checkInfo();
    } catch (e) {
      logger.e(e);
      emit(Error());
    }
  }

  Future checkInfo() async {
    emit(NostrWalletConnectInProgress());
    List urls = await nwcService.nwcStorage.get();
    print(urls);
    if (urls.isEmpty) {
      emit(Error(e: "No NWC urls found"));
      return;
    }
    return nwcService
        .getInfo((await nwcService.nwcStorage.get())[0])
        .then((value) {
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

class NostrWalletConnectInProgress extends NwcCubitState {
  const NostrWalletConnectInProgress();
}

class Success extends NwcCubitState {
  final GetInfoResponse content;

  const Success({required this.content});
}

class Error extends NwcCubitState {
  final dynamic e;
  const Error({this.e});
}
