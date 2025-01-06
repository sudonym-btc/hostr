import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/injection.dart';

import '../services/nostr_wallet_connect.dart';

class NostrWalletConnectCubit extends Cubit<NostrWalletConnectState> {
  CustomLogger logger = CustomLogger();
  NostrWalletConnectService nwcService = getIt<NostrWalletConnectService>();
  NostrWalletConnectCubit() : super(NostrWalletConnectState());

  void connect(String str) async {
    emit(NostrWalletConnectProgress());
    try {
      await nwcService.save(str);
      emit(Success());
    } catch (e) {
      emit(Error());
    }
  }

  // Should be moved to separate "Payment Cubit"
  void pay_invoice(String str) async {
    emit(NostrWalletConnectProgress());
    try {
      await nwcService.payInvoice(str);
      emit(Success());
    } catch (e) {
      logger.e('Error paying invoice', error: e);
      emit(Error());
    }
  }
}

class NostrWalletConnectState extends Equatable {
  const NostrWalletConnectState();

  @override
  // TODO: implement props
  List<Object?> get props => [];
}

class Idle extends NostrWalletConnectState {}

class NostrWalletConnectProgress extends NostrWalletConnectState {
  NostrWalletConnectProgress();
}

class Success extends NostrWalletConnectState {
  const Success();
}

class Error extends NostrWalletConnectState {
  const Error();
}
