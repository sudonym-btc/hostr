import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/sources/nostr/nostr/hostr.dart';
import 'package:hostr/data/sources/nostr/nostr/usecase/escrow/supported_escrow_contract/supported_escrow_contract.dart';
import 'package:hostr/injection.dart';
import 'package:models/main.dart';

class PaymentStatusCubit extends Cubit<PaymentStatusCubitState> {
  CustomLogger logger = CustomLogger();
  final Listing listing;
  final ReservationRequest reservationRequest;
  StreamSubscription<FundedEvent>? _escrowSubscription;
  StreamWithStatus<FundedEvent>? _escrowStatus;
  PaymentStatusCubit(this.listing, this.reservationRequest)
    : super(PaymentStatusCubitState());

  sync() {
    emit(PaymentStatusCubitDone());
    _escrowSubscription?.cancel();
    _escrowStatus?.close();
    _escrowStatus = getIt<Hostr>().escrow.checkEscrowStatus(
      reservationRequest.id,
      listing.pubKey,
    );
    _escrowSubscription = _escrowStatus!.stream.listen((escrowStatus) {
      emit(PaymentStatusCubitPaid());
      // Handle escrow status updates here
      logger.i(
        'Escrow status for reservation ${reservationRequest.id}: ${escrowStatus.transactionHash}',
      );
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
    _escrowSubscription?.cancel();
    _escrowStatus?.close();
    return super.close();
  }
}

class PaymentStatusCubitState {}

class PaymentStatusCubitPaid extends PaymentStatusCubitState {}

class PaymentStatusCubitDone extends PaymentStatusCubitState {}
