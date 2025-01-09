import 'payment.cubit.dart';

class LnUrlPaymentCubit extends PaymentCubit {
  /// Called upon payment detail page opening
  @override
  resolve() async {
    // Logic for resolving payment details
  }

  /// Called upon payment confirmation to fetch appropriate invoice
  callback() async {
    // Logic for handling callback
  }
}

// States

class LnUrlPaymentStateDetailsResolved extends PaymentStateDetailsResolved {
  LnUrlPaymentStateDetailsResolved(
      {required super.commentMin,
      required super.commentMax,
      required super.minAmount,
      required super.maxAmount});
}
