import 'package:hostr/export.dart';
import 'package:hostr/injection.dart';
import 'package:hostr/logic/workflows/lnurl_workflow.dart';
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

  PaymentCubit pay(PaymentParameters params) {
    if (params is Bolt11PaymentParameters) {
      return Bolt11PaymentCubit(
        params: params,
        nwc: nwc,
        workflow: getIt<LnUrlWorkflow>(),
      );
    } else if (params is LnUrlPaymentParameters) {
      return LnUrlPaymentCubit(
        params: params,
        nwc: nwc,
        workflow: getIt<LnUrlWorkflow>(),
      );
    } else {
      throw Exception('Unsupported payment type');
    }
  }
}
