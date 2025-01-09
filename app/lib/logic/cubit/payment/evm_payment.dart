import 'payment.cubit.dart';

class EVMPaymentCubit extends PaymentCubit {
  /// Specific to EVM payments, check chain for confirmation using txId
  getStatus() {}

  /// Called upon payment detail page opening
  @override
  resolve() async {
    // Logic for resolving payment details
    // Maybe guestimate fees
  }

  /// Called upon payment confirmation
  @override
  callback() async {
    // Logic for handling callback, possibly empty
  }

  /// Called upon
  @override
  complete() async {
    // Send transaction to rpc client and track status
  }
}

// States
class EvmPaymentStateInMempool extends PaymentStateInFlight {
  EvmPaymentStateInMempool();
}
