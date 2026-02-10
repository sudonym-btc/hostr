import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/injection.dart';
import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart';
import 'package:models/main.dart';

class PaymentStatusCubit extends Cubit<PaymentStatusCubitState> {
  CustomLogger logger = CustomLogger();
  final Listing listing;
  final ReservationRequest reservationRequest;
  StreamSubscription<FundedEvent>? _escrowSubscription;
  StreamSubscription<StreamStatus>? _escrowStatusSubscription;
  StreamWithStatus<FundedEvent>? _escrowPaymentStatus;
  PaymentStatusCubit(this.listing, this.reservationRequest)
    : super(PaymentStatusCubitState());

  sync() {
    _escrowStatusSubscription?.cancel();
    _escrowSubscription?.cancel();
    _escrowPaymentStatus?.close();
    _escrowPaymentStatus = getIt<Hostr>().escrow.checkEscrowStatus(
      reservationRequest.getDtag()!,
      listing.pubKey,
    );
    _escrowSubscription = _escrowPaymentStatus!.stream.listen((escrowStatus) {
      emit(PaymentStatusCubitPaid());
      // Handle escrow status updates here
      logger.i(
        'Escrow status for reservation ${reservationRequest.id}: ${escrowStatus.transactionHash}',
      );
    });

    _escrowStatusSubscription = _escrowPaymentStatus!.status.listen((status) {
      if (status is StreamStatusLive) {
        emit(PaymentStatusCubitDone());
      }
    });
    // return zaps.ndk.zaps
    //     .subscribeToZapReceipts(
    //       pubKey: l.pubKey,
    //       addressableId: reservationRequest.id,
    //     )
    //     .stream;
  }

  @override
  Future<void> close() {
    _escrowStatusSubscription?.cancel();
    _escrowSubscription?.cancel();
    _escrowPaymentStatus?.close();
    return super.close();
  }
}

class PaymentStatusCubitState {}

class PaymentStatusCubitPaid extends PaymentStatusCubitState {}

class PaymentStatusCubitDone extends PaymentStatusCubitState {}
