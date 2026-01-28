import 'package:hostr/export.dart';
import 'package:hostr/injection.dart';
import 'package:http/http.dart';
import 'package:injectable/injectable.dart';
import 'package:web3dart/web3dart.dart';

import '../auth/auth.dart';
import '../escrows/escrows.dart';
import '../nwc/nwc.dart';
import 'payment_escrow.dart';
import 'swap.dart';

@Singleton()
class Payments {
  late final PaymentEscrow escrow;
  late final Swap swap;
  late final Nwc nwc;

  Payments({required Auth auth, required Escrows escrows, required this.nwc}) {
    Config config = getIt<Config>();
    BoltzClient boltzClient = getIt<BoltzClient>();
    Web3Client web3client = Web3Client(
      getIt<Config>().rootstockRpcUrl,
      Client(),
    );

    escrow = PaymentEscrow(
      auth: auth,
      boltzClient: boltzClient,
      client: web3client,
      escrows: escrows,
    );
    swap = Swap(
      auth: auth,
      config: config,
      boltzClient: boltzClient,
      client: web3client,
    );
  }

  checkPaymentStatus(String reservationRequestId) {
    // return nwc.lookupInvoice(reservationRequestId);
    // return escrow.checkPaymentStatus(reservationRequestId);
  }

  pay(PaymentParameters params) {
    return PaymentCubit(params: params);
  }
}
