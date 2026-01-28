import 'package:hostr/data/sources/nostr/nostr/usecase/auth/auth.dart';
import 'package:hostr/export.dart';
import 'package:hostr/injection.dart';
import 'package:http/http.dart';
import 'package:ndk/domain_layer/usecases/nwc/nwc.dart';
import 'package:web3dart/web3dart.dart';

import '../escrows/escrows.dart';
import 'payment_escrow.dart';
import 'swap.dart';

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
}
