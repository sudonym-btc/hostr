import 'package:hostr/export.dart';
import 'package:injectable/injectable.dart';
import 'package:models/main.dart';

import '../auth/auth.dart';
import '../escrow/escrow.dart';
import '../nwc/nwc.dart';
import '../zaps/zaps.dart';

@Singleton()
class Payments {
  CustomLogger logger = CustomLogger();
  late final PaymentEscrow escrow;
  late final Zaps zaps;
  late final Nwc nwc;

  Payments({
    required Auth auth,
    required this.escrow,
    required this.zaps,
    required this.nwc,
  });

  // Once we have published a reservation item, we can use the payment proof to easily track status, so if we change trusted escrows, it doesn't matter.
  Stream checkPaymentStatus(Listing l, ReservationRequest reservationRequest) {
    escrow.checkEscrowStatus(reservationRequest.id, l.pubKey).listen((
      escrowStatus,
    ) {
      // Handle escrow status updates here
      logger.i(
        'Escrow status for reservation ${reservationRequest.id}: $escrowStatus',
      );
    });
    return zaps.ndk.zaps
        .subscribeToZapReceipts(
          pubKey: l.pubKey,
          addressableId: reservationRequest.id,
        )
        .stream;
  }

  PaymentCubit pay(PaymentParameters params) {
    if (params is Bolt11PaymentParameters) {
      return Bolt11PaymentCubit(params: params, nwc: nwc);
    } else if (params is LnUrlPaymentParameters) {
      return LnUrlPaymentCubit(params: params, nwc: nwc);
    } else {
      throw Exception('Unsupported payment type');
    }
  }
}
