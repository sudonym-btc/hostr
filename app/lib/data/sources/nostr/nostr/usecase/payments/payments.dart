import 'package:hostr/export.dart';
import 'package:injectable/injectable.dart';

import '../nwc/nwc.dart';
import '../zaps/zaps.dart';

@Singleton()
class Payments {
  CustomLogger logger = CustomLogger();
  late final Zaps zaps;
  late final Nwc nwc;

  Payments({required this.zaps, required this.nwc});

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
