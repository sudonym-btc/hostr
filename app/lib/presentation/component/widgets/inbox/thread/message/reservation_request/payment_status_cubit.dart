import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/core/main.dart';
import 'package:hostr/data/sources/nostr/nostr/hostr.dart';
import 'package:hostr/injection.dart';
import 'package:models/main.dart';

class PaymentStatusCubit extends Cubit<PaymentStatusCubitState> {
  CustomLogger logger = CustomLogger();
  final Listing listing;
  final ReservationRequest reservationRequest;
  PaymentStatusCubit(this.listing, this.reservationRequest)
    : super(PaymentStatusCubitState());

  sync() {
    emit(PaymentStatusCubitDone());
    getIt<Hostr>().escrow
        .checkEscrowStatus(reservationRequest.id, listing.pubKey)
        .listen((escrowStatus) {
          emit(PaymentStatusCubitPaid());
          // Handle escrow status updates here
          logger.i(
            'Escrow status for reservation ${reservationRequest.id}: $escrowStatus',
          );
        });
    // return zaps.ndk.zaps
    //     .subscribeToZapReceipts(
    //       pubKey: l.pubKey,
    //       addressableId: reservationRequest.id,
    //     )
    //     .stream;
  }
}

class PaymentStatusCubitState {}

class PaymentStatusCubitPaid extends PaymentStatusCubitState {}

class PaymentStatusCubitDone extends PaymentStatusCubitState {}
