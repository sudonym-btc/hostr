import 'package:flutter_bloc/flutter_bloc.dart';

class PaymentCubit extends Cubit<PaymentState> {
  // final NwcService nwcService = getIt<NwcService>();

  PaymentCubit() : super(PaymentStateInitial());

  /// Called upon initialization
  /// Estimates fees etc
  resolve() async {}

  /// Called if a step is required to fetch the final payment address
  /// E.g. for LNURL
  confirm() async {}

  /// Broadcast the payment to the network
  complete() {}
}

// States
abstract class PaymentState {}

class PaymentStateInitial extends PaymentState {}

class PaymentStateDetailsResolved extends PaymentState {
  final int commentMin;
  final int commentMax;
  final int minAmount;
  final int maxAmount;
  final String? callbackUrl;

  PaymentStateDetailsResolved({
    required this.commentMin,
    required this.commentMax,
    required this.minAmount,
    required this.maxAmount,
    this.callbackUrl,
  });
}

class PaymentStateInFlight extends PaymentState {}

class PaymentStateTerminal extends PaymentState {}

class PaymentStateCancelled extends PaymentStateTerminal {}

class PaymentStateExpired extends PaymentStateTerminal {}

class PaymentStateCompleted extends PaymentStateTerminal {
  final String response;
  PaymentStateCompleted(this.response);
}

class PaymentStateFailed extends PaymentStateTerminal {
  final String error;
  PaymentStateFailed(this.error);
}
