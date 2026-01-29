import 'package:hostr/export.dart';
import 'package:injectable/injectable.dart';

import '../auth/auth.dart';
import '../escrows/escrows.dart';
import '../nwc/nwc.dart';
import 'payment_escrow.dart';

@Singleton()
class Payments {
  late final PaymentEscrow escrow;
  late final Nwc nwc;

  Payments({required Auth auth, required Escrows escrows, required this.nwc});

  checkPaymentStatus(String reservationRequestId) {
    // return nwc.lookupInvoice(reservationRequestId);
    // return escrow.checkPaymentStatus(reservationRequestId);
  }

  pay(PaymentParameters params) {
    return PaymentCubit(params: params);
  }
}
