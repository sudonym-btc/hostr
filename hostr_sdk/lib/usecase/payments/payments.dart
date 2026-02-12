import 'package:hostr_sdk/hostr_sdk.dart';
import 'package:hostr_sdk/usecase/payments/operations/pay_models.dart';
import 'package:injectable/injectable.dart';

import 'operations/bolt11_operation.dart';
import 'operations/lnurl_operation.dart';
import 'operations/pay_operation.dart';

@Singleton()
class Payments {
  final CustomLogger logger;
  late final Zaps zaps;
  late final Nwc nwc;
  final EscrowUseCase escrow;

  Payments({
    required this.zaps,
    required this.nwc,
    required this.logger,
    required this.escrow,
  });

  PayOperation pay(PayParameters params) {
    if (params is Bolt11PayParameters) {
      return Bolt11PayOperation(params: params, nwc: nwc);
    } else if (params is LnurlPayParameters) {
      return LnurlPayOperation(params: params, nwc: nwc);
    } else {
      throw Exception('Unsupported payment type');
    }
  }
}
