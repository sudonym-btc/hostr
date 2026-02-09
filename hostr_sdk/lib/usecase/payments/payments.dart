import 'package:hostr_sdk/usecase/payments/operations/pay_models.dart';
import 'package:injectable/injectable.dart';

import '../../util/custom_logger.dart';
import '../nwc/nwc.dart';
import '../zaps/zaps.dart';
import 'operations/bolt11_operation.dart';
import 'operations/lnurl_operation.dart';
import 'operations/pay_operation.dart';

@Singleton()
class Payments {
  final CustomLogger logger;
  late final Zaps zaps;
  late final Nwc nwc;

  Payments({required this.zaps, required this.nwc, required this.logger});

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
