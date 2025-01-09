import 'package:flutter_bloc/flutter_bloc.dart';

import 'payment.cubit.dart';

class PaymentsManager extends Cubit<PaymentCubit?> {
  final List<PaymentCubit> payments = [];
  PaymentsManager() : super(null);

  create() {
    PaymentCubit payment = PaymentCubit();
    payments.add(payment);
    emit(payment);
  }
}
