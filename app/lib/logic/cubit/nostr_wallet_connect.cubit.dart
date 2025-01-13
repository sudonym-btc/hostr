import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/main.dart';
import 'package:hostr/injection.dart';

import '../services/nostr_wallet_connect.dart';

class NostrWalletConnectCubit extends Cubit<NostrWalletConnectState> {
  CustomLogger logger = CustomLogger();
  NostrWalletConnectService nwcService = getIt<NostrWalletConnectService>();
  NostrWalletConnectCubit() : super(Idle());

  void connect(String str) async {
    emit(NostrWalletConnectInProgress());
    try {
      await nwcService.save(str);
      // emit(Success(content: info));
    } catch (e) {
      emit(Error());
    }
  }

  void checkInfo() {
    emit(NostrWalletConnectInProgress());
    nwcService.getInfo().then((value) {
      emit(Success(content: value));
    }).catchError((e) {
      emit(Error());
    });
  }
}

class NostrWalletConnectState extends Equatable {
  const NostrWalletConnectState();

  @override
  List<Object?> get props => [];
}

class Idle extends NostrWalletConnectState {}

class NostrWalletConnectInProgress extends NostrWalletConnectState {
  const NostrWalletConnectInProgress();
}

class Success extends NostrWalletConnectState {
  final NwcInfoContent content;

  const Success({required this.content});
}

class Error extends NostrWalletConnectState {
  const Error();
}
