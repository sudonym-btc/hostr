import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hostr/logic/cubit/payment/bolt11_payment.cubit.dart';
import 'package:hostr/logic/cubit/payment/lnurl_payment.cubit.dart';

import 'payment.cubit.dart';

class PaymentsManager extends Cubit<PaymentCubit?> {
  final List<PaymentCubit> payments = [];
  PaymentsManager() : super(null);

  create(PaymentParameters params) {
    PaymentCubit payment;
    if (params is Bolt11PaymentParameters) {
      payment = Bolt11PaymentCubit(params: params);
    } else if (params is LnUrlPaymentParameters) {
      payment = LnUrlPaymentCubit(params: params);
    } else {
      throw Exception('Unsupported payment type');
    }
    payment.resolve();
    emit(payment);
    return payment;
  }
}

bool isBolt11(String to) {
  final bolt11Regex =
      RegExp(r'^[a-zA-Z0-9]{1,}$'); // Simplified regex for example
  return bolt11Regex.hasMatch(to);
}

bool isEthereumAddress(String to) {
  final ethAddressRegex = RegExp(r'^0x[a-fA-F0-9]{40}$');
  return ethAddressRegex.hasMatch(to);
}

bool isLnurl(String to) {
  final lnurlRegex =
      RegExp(r'^lnurl[a-zA-Z0-9]{1,}$'); // Simplified regex for example
  return lnurlRegex.hasMatch(to);
}
